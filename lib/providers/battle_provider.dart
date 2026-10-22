import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/character_unit.dart';
import '../models/game_log.dart';
import '../models/game_state.dart';
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
    _addLog(
      playerIndex: owner,
      actorName: unit.name,
      actionTitle: '調整小兵等級',
      detail: level != null ? '等級設定為 Lv.$level' : '已清除等級標籤',
      type: LogType.system,
      skipSnapshot: true,
    );
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
    // 小兵名稱不再附帶 P1 或 P2 前綴，純粹為 "小兵" 或自訂名稱
    final minionName = customName ?? '小兵';
    final minion = CharacterUnit.createMinion(
      id: 'minion_${playerIndex}_${slotIndex}_${DateTime.now().millisecondsSinceEpoch}',
      name: minionName,
      slotIndex: slotIndex,
      ownerIndex: playerIndex,
      spawnOrder: nextOrder,
    );

    list[slotIndex] = minion;
    _recalculatePassiveMinionBuffs(playerIndex);

    _addLog(
      playerIndex: playerIndex,
      actorName: minionName,
      actionTitle: '小兵召喚',
      detail: '召喚第 $nextOrder 隻小兵於第 ${slotIndex + 1} 槽位（HP: 30, ATK: 5, RNG: 1, MOV: 2）',
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
