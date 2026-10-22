import 'package:flutter/material.dart';

/// 狀態效果類型與影響屬性
class StatusEffect {
  final String id;
  final String name;
  final String iconCode; // 預設圖示名稱
  final int shieldDelta; // 護盾加成/減成
  final int atkDelta; // 攻擊力加成/減成
  final int rangeDelta; // 攻擊範圍加成/減成
  final int moveDelta; // 移動距離加成/減成
  final int hpPerTurnDelta; // 每回合生命值變化（負數為毒素/燃燒，正數為再生）
  final int turnsRemaining; // 剩餘回合數
  final bool isPermanent; // 是否為永久效果
  final bool isDebuff; // 是否為負面效果
  final String description;

  // 能量值系統相關設定
  final bool hasEnergy; // 是否開啟能量值
  final int initialEnergy; // 原始數量
  final int energyPerTurnDelta; // 每到自己回合增加或減少多少能量 (+/-)
  final int maxEnergy; // 最大能量值
  final int minEnergy; // 最小能量值

  const StatusEffect({
    required this.id,
    required this.name,
    this.iconCode = 'flash',
    this.shieldDelta = 0,
    this.atkDelta = 0,
    this.rangeDelta = 0,
    this.moveDelta = 0,
    this.hpPerTurnDelta = 0,
    this.turnsRemaining = 2,
    this.isPermanent = false,
    this.isDebuff = false,
    this.description = '',
    this.hasEnergy = false,
    this.initialEnergy = 0,
    this.energyPerTurnDelta = 0,
    this.maxEnergy = 100,
    this.minEnergy = 0,
  });

  StatusEffect copyWith({
    String? id,
    String? name,
    String? iconCode,
    int? shieldDelta,
    int? atkDelta,
    int? rangeDelta,
    int? moveDelta,
    int? hpPerTurnDelta,
    int? turnsRemaining,
    bool? isPermanent,
    bool? isDebuff,
    String? description,
    bool? hasEnergy,
    int? initialEnergy,
    int? energyPerTurnDelta,
    int? maxEnergy,
    int? minEnergy,
  }) {
    return StatusEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      shieldDelta: shieldDelta ?? this.shieldDelta,
      atkDelta: atkDelta ?? this.atkDelta,
      rangeDelta: rangeDelta ?? this.rangeDelta,
      moveDelta: moveDelta ?? this.moveDelta,
      hpPerTurnDelta: hpPerTurnDelta ?? this.hpPerTurnDelta,
      turnsRemaining: turnsRemaining ?? this.turnsRemaining,
      isPermanent: isPermanent ?? this.isPermanent,
      isDebuff: isDebuff ?? this.isDebuff,
      description: description ?? this.description,
      hasEnergy: hasEnergy ?? this.hasEnergy,
      initialEnergy: initialEnergy ?? this.initialEnergy,
      energyPerTurnDelta: energyPerTurnDelta ?? this.energyPerTurnDelta,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      minEnergy: minEnergy ?? this.minEnergy,
    );
  }

  /// 取得對應的 IconData
  IconData get iconData {
    switch (iconCode) {
      case 'sword':
        return Icons.sports_kabaddi;
      case 'shield':
        return Icons.shield;
      case 'skull':
        return Icons.coronavirus;
      case 'poison':
        return Icons.science;
      case 'fire':
        return Icons.local_fire_department;
      case 'speed':
        return Icons.speed;
      case 'heal':
        return Icons.favorite;
      case 'blind':
        return Icons.visibility_off;
      case 'freeze':
        return Icons.ac_unit;
      case 'star':
        return Icons.star;
      default:
        return isDebuff ? Icons.arrow_downward : Icons.arrow_upward;
    }
  }

  /// 顏色區分
  Color get color {
    if (isDebuff) {
      return Colors.redAccent;
    }
    return Colors.amberAccent;
  }

  /// 效果效果字串摘要
  String get effectSummary {
    final List<String> parts = [];
    if (shieldDelta != 0) parts.add('Shield ${shieldDelta > 0 ? "+$shieldDelta" : "$shieldDelta"}');
    if (atkDelta != 0) parts.add('ATK ${atkDelta > 0 ? "+$atkDelta" : "$atkDelta"}');
    if (rangeDelta != 0) parts.add('Range ${rangeDelta > 0 ? "+$rangeDelta" : "$rangeDelta"}');
    if (moveDelta != 0) parts.add('Move ${moveDelta > 0 ? "+$moveDelta" : "$moveDelta"}');
    if (hpPerTurnDelta != 0) {
      parts.add('HP/回合 ${hpPerTurnDelta > 0 ? "+$hpPerTurnDelta" : "$hpPerTurnDelta"}');
    }
    if (parts.isEmpty) return '無數值變化';
    return parts.join(', ');
  }
}
