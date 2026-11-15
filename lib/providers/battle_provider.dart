import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/character_unit.dart';
import '../models/game_log.dart';
import '../models/game_state.dart';
import '../models/skill_card.dart';
import '../models/status_effect.dart';
import '../utils/arithmetic_parser.dart';

class BattleProvider extends ChangeNotifier {
  late GameState _state;
  final List<GameState> _undoStack = [];
  static const int _maxUndoHistory = 50;

  BattleProvider({int startingPlayerIndex = 0}) {
    _state = GameState.initial(startingPlayerIndex: startingPlayerIndex);
    _recalculatePassiveMinionBuffs(0);
    _recalculatePassiveMinionBuffs(1);
  }

  // Getters
  GameState get state => _state;
  int get roundNumber => _state.roundNumber;
  int get activePlayerIndex => _state.activePlayerIndex;
  CharacterUnit get player1 => _state.player1;
  CharacterUnit get player2 => _state.player2;
  CharacterUnit getHero(int playerIndex) => playerIndex == 0 ? _state.player1 : _state.player2;
  List<CharacterUnit?> get player1Minions => _state.player1Minions;
  List<CharacterUnit?> get player2Minions => _state.player2Minions;
  List<GameLog> get logs => List.unmodifiable(_state.logs);
  bool get isGameOver => _state.isGameOver;
  int? get winnerIndex => _state.winnerIndex;
  String? get gameOverReason => _state.gameOverReason;
  bool get canUndo => _undoStack.isNotEmpty;
  int get undoCount => _undoStack.length;

  /// 取得當前行動方名稱
  String get activePlayerName =>
      _state.activePlayerIndex == 0 ? _state.player1.name : _state.player2.name;

  /// 儲存當前狀態快照到 Undo 棧
  void _saveSnapshot() {
    _undoStack.add(_state.deepCopy());
    if (_undoStack.length > _maxUndoHistory) {
      _undoStack.removeAt(0);
    }
  }

  /// 復原上一步操作 (Undo)
  bool undo() {
    if (_undoStack.isEmpty) return false;

    final previousState = _undoStack.removeLast();
    _state = previousState;

    _addLog(
      playerIndex: -1,
      actorName: '系統',
      actionTitle: '復原動作 (Undo)',
      detail: '已成功復原上一動操作，回到當前狀態',
      type: LogType.undo,
      skipSnapshot: true,
    );

    notifyListeners();
    return true;
  }

  /// 記錄遊戲歷史
  void _addLog({
    required int playerIndex,
    required String actorName,
    required String actionTitle,
    required String detail,
    required LogType type,
    bool skipSnapshot = false,
  }) {
    final log = GameLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      round: _state.roundNumber,
      playerIndex: playerIndex,
      actorName: actorName,
      actionTitle: actionTitle,
      detail: detail,
      type: type,
    );
    _state.logs.insert(0, log); // 最新在最前
  }

  /// 尋找單位
  CharacterUnit? findUnitById(String unitId) {
    if (_state.player1.id == unitId) return _state.player1;
    if (_state.player2.id == unitId) return _state.player2;

    for (final m in _state.player1Minions) {
      if (m != null && m.id == unitId) return m;
    }
    for (final m in _state.player2Minions) {
      if (m != null && m.id == unitId) return m;
    }
    return null;
  }

  /// 取得單位所屬玩家 (0: P1, 1: P2)
  int getUnitOwner(String unitId) {
    if (_state.player1.id == unitId) return 0;
    for (final m in _state.player1Minions) {
      if (m != null && m.id == unitId) return 0;
    }
    return 1;
  }

  /// 套用算術運算調整數值 (快速運算輸入: +5, -10, *2, /2, %50 或純數字)
  bool applyArithmetic({
    required String unitId,
    required StatType statType,
    required String expression,
  }) {
    if (_state.isGameOver) return false;

    final unit = findUnitById(unitId);
    if (unit == null) return false;

    final currentBase = unit.getBaseStat(statType);
    final parseResult = ArithmeticParser.parseAndCompute(
      currentValue: currentBase,
      input: expression,
      allowNegative: false,
    );

    if (!parseResult.isValid) {
      return false;
    }

    _saveSnapshot();

    final oldEffective = unit.getEffectiveStat(statType);
    unit.setBaseStat(statType, parseResult.newValue);
    final newEffective = unit.getEffectiveStat(statType);

    final owner = getUnitOwner(unitId);
    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: '${statType.displayName}調整',
      detail: '$expression ➔ ${unit.getBaseStat(statType)} (最終有效值: $oldEffective → $newEffective)',
      type: LogType.statChange,
      skipSnapshot: true,
    );

    _checkGameOver();
    notifyListeners();
    return true;
  }

  /// 新增狀態效果 (Buff / Debuff)
  void addEffect({
    required String unitId,
    required StatusEffect effect,
  }) {
    if (_state.isGameOver) return;

    final unit = findUnitById(unitId);
    if (unit == null) return;

    _saveSnapshot();

    unit.effects.add(effect);
    final owner = getUnitOwner(unitId);

    // 生命值效果 (hpPerTurnDelta) 在設置的回合就會馬上執行一次結算
    if (effect.hpPerTurnDelta != 0) {
      final oldHp = unit.baseHp;
      unit.baseHp += effect.hpPerTurnDelta;
      if (unit.baseHp < 0) unit.baseHp = 0;

      _addLog(
        playerIndex: owner,
        actorName: unit.name,
        actionTitle: effect.hpPerTurnDelta < 0 ? '效果即時傷害' : '效果即時治療',
        detail: '受「${effect.name}」即時生效影響，HP $oldHp ➔ ${unit.baseHp} (${effect.hpPerTurnDelta > 0 ? "+${effect.hpPerTurnDelta}" : "${effect.hpPerTurnDelta}"})',
        type: LogType.buffTick,
        skipSnapshot: true,
      );
    }

    // 檢查生命值歸零
    _checkGameOver();

    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: effect.isDebuff ? '附加負面效果' : '獲得正面增益',
      detail: '掛載「${effect.name}」（${effect.effectSummary}，持續: ${effect.isPermanent ? '永久' : '${effect.turnsRemaining}回合'}）',
      type: LogType.buffAdd,
      skipSnapshot: true,
    );

    notifyListeners();
  }

  /// 編輯現有狀態效果
  void updateEffect({
    required String unitId,
    required StatusEffect updatedEffect,
  }) {
    if (_state.isGameOver) return;

    final unit = findUnitById(unitId);
    if (unit == null) return;

    final idx = unit.effects.indexWhere((e) => e.id == updatedEffect.id);
    if (idx == -1) return;

    _saveSnapshot();

    final oldName = unit.effects[idx].name;
    unit.effects[idx] = updatedEffect;

    final owner = getUnitOwner(unitId);

    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: '修改狀態效果',
      detail: '已更新「$oldName」➔「${updatedEffect.name}」（${updatedEffect.effectSummary}）',
      type: LogType.buffAdd,
      skipSnapshot: true,
    );

    notifyListeners();
  }

  /// 移除狀態效果
  void removeEffect({
    required String unitId,
    required String effectId,
  }) {
    if (_state.isGameOver) return;

    final unit = findUnitById(unitId);
    if (unit == null) return;

    final idx = unit.effects.indexWhere((e) => e.id == effectId);
    if (idx == -1) return;

    _saveSnapshot();

    final removed = unit.effects.removeAt(idx);
    final owner = getUnitOwner(unitId);

    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: '移除狀態效果',
      detail: '手動移除效果「${removed.name}」',
      type: LogType.buffRemove,
      skipSnapshot: true,
    );

    notifyListeners();
  }

  /// 設定/更新單位的能量值系統 (可開啟或關閉)
  void configureUnitEnergy({
    required String unitId,
    required bool enabled,
    int? currentEnergy,
    int? energyPerTurnDelta,
    int? minEnergy,
    int? maxEnergy,
  }) {
    if (_state.isGameOver) return;
    final unit = findUnitById(unitId);
    if (unit == null) return;

    _saveSnapshot();
    final owner = getUnitOwner(unitId);

    if (enabled) {
      unit.minEnergy = minEnergy ?? unit.minEnergy;
      unit.maxEnergy = maxEnergy ?? unit.maxEnergy;
      unit.energyPerTurnDelta = energyPerTurnDelta ?? unit.energyPerTurnDelta;
      final val = currentEnergy ?? unit.currentEnergy ?? 0;
      unit.currentEnergy = math.min(unit.maxEnergy, math.max(unit.minEnergy, val));

      _addLog(
        playerIndex: owner,
        actorName: unit.name,
        actionTitle: '設定能量值系統',
        detail: '能量設定: ${unit.currentEnergy} (上限: ${unit.maxEnergy}, 下限: ${unit.minEnergy}, 每回合: ${unit.energyPerTurnDelta >= 0 ? "+${unit.energyPerTurnDelta}" : "${unit.energyPerTurnDelta}"})',
        type: LogType.system,
        skipSnapshot: true,
      );
    } else {
      unit.currentEnergy = null;
      unit.energyPerTurnDelta = 0;

      _addLog(
        playerIndex: owner,
        actorName: unit.name,
        actionTitle: '關閉能量值系統',
        detail: '已移除能量值屬性',
        type: LogType.system,
        skipSnapshot: true,
      );
    }

    notifyListeners();
  }

  /// 更新小兵等級 (Lv1, Lv2, Lv3, 或 null)
  void setMinionLevel({
    required String unitId,
    required int? level,
  }) {
    if (_state.isGameOver) return;
    final unit = findUnitById(unitId);
    if (unit == null) return;

    _saveSnapshot();
    unit.level = level;
    final owner = getUnitOwner(unitId);
    final hero = getHero(owner);

    // 當角色是 Tinna 時，不同 lvl 的小兵會有不同的預設數值：
    // lv 1: atk 5, hp 10, mov 3, rng 3
    // lv 2: atk 15, hp 40, mov 3, rng 3
    // lv 3: atk 40, hp 100, mov 3, rng 3
    if (hero.presetId == 'tinna' && level != null) {
      if (level == 1) {
        unit.baseAtk = 5;
        unit.baseHp = 10;
        unit.maxHp = 10;
        unit.baseMove = 3;
        unit.baseRange = 3;
      } else if (level == 2) {
        unit.baseAtk = 15;
        unit.baseHp = 40;
        unit.maxHp = 40;
        unit.baseMove = 3;
        unit.baseRange = 3;
      } else if (level == 3) {
        unit.baseAtk = 40;
        unit.baseHp = 100;
        unit.maxHp = 100;
        unit.baseMove = 3;
        unit.baseRange = 3;
      }
    }

    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: '調整小兵等級',
      detail: level != null
          ? (hero.presetId == 'tinna' && (level >= 1 && level <= 3)
              ? '等級設定為 Lv.$level (HP: ${unit.baseHp}, ATK: ${unit.baseAtk}, MOV: ${unit.baseMove}, RNG: ${unit.baseRange})'
              : '等級設定為 Lv.$level')
          : '已清除等級標籤',
      type: LogType.system,
      skipSnapshot: true,
    );

    // 等級變動時同步重新計算 Tinna 技能卡 1 的等級光環被動
    _syncPassiveSkillCardBuffs(owner);

    notifyListeners();
  }

  /// 更新單位名稱 (例如在顯示效果彈窗中修改小兵名字)
  void renameUnit({
    required String unitId,
    required String newName,
  }) {
    if (_state.isGameOver) return;
    final unit = findUnitById(unitId);
    if (unit == null || newName.trim().isEmpty) return;

    _saveSnapshot();
    final oldName = unit.name;
    unit.name = newName.trim();
    final owner = getUnitOwner(unitId);
    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: '修改小兵名稱',
      detail: '「$oldName」更名為「${unit.name}」',
      type: LogType.system,
      skipSnapshot: true,
    );
    notifyListeners();
  }

  /// 取得該玩家目前已生成的小兵數量（包含在己方槽位與在對方槽位的小兵）
  int getPlayerSpawnedMinionsCount(int playerIndex) {
    int count = 0;
    for (final m in _state.player1Minions) {
      if (m != null && m.originalOwnerIndex == playerIndex) count++;
    }
    for (final m in _state.player2Minions) {
      if (m != null && m.originalOwnerIndex == playerIndex) count++;
    }
    return count;
  }

  /// 取得該玩家在場上的小兵中，已經使用過的最大序號 (1, 2, 3...)
  int getNextSpawnOrder(int playerIndex) {
    final usedOrders = <int>{};
    for (final m in [..._state.player1Minions, ..._state.player2Minions]) {
      if (m != null && m.originalOwnerIndex == playerIndex) {
        usedOrders.add(m.spawnOrder);
      }
    }
    for (int i = 1; i <= 3; i++) {
      if (!usedOrders.contains(i)) return i;
    }
    return usedOrders.length + 1;
  }

  /// 召喚小兵 (Slot: 0, 1, 2)
  /// 每個玩家最多生成 3 個小兵 (包含在對方槽位的小兵)
  void summonMinion({
    required int playerIndex,
    required int slotIndex,
    String? customName,
  }) {
    if (_state.isGameOver) return;
    if (slotIndex < 0 || slotIndex > 2) return;

    // 檢查玩家自身生成的小兵總數上限 (最多 3 隻)
    if (getPlayerSpawnedMinionsCount(playerIndex) >= 3) return;

    final list = playerIndex == 0 ? _state.player1Minions : _state.player2Minions;
    if (list[slotIndex] != null) return; // 該槽位已有小兵

    _saveSnapshot();

    final nextOrder = getNextSpawnOrder(playerIndex);
    final hero = getHero(playerIndex);
    final isTinna = hero.presetId == 'tinna';

    // 小兵名稱不再附帶 P1 或 P2 前綴，純粹為 "小兵" 或自訂名稱
    final minionName = customName ?? '小兵';
    // 若英雄為 Tinna，小兵預設為 Lv.1 (atk: 5, hp: 10, mov: 3, rng: 3)
    final minion = CharacterUnit.createMinion(
      id: 'minion_${playerIndex}_${slotIndex}_${DateTime.now().millisecondsSinceEpoch}',
      name: minionName,
      slotIndex: slotIndex,
      ownerIndex: playerIndex,
      spawnOrder: nextOrder,
      hp: isTinna ? 10 : 30,
      atk: isTinna ? 5 : 5,
      range: isTinna ? 3 : 1,
      move: isTinna ? 3 : 2,
    );
    if (isTinna) {
      minion.level = 1;
    }

    list[slotIndex] = minion;
    _recalculatePassiveMinionBuffs(playerIndex);
    _syncPassiveSkillCardBuffs(playerIndex);

    _addLog(
      playerIndex: playerIndex,
      actorName: minionName,
      actionTitle: '小兵召喚',
      detail: isTinna
          ? '召喚第 $nextOrder 隻小兵 (Lv.1) 於第 ${slotIndex + 1} 槽位（HP: 10, ATK: 5, RNG: 3, MOV: 3）'
          : '召喚第 $nextOrder 隻小兵於第 ${slotIndex + 1} 槽位（HP: 30, ATK: 5, RNG: 1, MOV: 2）',
      type: LogType.minionSummon,
      skipSnapshot: true,
    );

    notifyListeners();
  }

  /// 撤退或擊殺小兵
  void dismissMinion({
    required int playerIndex,
    required int slotIndex,
    bool isKilled = false,
  }) {
    if (_state.isGameOver) return;
    if (slotIndex < 0 || slotIndex > 2) return;

    final list = playerIndex == 0 ? _state.player1Minions : _state.player2Minions;
    final minion = list[slotIndex];
    if (minion == null) return;

    _saveSnapshot();

    list[slotIndex] = null;
    _recalculatePassiveMinionBuffs(playerIndex);

    _addLog(
      playerIndex: playerIndex,
      actorName: minion.name,
      actionTitle: isKilled ? '小兵陣亡' : '小兵撤退',
      detail: '槽位 #${slotIndex + 1} 已清空',
      type: LogType.minionDismiss,
      skipSnapshot: true,
    );

    // 小兵陣亡或撤退時，重新同步 Tinna 技能卡 1 等級光環
    _syncPassiveSkillCardBuffs(playerIndex);

    notifyListeners();
  }

  /// 小兵數量連動被動增益計算
  /// 需求規格：
  /// 1. 存活 1 個小兵：攻擊範圍 +1
  /// 2. 存活 2 個小兵：移動距離 +1（包含前一個：攻擊範圍 +1, 移動距離 +1）
  /// 3. 存活 3 個小兵：攻擊力 +10（包含前面所有加成：攻擊範圍 +1, 移動距離 +1, 攻擊力 +10）
  /// 4. 只有在開關 (PassiveEnabled) 打開時才會增加效果，關閉則全為 0
  void _recalculatePassiveMinionBuffs(int playerIndex) {
    final list = playerIndex == 0 ? _state.player1Minions : _state.player2Minions;
    final isEnabled = playerIndex == 0 ? _state.player1PassiveEnabled : _state.player2PassiveEnabled;
    final aliveCount = list.where((m) => m != null).length;

    int bonusRange = 0;
    int bonusMove = 0;
    int bonusAtk = 0;

    if (isEnabled) {
      if (aliveCount >= 1) {
        bonusRange = 1;
      }
      if (aliveCount >= 2) {
        bonusMove = 1;
      }
      if (aliveCount >= 3) {
        bonusAtk = 10;
      }
    }

    for (final minion in list) {
      if (minion != null) {
        minion.passiveRangeBonus = bonusRange;
        minion.passiveMoveBonus = bonusMove;
        minion.passiveAtkBonus = bonusAtk;
      }
    }
  }

  /// 取得該玩家小兵被動連動開關狀態
  bool isPassiveEnabled(int playerIndex) {
    return playerIndex == 0 ? _state.player1PassiveEnabled : _state.player2PassiveEnabled;
  }

  /// 切換該玩家小兵被動連動開關
  void togglePassiveEnabled(int playerIndex) {
    if (_state.isGameOver) return;
    _saveSnapshot();
    if (playerIndex == 0) {
      _state.player1PassiveEnabled = !_state.player1PassiveEnabled;
    } else {
      _state.player2PassiveEnabled = !_state.player2PassiveEnabled;
    }
    _recalculatePassiveMinionBuffs(playerIndex);
    notifyListeners();
  }

  // ==========================================
  // 技能卡與專屬技能發動系統 (Skill Cards System)
  // ==========================================

  /// 取得玩家持有的技能卡數量 (0, 1, 2)
  int getSkillCardCopies(int playerIndex, String cardId) {
    final map = playerIndex == 0 ? _state.player1SkillCards : _state.player2SkillCards;
    return map[cardId] ?? 0;
  }

  /// 取得技能在當前每回合最多可發動的次數 (有兩張同樣的技能卡時，發動次數跟著倍增；固有技能固定為原次數)
  int getMaxSkillUsesPerTurn(int playerIndex, SkillEffect effect, SkillCard card) {
    if (card.isHeroInnate) return effect.maxUsesPerTurn;
    final copies = getSkillCardCopies(playerIndex, card.id);
    return effect.maxUsesPerTurn * (copies > 0 ? copies : 1);
  }

  /// 取得技能本回合已發動次數
  int getSkillUsedCount(String effectId) {
    return _state.turnSkillUsage[effectId] ?? 0;
  }

  /// 變更技能卡持有數量 (0, 1, 2)
  void setSkillCardCopies({
    required int playerIndex,
    required String cardId,
    required int copies,
  }) {
    if (_state.isGameOver) return;
    _saveSnapshot();
    final map = playerIndex == 0 ? _state.player1SkillCards : _state.player2SkillCards;
    final clamped = math.max(0, math.min(2, copies));
    map[cardId] = clamped;

    _syncPassiveSkillCardBuffs(playerIndex);
    notifyListeners();
  }

  // --- 印記 (Mark) 專屬管理 (Eris) ---

  /// 取得 Eris 印記最大上限：基礎 10 + 技能卡1 (+5/張) + 技能卡2 (+5/張)
  int getErisMaxMarks(int playerIndex) {
    final c1 = getSkillCardCopies(playerIndex, 'eris_card_1');
    final c2 = getSkillCardCopies(playerIndex, 'eris_card_2');
    return 10 + (c1 * 5) + (c2 * 5);
  }

  /// 取得 Eris 當前場上印記數量
  int getErisMarks(int playerIndex) {
    return _state.customCounters['eris_marks_$playerIndex'] ?? 0;
  }

  /// 變更 Eris 印記數量
  void setErisMarks(int playerIndex, int count) {
    if (_state.isGameOver) return;
    _saveSnapshot();
    final maxMarks = getErisMaxMarks(playerIndex);
    final clamped = math.max(0, math.min(maxMarks, count));
    _state.customCounters['eris_marks_$playerIndex'] = clamped;
    notifyListeners();
  }

  /// 取得 Eris 印記引爆傷害：基礎 10 + 技能卡1 (+5/張)
  int getErisMarkDamage(int playerIndex) {
    final c1 = getSkillCardCopies(playerIndex, 'eris_card_1');
    return 10 + (c1 * 5);
  }

  /// 同步計算技能卡的被動常駐 Buff (如 Luna 技能卡 1、Tinna 技能卡 1)
  void _syncPassiveSkillCardBuffs(int playerIndex) {
    final hero = getHero(playerIndex);

    // --- Luna 技能卡 1 被動 ---
    if (hero.presetId == 'luna') {
      final c1Copies = getSkillCardCopies(playerIndex, 'luna_card_1');
      hero.effects.removeWhere((e) => e.id == 'passive_luna_c1');

      if (c1Copies > 0) {
        final bonusAtk = 20 * c1Copies;
        final bonusMove = 1 * c1Copies;
        hero.effects.add(
          StatusEffect(
            id: 'passive_luna_c1',
            name: c1Copies > 1 ? '狂暴突破 (x2)' : '狂暴突破',
            iconCode: 'flash',
            atkDelta: bonusAtk,
            moveDelta: bonusMove,
            isPermanent: true,
          ),
        );
      }
    }

    // --- Tinna 技能卡 1 被動光環 (根據場上是否有對應等級小兵) ---
    if (hero.presetId == 'tinna') {
      final c1Copies = getSkillCardCopies(playerIndex, 'tinna_card_1');
      final minions = (playerIndex == 0 ? _state.player1Minions : _state.player2Minions)
          .whereType<CharacterUnit>()
          .toList();

      final hasLv2 = minions.any((m) => m.level == 2);
      final hasLv3 = minions.any((m) => m.level == 3);

      // 清除 Tinna 本體與我方小兵的 Tinna 技能卡 1 被動
      hero.effects.removeWhere((e) => e.id == 'passive_tinna_c1_hero');
      for (final m in minions) {
        m.effects.removeWhere((e) => e.id == 'passive_tinna_c1_minion');
      }

      if (c1Copies > 0) {
        // LV2: 緹娜步數 +1 (持有2張則 +2)
        final moveBonus = hasLv2 ? (1 * c1Copies) : 0;
        // LV3: 我方全體單位攻擊力 +5 (持有2張則 +10)
        final atkBonus = hasLv3 ? (5 * c1Copies) : 0;

        if (moveBonus > 0 || atkBonus > 0) {
          hero.effects.add(
            StatusEffect(
              id: 'passive_tinna_c1_hero',
              name: c1Copies > 1 ? '等級連鎖 (x2)' : '等級連鎖',
              iconCode: 'flash',
              moveDelta: moveBonus,
              atkDelta: atkBonus,
              isPermanent: true,
            ),
          );
        }

        if (atkBonus > 0) {
          for (final m in minions) {
            m.effects.add(
              StatusEffect(
                id: 'passive_tinna_c1_minion',
                name: c1Copies > 1 ? '等級連鎖 (x2)' : '等級連鎖',
                iconCode: 'flash',
                atkDelta: atkBonus,
                isPermanent: true,
              ),
            );
          }
        }
      }
    }
  }

  /// 發動技能效果
  void executeSkill({
    required int playerIndex,
    required SkillCard card,
    required SkillEffect effect,
    CharacterUnit? targetUnit,
    int? deductHpCost,
  }) {
    if (_state.isGameOver) return;
    final hero = getHero(playerIndex);

    // 檢查次數
    final maxUses = getMaxSkillUsesPerTurn(playerIndex, effect, card);
    final usedCount = getSkillUsedCount(effect.id);
    if (usedCount >= maxUses) return;

    _saveSnapshot();

    // 1. 扣除生命代價 (優先採用直接傳入的自訂代價，例如印記穿梭選擇扣除 20 生命)
    final actualHpCost = deductHpCost ?? effect.hpCost;
    if (actualHpCost > 0) {
      hero.baseHp = math.max(0, hero.baseHp - actualHpCost);
    }

    // 2. 針對具體技能效果進行業務邏輯處理
    String actionDetail = '';

    // [Luna 固有 - 攻擊強化]
    if (effect.id == 'luna_innate_1' && targetUnit != null) {
      targetUnit.effects.removeWhere((e) => e.id == 'buff_luna_innate_1');
      targetUnit.effects.add(
        const StatusEffect(
          id: 'buff_luna_innate_1',
          name: 'Luna 攻擊強化',
          iconCode: 'flash',
          atkDelta: 5,
          turnsRemaining: 1,
        ),
      );
      actionDetail = '指定【${targetUnit.name}】攻擊力 +5 (持續至本回合結束)';
    }
    // [Luna 固有 - 位置交換]
    else if (effect.id == 'luna_innate_2' && targetUnit != null) {
      actionDetail = '扣除 10 HP，與【${targetUnit.name}】交換戰鬥位置';
    }
    // [Luna 技能卡 1 - 瀕死替換]
    else if (effect.id == 'luna_c1_eff2') {
      // 丟棄一張卡片
      final curCopies = getSkillCardCopies(playerIndex, card.id);
      if (curCopies > 0) {
        final map = playerIndex == 0 ? _state.player1SkillCards : _state.player2SkillCards;
        map[card.id] = curCopies - 1;
        _syncPassiveSkillCardBuffs(playerIndex);
      }
      actionDetail = targetUnit != null
          ? '棄置一張【${card.name}】，抵消傷害並與【${targetUnit.name}】交換位置'
          : '棄置一張【${card.name}】，抵消一次傷害';
    }
    // [Luna 技能卡 2 - 契約檢索]
    else if (effect.id == 'luna_c2_eff1') {
      actionDetail = '支付 20 HP，從卡組或墓地將契約卡加入手牌';
    }
    // [Luna 技能卡 2 - 怪物獻祭回血30]
    else if (effect.id == 'luna_c2_eff2' && targetUnit != null) {
      hero.baseHp = math.min(hero.maxHp, hero.baseHp + 30);
      final owner = getUnitOwner(targetUnit.id);
      if (targetUnit.slotIndex != null) {
        dismissMinion(
          playerIndex: owner,
          slotIndex: targetUnit.slotIndex!,
          isKilled: true,
        );
      }
      actionDetail = '獻祭【${targetUnit.name}】，${hero.name} 回復 30 點生命值';
    }
    // [Eris 固有 - 放置印記]
    else if (effect.id == 'eris_innate_1') {
      final curMarks = getErisMarks(playerIndex);
      final maxMarks = getErisMaxMarks(playerIndex);
      final newMarks = math.min(maxMarks, curMarks + 1);
      _state.customCounters['eris_marks_$playerIndex'] = newMarks;
      actionDetail = '在攻擊範圍內的 1 個格子放置印記（場上印記: $newMarks / $maxMarks）';
    }
    // [Eris 固有 - 替罪轉移]
    else if (effect.id == 'eris_innate_2' && targetUnit != null) {
      final owner = getUnitOwner(targetUnit.id);
      if (targetUnit.slotIndex != null) {
        dismissMinion(
          playerIndex: owner,
          slotIndex: targetUnit.slotIndex!,
          isKilled: true,
        );
      }
      actionDetail = '犧牲【${targetUnit.name}】抵消傷害，並可移動敵方攻擊單位 4 格';
    }
    // [Eris 技能卡 1 - 印記穿梭]
    else if (effect.id == 'eris_c1_eff3') {
      actionDetail = actualHpCost > 0
          ? '支付 20 HP，傳送至任意印記格子'
          : '釋放已佔領的佔領點，傳送至任意印記格子';
    }
    // [Tinna 固有 - 能量/生命召喚 Lv.1 小兵]
    else if (effect.id == 'tinna_innate_2') {
      final isEnergy = deductHpCost == null || deductHpCost == 0;
      if (isEnergy) {
        hero.currentEnergy = math.max(0, (hero.currentEnergy ?? 0) - 2);
      }
      actionDetail = isEnergy
          ? '消耗 2 點能量召喚一隻 Lv.1 小兵'
          : '消耗 10 點生命值召喚一隻 Lv.1 小兵';
    }
    // [Tinna 技能卡 2 - 致命傷害抵消]
    else if (effect.id == 'tinna_c2_eff') {
      actionDetail = targetUnit != null
          ? '犧牲【${targetUnit.name}】代替破壞，抵消致命傷害並傳送至我方出生點/佔領點'
          : '破壞【${card.name}】，抵消致命傷害並傳送至我方出生點/佔領點';
    } else {
      actionDetail = '發動效果：${effect.name}';
    }

    // 3. 記錄發動次數
    _state.turnSkillUsage[effect.id] = usedCount + 1;

    // 4. 寫入戰鬥紀錄
    _addLog(
      playerIndex: playerIndex,
      actorName: hero.name,
      actionTitle: '技能發動【${effect.name}】',
      detail: actionDetail,
      type: LogType.skill,
      skipSnapshot: true,
    );

    _checkGameOver();
    notifyListeners();
  }

  /// Eris 踩中印記引爆傷害結算
  void triggerErisMarkDamage({
    required int playerIndex,
    required CharacterUnit targetUnit,
    required int marksToConsume,
  }) {
    if (_state.isGameOver) return;
    final hero = getHero(playerIndex);
    final curMarks = getErisMarks(playerIndex);
    final count = math.min(curMarks, math.max(1, marksToConsume));

    _saveSnapshot();

    // 計算傷害：每枚印記傷害 (基礎 10 + 技能卡1加成)
    final perMarkDmg = getErisMarkDamage(playerIndex);
    final totalDmg = perMarkDmg * count;

    // 扣除印記
    _state.customCounters['eris_marks_$playerIndex'] = curMarks - count;

    // 扣除目標生命
    final oldHp = targetUnit.baseHp;
    targetUnit.baseHp = math.max(0, targetUnit.baseHp - totalDmg);

    _addLog(
      playerIndex: playerIndex,
      actorName: hero.name,
      actionTitle: '印記引爆',
      detail: '消耗 $count 個印記，對【${targetUnit.name}】造成 $totalDmg 傷害 (HP $oldHp ➔ ${targetUnit.baseHp})，剩餘印記: ${curMarks - count}',
      type: LogType.skill,
      skipSnapshot: true,
    );

    _checkGameOver();
    notifyListeners();
  }

  /// Eris 回收印記兌換效果 (4: 傳送, 5: 回復20血, 10: 佔領任意佔領點)
  void recycleErisMarks({
    required int playerIndex,
    required int tierMarks, // 4, 5, 10
  }) {
    if (_state.isGameOver) return;
    final hero = getHero(playerIndex);
    final curMarks = getErisMarks(playerIndex);
    if (curMarks < tierMarks) return;

    _saveSnapshot();

    // 扣除指定數量印記
    _state.customCounters['eris_marks_$playerIndex'] = curMarks - tierMarks;

    String effectDetail = '';
    if (tierMarks == 4) {
      effectDetail = '回收 4 個印記：傳送至任意印記格子';
    } else if (tierMarks == 5) {
      final oldHp = hero.baseHp;
      hero.baseHp = math.min(hero.maxHp, hero.baseHp + 20);
      effectDetail = '回收 5 個印記：${hero.name} 回復 20 HP (HP $oldHp ➔ ${hero.baseHp})';
    } else if (tierMarks == 10) {
      effectDetail = '回收 10 個印記：獲得任意佔領點之佔領權（含對方佔領點）';
    }

    _addLog(
      playerIndex: playerIndex,
      actorName: hero.name,
      actionTitle: '印記回收',
      detail: '$effectDetail，剩餘印記: ${curMarks - tierMarks}',
      type: LogType.skill,
      skipSnapshot: true,
    );

    _checkGameOver();
    notifyListeners();
  }

  /// 切換回合
  ///
  /// 需求規格：
  /// - 當對手一結束回合（即輪到新行動方開始其回合）時，馬上執行該新行動方的：
  ///   1. 持續效果生命值加減（毒素/燃燒傷害或生命再生）。
  ///   2. 能量值加減（若開啟能量系統且有每回合增減設定）。
  ///   3. 狀態效果剩餘回合數進行 -1 倒數，歸零時自動移除失效效果。
  /// - 切換至新行動方，若輪回到 P1 則 Round + 1。
  void nextTurn() {
    if (_state.isGameOver) return;

    _saveSnapshot();

    final previousActingPlayer = _state.activePlayerIndex;
    final nextPlayerIndex = previousActingPlayer == 0 ? 1 : 0;
    if (nextPlayerIndex == 0) {
      _state.roundNumber += 1;
    }
    _state.activePlayerIndex = nextPlayerIndex;

    final nextPlayerName = nextPlayerIndex == 0 ? _state.player1.name : _state.player2.name;
    _addLog(
      playerIndex: nextPlayerIndex,
      actorName: '系統',
      actionTitle: '切換回合',
      detail: '輪到 $nextPlayerName 行動（第 ${_state.roundNumber} 回合）',
      type: LogType.turnChange,
      skipSnapshot: true,
    );

    // 當對手一結束回合，立刻為即將行動的玩家單位執行生命值、能量值與效果倒數結算
    final incomingHero = nextPlayerIndex == 0 ? _state.player1 : _state.player2;
    final incomingMinions =
        nextPlayerIndex == 0 ? _state.player1Minions : _state.player2Minions;

    final incomingUnits = <CharacterUnit>[
      incomingHero,
      ...incomingMinions.whereType<CharacterUnit>(),
    ];

    for (final unit in incomingUnits) {
      final effectsToKeep = <StatusEffect>[];

      for (final effect in unit.effects) {
        // 1. 每到自己回合一開始：生命值加減結算 (如毒素扣血、再生回血)
        if (effect.hpPerTurnDelta != 0) {
          final oldHp = unit.baseHp;
          unit.baseHp += effect.hpPerTurnDelta;
          if (unit.baseHp < 0) unit.baseHp = 0;

          _addLog(
            playerIndex: nextPlayerIndex,
            actorName: unit.name,
            actionTitle: effect.hpPerTurnDelta < 0 ? '持續傷害結算' : '持續治療結算',
            detail: '受「${effect.name}」影響，HP $oldHp ➔ ${unit.baseHp} (${effect.hpPerTurnDelta > 0 ? "+${effect.hpPerTurnDelta}" : "${effect.hpPerTurnDelta}"})',
            type: LogType.buffTick,
            skipSnapshot: true,
          );
        }

        // 2. 回合數扣除邏輯
        if (effect.isPermanent) {
          effectsToKeep.add(effect);
        } else {
          final remaining = effect.turnsRemaining - 1;
          if (remaining > 0) {
            effectsToKeep.add(effect.copyWith(turnsRemaining: remaining));
          } else {
            // 效果到期自動移除
            _addLog(
              playerIndex: nextPlayerIndex,
              actorName: unit.name,
              actionTitle: '狀態效果結束',
              detail: '「${effect.name}」持續時間結束，效果已自然消退',
              type: LogType.buffRemove,
              skipSnapshot: true,
            );
          }
        }
      }

      unit.effects = effectsToKeep;

      // 3. 每到自己回合一開始：能量值加減結算
      if (unit.currentEnergy != null && unit.energyPerTurnDelta != 0) {
        final oldEnergy = unit.currentEnergy!;
        final newEnergy = math.min(
          unit.maxEnergy,
          math.max(unit.minEnergy, oldEnergy + unit.energyPerTurnDelta),
        );
        unit.currentEnergy = newEnergy;

        _addLog(
          playerIndex: nextPlayerIndex,
          actorName: unit.name,
          actionTitle: '能量結算',
          detail: '每回合能量變化: $oldEnergy ➔ $newEnergy (${unit.energyPerTurnDelta > 0 ? "+${unit.energyPerTurnDelta}" : "${unit.energyPerTurnDelta}"})',
          type: LogType.system,
          skipSnapshot: true,
        );
      }
    }

    // 4. 重設該回合技能卡主動發動次數
    _state.turnSkillUsage.clear();

    // 5. 處理 Tinna 技能卡 1【LV1 護盾只在對方回合生效】：
    // 當切換到自己的回合時，對方回合結束，清除 Tinna 的臨時護盾
    if (incomingHero.presetId == 'tinna') {
      incomingHero.effects.removeWhere((e) => e.id == 'shield_tinna_c1');
    }

    // 當對方回合開始時（即剛剛結束行動的玩家回合），若對手是 Tinna 且有 Lv.1 小兵與技能卡 1，獲得 +5 (或 +10) 護盾
    final waitingPlayerIndex = previousActingPlayer;
    final waitingHero = getHero(waitingPlayerIndex);
    if (waitingHero.presetId == 'tinna') {
      final c1Copies = getSkillCardCopies(waitingPlayerIndex, 'tinna_card_1');
      final waitingMinions = (waitingPlayerIndex == 0 ? _state.player1Minions : _state.player2Minions)
          .whereType<CharacterUnit>()
          .toList();
      final hasLv1 = waitingMinions.any((m) => m.level == 1);

      waitingHero.effects.removeWhere((e) => e.id == 'shield_tinna_c1');
      if (c1Copies > 0 && hasLv1) {
        final shieldAmount = 5 * c1Copies;
        waitingHero.effects.add(
          StatusEffect(
            id: 'shield_tinna_c1',
            name: c1Copies > 1 ? '守護壁壘 (x2)' : '守護壁壘',
            iconCode: 'shield',
            shieldDelta: shieldAmount,
            isPermanent: true, // 在對方回合內常駐生效，輪回到自己回合時由上面第 5 點自動移除
          ),
        );
        _addLog(
          playerIndex: waitingPlayerIndex,
          actorName: waitingHero.name,
          actionTitle: '技能卡1【Lv.1連鎖】',
          detail: '對方回合開始，${waitingHero.name} 獲得 $shieldAmount 點護盾（對方回合結束時消退）',
          type: LogType.skill,
          skipSnapshot: true,
        );
      }
    }

    // 檢查生命值歸零
    _checkGameOver();
    notifyListeners();
  }

  /// 檢查是否觸發遊戲結束 (當任一角色英雄生命值扣到 0 或以下)
  void _checkGameOver() {
    if (_state.isGameOver) return;

    if (_state.player1.baseHp <= 0 && _state.player2.baseHp <= 0) {
      _state.isGameOver = true;
      _state.winnerIndex = -1; // 平手
      _state.gameOverReason = '雙方英雄同時倒下，戰局平手！';
      _addLog(
        playerIndex: -1,
        actorName: '系統',
        actionTitle: '遊戲結束',
        detail: '雙方英雄生命值歸零，平局！',
        type: LogType.gameOver,
        skipSnapshot: true,
      );
    } else if (_state.player1.baseHp <= 0) {
      _state.isGameOver = true;
      _state.winnerIndex = 1;
      _state.gameOverReason = '${_state.player2.name} 擊敗了對手，贏得勝利！';
      _addLog(
        playerIndex: 1,
        actorName: '系統',
        actionTitle: '遊戲結束',
        detail: '${_state.player1.name} 生命值歸零，${_state.player2.name} 獲勝！',
        type: LogType.gameOver,
        skipSnapshot: true,
      );
    } else if (_state.player2.baseHp <= 0) {
      _state.isGameOver = true;
      _state.winnerIndex = 0;
      _state.gameOverReason = '${_state.player1.name} 擊敗了對手，贏得勝利！';
      _addLog(
        playerIndex: 0,
        actorName: '系統',
        actionTitle: '遊戲結束',
        detail: '${_state.player2.name} 生命值歸零，${_state.player1.name} 獲勝！',
        type: LogType.gameOver,
        skipSnapshot: true,
      );
    }
  }

  /// 手動結束遊戲
  void manualEndGame() {
    _saveSnapshot();
    _state.isGameOver = true;
    _state.winnerIndex = null;
    _state.gameOverReason = '玩家手動提前結束本局對戰。';

    _addLog(
      playerIndex: -1,
      actorName: '系統',
      actionTitle: '手動結束遊戲',
      detail: '玩家確認提前結束遊戲',
      type: LogType.gameOver,
      skipSnapshot: true,
    );

    notifyListeners();
  }

  /// 重新開始新遊戲 (可選擇先攻方與自訂/選擇的英雄)
  void restartGame({
    int startingPlayerIndex = 0,
    CharacterUnit? hero1,
    CharacterUnit? hero2,
  }) {
    _saveSnapshot();
    _state = GameState.initial(
      startingPlayerIndex: startingPlayerIndex,
      hero1: hero1,
      hero2: hero2,
    );
    _recalculatePassiveMinionBuffs(0);
    _recalculatePassiveMinionBuffs(1);
    notifyListeners();
  }

  /// 快速切換或設定先攻方（於遊戲準備階段）
  void setStartingPlayer(int playerIndex) {
    if (_state.isGameOver) return;
    _saveSnapshot();
    _state.activePlayerIndex = playerIndex;
    final name = playerIndex == 0 ? _state.player1.name : _state.player2.name;
    _addLog(
      playerIndex: playerIndex,
      actorName: '系統',
      actionTitle: '設定先攻方',
      detail: '先攻順序設定為: $name',
      type: LogType.system,
      skipSnapshot: true,
    );
    notifyListeners();
  }

  /// 擲骰子
  int rollDice({required int sides, required String rollerName, int? playerIndex}) {
    final result = math.Random().nextInt(sides) + 1;
    _addLog(
      playerIndex: playerIndex ?? _state.activePlayerIndex,
      actorName: rollerName,
      actionTitle: '甩骰子 (D$sides)',
      detail: '$rollerName 擲出了 $result 點！ (1~$sides)',
      type: LogType.diceRoll,
      skipSnapshot: true,
    );
    notifyListeners();
    return result;
  }

  /// 檢查對方小兵格是否有空位
  bool canTransferMinion(int fromPlayerIndex) {
    final targetList = fromPlayerIndex == 0 ? _state.player2Minions : _state.player1Minions;
    return targetList.any((m) => m == null);
  }

  /// 獲取對方小兵格的第一個可用空位索引 (-1 表示無位置)
  int getFirstAvailableSlot(int targetPlayerIndex) {
    final list = targetPlayerIndex == 0 ? _state.player1Minions : _state.player2Minions;
    return list.indexWhere((m) => m == null);
  }

  /// 轉移或移動小兵到指定的玩家槽位 (支援 Drag & Drop 移到己方或對方任意指定空位)
  ///
  /// 需求規格：
  /// - 移動後小兵的名字不會改動
  /// - 名字的 header 與 icon 顏色依然使用原本創立時的顏色 (originalOwnerIndex)
  /// - 帶著小兵本身的效果、攻擊力、生命值、護盾值等
  /// - 移動後，雙方各自根據存活小兵數量重新計算被動加成，對方效果也會被觸發！
  bool moveMinionToSlot({
    required int fromPlayerIndex,
    required int fromSlotIndex,
    required int toPlayerIndex,
    required int toSlotIndex,
  }) {
    if (_state.isGameOver) return false;
    if (fromSlotIndex < 0 || fromSlotIndex > 2 || toSlotIndex < 0 || toSlotIndex > 2) return false;

    // 若拖曳到同一格，不做任何處理
    if (fromPlayerIndex == toPlayerIndex && fromSlotIndex == toSlotIndex) return true;

    final sourceList = fromPlayerIndex == 0 ? _state.player1Minions : _state.player2Minions;
    final targetList = toPlayerIndex == 0 ? _state.player1Minions : _state.player2Minions;

    final minion = sourceList[fromSlotIndex];
    if (minion == null) return false;

    // 若目標格子已被佔用則不予移動
    if (targetList[toSlotIndex] != null) return false;

    _saveSnapshot();

    // 從原本位置移除
    sourceList[fromSlotIndex] = null;

    // 保留小兵原本的名字、原始創建陣營色彩 (originalOwnerIndex)、生成序號 (spawnOrder)、等級 (level)、能量與屬性效果
    final transferredMinion = CharacterUnit(
      id: minion.id,
      name: minion.name, // 保持原本名字不改動
      isHero: false,
      slotIndex: toSlotIndex,
      originalOwnerIndex: minion.originalOwnerIndex, // 保持原本創立時的顏色
      spawnOrder: minion.spawnOrder, // 保持原本的生成序號
      level: minion.level, // 保持小兵已設定的等級 (Lv1~Lv3)
      baseHp: minion.baseHp,
      maxHp: minion.maxHp,
      baseShield: minion.baseShield,
      baseAtk: minion.baseAtk,
      baseRange: minion.baseRange,
      baseMove: minion.baseMove,
      currentEnergy: minion.currentEnergy,
      energyPerTurnDelta: minion.energyPerTurnDelta,
      minEnergy: minion.minEnergy,
      maxEnergy: minion.maxEnergy,
      effects: minion.effects.map((e) => e.copyWith()).toList(),
    );

    targetList[toSlotIndex] = transferredMinion;

    // 雙方重新計算被動增益（雙方小兵數量連動效果即時生效）
    _recalculatePassiveMinionBuffs(0);
    _recalculatePassiveMinionBuffs(1);

    final fromName = fromPlayerIndex == 0 ? '玩家 1' : '玩家 2';
    final toName = toPlayerIndex == 0 ? '玩家 1' : '玩家 2';

    _addLog(
      playerIndex: toPlayerIndex,
      actorName: transferredMinion.name,
      actionTitle: fromPlayerIndex == toPlayerIndex ? '小兵調動' : '小兵陣營轉移',
      detail: fromPlayerIndex == toPlayerIndex
          ? '「${minion.name}」在 $fromName 陣地內調整至槽位 #${toSlotIndex + 1}'
          : '「${minion.name}」由 $fromName 移動至 $toName 槽位 #${toSlotIndex + 1}！',
      type: LogType.minionTransfer,
      skipSnapshot: true,
    );

    notifyListeners();
    return true;
  }

  /// 轉移小兵到對方小兵格 (快捷按鈕使用)
  bool transferMinionToOpponent({
    required int fromPlayerIndex,
    required int fromSlotIndex,
    int? targetSlotIndex,
  }) {
    final toPlayerIndex = fromPlayerIndex == 0 ? 1 : 0;
    final targetList = toPlayerIndex == 0 ? _state.player1Minions : _state.player2Minions;

    final destSlot = targetSlotIndex ?? targetList.indexWhere((m) => m == null);
    if (destSlot == -1 || destSlot > 2 || targetList[destSlot] != null) {
      return false; // 對方無空位
    }

    return moveMinionToSlot(
      fromPlayerIndex: fromPlayerIndex,
      fromSlotIndex: fromSlotIndex,
      toPlayerIndex: toPlayerIndex,
      toSlotIndex: destSlot,
    );
  }
}
