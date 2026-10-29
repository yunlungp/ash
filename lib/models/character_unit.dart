import 'dart:math' as math;
import 'status_effect.dart';

enum StatType {
  hp,
  shield,
  atk,
  range,
  move,
  energy,
}

extension StatTypeExtension on StatType {
  String get displayName {
    switch (this) {
      case StatType.hp:
        return '生命值 (HP)';
      case StatType.shield:
        return '護盾值 (Shield)';
      case StatType.atk:
        return '攻擊力 (ATK)';
      case StatType.range:
        return '攻擊範圍 (Range)';
      case StatType.move:
        return '移動距離 (Movement)';
      case StatType.energy:
        return '能量值 (Energy)';
    }
  }

  String get shortCode {
    switch (this) {
      case StatType.hp:
        return 'HP';
      case StatType.shield:
        return 'SHD';
      case StatType.atk:
        return 'ATK';
      case StatType.range:
        return 'RNG';
      case StatType.move:
        return 'MOV';
      case StatType.energy:
        return 'EN';
    }
  }
}

/// 代表戰場上的英雄或小兵單位
class CharacterUnit {
  final String id;
  String name;
  final bool isHero;
  final int? slotIndex; // 若為小兵，表示在第幾個槽位 (0, 1, 2)
  final int originalOwnerIndex; // 原始建立者玩家 (0: P1, 1: P2)，用於保持原色與標籤
  final int spawnOrder; // 玩家生成的第幾個小兵 (1, 2, 3...)
  final String? avatarAsset; // 角色頭像圖片路徑 (如 'photo/eris.png')
  int? level; // 小兵等級 (1, 2, 3)，可選，null 代表尚未選擇或英雄
  int baseHp;
  int maxHp;
  int baseShield; // 護盾值
  int baseAtk;
  int baseRange;
  int baseMove;
  int? currentEnergy; // 當前能量值 (只有在開啟能量值時才生效/顯示)
  int energyPerTurnDelta; // 每回合能量增減 (+/-)
  int minEnergy; // 能量下限
  int maxEnergy; // 能量上限
  List<StatusEffect> effects;

  final String? presetId; // 對應的 HeroPreset ID (如 'eris', 'luna', 'tinna', 'custom')

  // 小兵數量連動的額外被動加成（由 Provider 動態更新到小兵）
  int passiveAtkBonus;
  int passiveRangeBonus;
  int passiveMoveBonus;

  CharacterUnit({
    required this.id,
    required this.name,
    required this.isHero,
    this.presetId,
    this.slotIndex,
    this.originalOwnerIndex = 0,
    this.spawnOrder = 1,
    this.avatarAsset,
    this.level,
    required this.baseHp,
    required this.maxHp,
    this.baseShield = 0,
    required this.baseAtk,
    required this.baseRange,
    required this.baseMove,
    this.currentEnergy,
    this.energyPerTurnDelta = 0,
    this.minEnergy = 0,
    this.maxEnergy = 100,
    List<StatusEffect>? effects,
    this.passiveAtkBonus = 0,
    this.passiveRangeBonus = 0,
    this.passiveMoveBonus = 0,
  }) : effects = effects ?? [];

  /// 建立預設英雄單位 (Player 1 或 2)
  factory CharacterUnit.createHero({
    required String id,
    required String name,
    String? presetId,
    int ownerIndex = 0,
    String? avatarAsset,
    int hp = 100,
    int shield = 0,
    int atk = 15,
    int range = 2,
    int move = 3,
    int? currentEnergy,
    int energyPerTurnDelta = 0,
    int minEnergy = 0,
    int maxEnergy = 100,
  }) {
    return CharacterUnit(
      id: id,
      name: name,
      isHero: true,
      presetId: presetId,
      originalOwnerIndex: ownerIndex,
      avatarAsset: avatarAsset,
      baseHp: hp,
      maxHp: hp,
      baseShield: shield,
      baseAtk: atk,
      baseRange: range,
      baseMove: move,
      currentEnergy: currentEnergy,
      energyPerTurnDelta: energyPerTurnDelta,
      minEnergy: minEnergy,
      maxEnergy: maxEnergy,
      effects: [],
    );
  }

  /// 建立預設小兵單位 (需求第 8 點：HP 30, ATK 5, Range 1, Move 2, 預設 Shield 0)
  factory CharacterUnit.createMinion({
    required String id,
    required String name,
    required int slotIndex,
    required int ownerIndex,
    int spawnOrder = 1,
    int hp = 30,
    int shield = 0,
    int atk = 5,
    int range = 1,
    int move = 2,
  }) {
    return CharacterUnit(
      id: id,
      name: name,
      isHero: false,
      slotIndex: slotIndex,
      originalOwnerIndex: ownerIndex,
      spawnOrder: spawnOrder,
      baseHp: hp,
      maxHp: hp,
      baseShield: shield,
      baseAtk: atk,
      baseRange: range,
      baseMove: move,
      effects: [],
    );
  }

  /// 所有 Buff/Debuff 對 Shield 的影響加總
  int get buffShieldDelta =>
      effects.fold(0, (sum, effect) => sum + effect.shieldDelta);

  /// 所有 Buff/Debuff 對 ATK 的影響加總
  int get buffAtkDelta =>
      effects.fold(0, (sum, effect) => sum + effect.atkDelta);

  /// 所有 Buff/Debuff 對 Range 的影響加總
  int get buffRangeDelta =>
      effects.fold(0, (sum, effect) => sum + effect.rangeDelta);

  /// 所有 Buff/Debuff 對 Move 的影響加總
  int get buffMoveDelta =>
      effects.fold(0, (sum, effect) => sum + effect.moveDelta);

  /// 當前動態計算後的有效生命值
  int get effectiveHp => baseHp;

  /// 當前動態計算後的有效護盾值 (不可小於 0)
  int get effectiveShield => math.max(0, baseShield + buffShieldDelta);

  /// 當前動態計算後的有效攻擊力 (不可小於 0)
  int get effectiveAtk =>
      math.max(0, baseAtk + buffAtkDelta + passiveAtkBonus);

  /// 當前動態計算後的有效攻擊範圍 (不可小於 0)
  int get effectiveRange =>
      math.max(0, baseRange + buffRangeDelta + passiveRangeBonus);

  /// 當前動態計算後的有效移動距離 (不可小於 0)
  int get effectiveMove =>
      math.max(0, baseMove + buffMoveDelta + passiveMoveBonus);

  /// 取得特定屬性的基礎值
  int getBaseStat(StatType type) {
    switch (type) {
      case StatType.hp:
        return baseHp;
      case StatType.shield:
        return baseShield;
      case StatType.atk:
        return baseAtk;
      case StatType.range:
        return baseRange;
      case StatType.move:
        return baseMove;
      case StatType.energy:
        return currentEnergy ?? 0;
    }
  }

  /// 取得特定屬性的最終有效值
  int getEffectiveStat(StatType type) {
    switch (type) {
      case StatType.hp:
        return effectiveHp;
      case StatType.shield:
        return effectiveShield;
      case StatType.atk:
        return effectiveAtk;
      case StatType.range:
        return effectiveRange;
      case StatType.move:
        return effectiveMove;
      case StatType.energy:
        return currentEnergy ?? 0;
    }
  }

  /// 設定特定屬性的基礎值
  void setBaseStat(StatType type, int val) {
    switch (type) {
      case StatType.hp:
        baseHp = val;
        break;
      case StatType.shield:
        baseShield = math.max(0, val);
        break;
      case StatType.atk:
        baseAtk = math.max(0, val);
        break;
      case StatType.range:
        baseRange = math.max(0, val);
        break;
      case StatType.move:
        baseMove = math.max(0, val);
        break;
      case StatType.energy:
        if (currentEnergy != null) {
          currentEnergy = math.min(maxEnergy, math.max(minEnergy, val));
        }
        break;
    }
  }

  /// 深層拷貝
  CharacterUnit deepCopy() {
    return CharacterUnit(
      id: id,
      name: name,
      isHero: isHero,
      presetId: presetId,
      slotIndex: slotIndex,
      originalOwnerIndex: originalOwnerIndex,
      spawnOrder: spawnOrder,
      avatarAsset: avatarAsset,
      level: level,
      baseHp: baseHp,
      maxHp: maxHp,
      baseShield: baseShield,
      baseAtk: baseAtk,
      baseRange: baseRange,
      baseMove: baseMove,
      currentEnergy: currentEnergy,
      energyPerTurnDelta: energyPerTurnDelta,
      minEnergy: minEnergy,
      maxEnergy: maxEnergy,
      effects: effects.map((e) => e.copyWith()).toList(),
      passiveAtkBonus: passiveAtkBonus,
      passiveRangeBonus: passiveRangeBonus,
      passiveMoveBonus: passiveMoveBonus,
    );
  }
}
