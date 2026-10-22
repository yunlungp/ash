import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:battle_tracker/main.dart';
import 'package:battle_tracker/models/character_unit.dart';
import 'package:battle_tracker/models/game_log.dart';
import 'package:battle_tracker/models/status_effect.dart';
import 'package:battle_tracker/providers/battle_provider.dart';
import 'package:battle_tracker/utils/arithmetic_parser.dart';
import 'package:battle_tracker/widgets/dialogs/arithmetic_input_dialog.dart';
import 'package:battle_tracker/widgets/dialogs/dice_dialog.dart';
import 'package:battle_tracker/widgets/dialogs/effect_dialog.dart';

void main() {
  group('ArithmeticParser 算術解析測試', () {
    test('基本運算測試 (+, -, *, /, %, 直接覆寫)', () {
      // 加法
      expect(
        ArithmeticParser.parseAndCompute(currentValue: 100, input: '+5').newValue,
        105,
      );
      // 減法
      expect(
        ArithmeticParser.parseAndCompute(currentValue: 100, input: '-10').newValue,
        90,
      );
      // 乘法
      expect(
        ArithmeticParser.parseAndCompute(currentValue: 20, input: '*2').newValue,
        40,
      );
      // 除法
      expect(
        ArithmeticParser.parseAndCompute(currentValue: 30, input: '/2').newValue,
        15,
      );
      // 百分比
      expect(
        ArithmeticParser.parseAndCompute(currentValue: 80, input: '%50').newValue,
        40,
      );
      // 直接數值
      expect(
        ArithmeticParser.parseAndCompute(currentValue: 100, input: '25').newValue,
        25,
      );
    });
  });

  group('BattleProvider 核心對戰邏輯測試', () {
    test('小兵數量連動被動增益 (1隻: RNG+1, 2隻: MOV+1, 3隻: ATK+10)', () {
      final provider = BattleProvider();

      // 召喚第 1 隻小兵
      provider.summonMinion(playerIndex: 0, slotIndex: 0);
      var minion0 = provider.player1Minions[0]!;
      expect(minion0.passiveRangeBonus, 1);
      expect(minion0.passiveMoveBonus, 0);
      expect(minion0.passiveAtkBonus, 0);
      expect(minion0.effectiveRange, 1 + 1); // 基礎 1 + 被動 1 = 2

      // 召喚第 2 隻小兵
      provider.summonMinion(playerIndex: 0, slotIndex: 1);
      minion0 = provider.player1Minions[0]!;
      var minion1 = provider.player1Minions[1]!;
      expect(minion0.passiveRangeBonus, 1);
      expect(minion0.passiveMoveBonus, 1);
      expect(minion0.passiveAtkBonus, 0);
      expect(minion1.effectiveMove, 2 + 1); // 基礎 2 + 被動 1 = 3

      // 召喚第 3 隻小兵
      provider.summonMinion(playerIndex: 0, slotIndex: 2);
      minion0 = provider.player1Minions[0]!;
      var minion2 = provider.player1Minions[2]!;
      expect(minion0.passiveRangeBonus, 1);
      expect(minion0.passiveMoveBonus, 1);
      expect(minion0.passiveAtkBonus, 10);
      expect(minion2.effectiveAtk, 5 + 10); // 基礎 5 + 被動 10 = 15

      // 撤退 1 隻小兵，被動自動退階
      provider.dismissMinion(playerIndex: 0, slotIndex: 2);
      minion0 = provider.player1Minions[0]!;
      expect(minion0.passiveAtkBonus, 0);
      expect(minion0.passiveMoveBonus, 1);
      expect(minion0.passiveRangeBonus, 1);
    });

    test('狀態效果掛載、動態計算、回合結算倒數與 Undo 復原', () {
      final provider = BattleProvider();

      // 玩家 1 英雄初始 ATK = 15
      expect(provider.player1.effectiveAtk, 15);

      // 掛載狂暴 Buff (+5 ATK, 2 回合)
      provider.addEffect(
        unitId: provider.player1.id,
        effect: const StatusEffect(
          id: 'buff_berserk',
          name: '狂暴',
          atkDelta: 5,
          turnsRemaining: 2,
        ),
      );

      // 動態連動：15 + 5 = 20
      expect(provider.player1.effectiveAtk, 20);

      // 掛載中毒 (-5 HP/回合, 1 回合)
      // 注意：生命值效果在掛載的當下回合就會馬上執行一次扣血/補血 (HP: 100 -> 95)
      provider.addEffect(
        unitId: provider.player1.id,
        effect: const StatusEffect(
          id: 'debuff_poison',
          name: '劇毒',
          hpPerTurnDelta: -5,
          turnsRemaining: 1,
          isDebuff: true,
        ),
      );

      expect(provider.player1.baseHp, 95); // 掛載當下即時執行 -5

      // 切換回合 (P1 結束回合 -> 輪到 P2 行動)
      provider.nextTurn();
      // 此時是 P2 回合開始，P1 的生命值與效果不變
      expect(provider.player1.baseHp, 95);
      expect(provider.player1.effects.any((e) => e.name == '劇毒'), isTrue);

      // 再次切換回合 (P2 結束回合 -> 輪到 P1 行動開始)
      // 當對手一結束回合、輪回自己時，馬上執行自己的生命值扣血 (HP: 95 -> 90) 並移除到期效果
      provider.nextTurn();

      expect(provider.player1.baseHp, 90);
      expect(provider.player1.effects.any((e) => e.name == '劇毒'), isFalse);

      // 狂暴剩餘 1 回合，加成依然在
      expect(provider.player1.effects.firstWhere((e) => e.name == '狂暴').turnsRemaining, 1);
      expect(provider.player1.effectiveAtk, 20);

      // 測試 Undo
      final undoSuccess = provider.undo();
      expect(undoSuccess, isTrue);
      // 回到切換回合前 (P2 行動時)：HP 為 95
      expect(provider.player1.baseHp, 95);
    });

    test('護盾增減與效果加成測試', () {
      final provider = BattleProvider();
      expect(provider.player1.effectiveShield, 0);

      // 調整基礎護盾 +15
      provider.applyArithmetic(
        unitId: provider.player1.id,
        statType: StatType.shield,
        expression: '+15',
      );
      expect(provider.player1.baseShield, 15);
      expect(provider.player1.effectiveShield, 15);

      // 掛載護盾 Buff (+10 護盾)
      provider.addEffect(
        unitId: provider.player1.id,
        effect: const StatusEffect(
          id: 'buff_shield_extra',
          name: '護盾加持',
          shieldDelta: 10,
          turnsRemaining: 2,
        ),
      );
      expect(provider.player1.effectiveShield, 25);
    });

    test('雙方小兵轉移至對方槽位，並觸發小兵數量被動連動', () {
      final provider = BattleProvider();

      // P1 召喚 1 隻小兵 (P1 有 1 隻小兵 -> P1 小兵有 RNG+1)
      provider.summonMinion(playerIndex: 0, slotIndex: 0);
      expect(provider.state.getAliveMinionsCount(0), 1);
      expect(provider.state.getAliveMinionsCount(1), 0);
      expect(provider.player1Minions[0]!.passiveRangeBonus, 1);

      // 將 P1 小兵掛上狀態效果
      provider.addEffect(
        unitId: provider.player1Minions[0]!.id,
        effect: const StatusEffect(
          id: 'minion_buff',
          name: '祝福',
          atkDelta: 3,
          turnsRemaining: 3,
        ),
      );

      // 移動至 P2 小兵槽位
      final transferred = provider.transferMinionToOpponent(
        fromPlayerIndex: 0,
        fromSlotIndex: 0,
      );
      expect(transferred, isTrue);

      // P1 原本位置空出 (0 隻小兵)
      expect(provider.player1Minions[0], isNull);
      expect(provider.state.getAliveMinionsCount(0), 0);

      // P2 接收該小兵，且攜帶原本效果與數值，名字與原色標記不變！
      expect(provider.state.getAliveMinionsCount(1), 1);
      final p2Minion = provider.player2Minions[0]!;
      expect(p2Minion.name, '小兵'); // 名字保持原本不變 (無 P1/P2 前綴，無 #數字)
      expect(p2Minion.originalOwnerIndex, 0); // 原創立者色彩保持 0 (藍色)
      expect(p2Minion.spawnOrder, 1); // 原生成序號保持 1
      expect(p2Minion.effects.any((e) => e.name == '祝福'), isTrue);

      // P2 的小兵數量生效：觸發 1 隻小兵的被動效果 (RNG+1)
      expect(p2Minion.passiveRangeBonus, 1);

      // 驗證 Undo 能還原轉移
      provider.undo();
      expect(provider.state.getAliveMinionsCount(0), 1);
      expect(provider.state.getAliveMinionsCount(1), 0);
      expect(provider.player1Minions[0], isNotNull);
    });

    test('甩骰子測試', () {
      final provider = BattleProvider();
      final roll = provider.rollDice(sides: 20, rollerName: '測試玩家');
      expect(roll, greaterThanOrEqualTo(1));
      expect(roll, lessThanOrEqualTo(20));
      expect(provider.logs.first.type, LogType.diceRoll);
    });
  });

  testWidgets('BoardGameBattleApp 介面加載煙霧測試 (橫向螢幕)', (WidgetTester tester) async {
    // 模擬手機橫向螢幕尺寸 (常見橫屏手機約 800x360 或 900x400)
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = BattleProvider();
    await tester.pumpWidget(BoardGameBattleApp(provider: provider));
    await tester.pump();
    expect(find.text('Ash Bound'), findsOneWidget);
    expect(find.textContaining('點 擊 螢 幕 開 始 遊 戲'), findsOneWidget);

    // 直接在 BattleFieldScreen 進行戰場 UI 渲染測試
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
      ),
      home: ChangeNotifierProvider<BattleProvider>.value(
        value: provider,
        child: const BattleFieldScreen(),
      ),
    ));
    await tester.pump();

    expect(find.textContaining('ROUND 1'), findsOneWidget);
    expect(find.textContaining('PLAYER 1'), findsOneWidget);
    expect(find.textContaining('PLAYER 2'), findsOneWidget);

    // 測試召喚小兵 (使用 Provider 召喚以驗證渲染)
    provider.summonMinion(playerIndex: 0, slotIndex: 0);
    provider.summonMinion(playerIndex: 0, slotIndex: 1);
    provider.summonMinion(playerIndex: 0, slotIndex: 2);
    await tester.pump();

    // 驗證 3 隻小兵（名稱移除 P1/P2 與 #數字，純為 小兵）與各項加成數值均正常渲染，且無任何 overflow
    expect(find.text('小兵'), findsNWidgets(3));

    // 驗證中間控制面板的結束回合大按鈕置中、骰子與復原等按鈕在下方
    expect(find.text('結束回合'), findsOneWidget);
    expect(find.text('骰子'), findsOneWidget);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);

    // 驗證下方提示文字存在
    expect(find.textContaining('提示：長按小兵可拖曳'), findsWidgets);
  });

  testWidgets('ArithmeticInputDialog.showCustom 自訂數值輸入測試', (WidgetTester tester) async {
    int updatedValue = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              ArithmeticInputDialog.showCustom(
                context: context,
                title: '測試護盾增減',
                currentValue: 5,
                allowNegative: true,
                onConfirmValue: (val) {
                  updatedValue = val;
                },
              );
            },
            child: const Text('打開輸入框'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('打開輸入框'));
    await tester.pumpAndSettle();

    expect(find.text('測試護盾增減'), findsOneWidget);
    expect(find.textContaining('目前數值: 5'), findsOneWidget);

    // 輸入 +15
    await tester.enterText(find.byType(TextField), '+15');
    await tester.pumpAndSettle();

    // 點擊確定
    await tester.tap(find.text('確定'));
    await tester.pumpAndSettle();

    expect(updatedValue, 20);
  });

  testWidgets('EffectDialog 與 DiceDialog 手機橫向螢幕 (800x360) 佈局相容性測試', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testHero = CharacterUnit.createHero(id: 'hero', name: '測試英雄');

    // 測試 EffectDialog
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => EffectDialog.show(
              context: context,
              unit: testHero,
            ),
            child: const Text('打開效果彈窗'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('打開效果彈窗'));
    await tester.pumpAndSettle();

    expect(find.textContaining('添加狀態效果'), findsOneWidget);
    expect(find.text('狂暴'), findsOneWidget);

    // 關閉彈窗
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 測試 DiceDialog
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DiceDialog.show(
              context: context,
              onRoll: (s, r) {},
            ),
            child: const Text('打開骰子彈窗'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('打開骰子彈窗'));
    await tester.pumpAndSettle();

    expect(find.text('擲骰子 (Roll Dice)'), findsOneWidget);
    expect(find.text('D6'), findsOneWidget);
    expect(find.textContaining('甩 D6 骰子！'), findsOneWidget);
  });
}
