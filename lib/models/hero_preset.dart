import 'character_unit.dart';

class HeroPreset {
  final String id;
  final String name;
  final String? avatarAsset;
  final int hp;
  final int atk;
  final int range;
  final int move;
  final String description;

  const HeroPreset({
    required this.id,
    required this.name,
    this.avatarAsset,
    required this.hp,
    required this.atk,
    required this.range,
    required this.move,
    required this.description,
  });

  /// 建立對應的 CharacterUnit 實例
  CharacterUnit toCharacterUnit({required int ownerIndex, String? customDisplayName}) {
    final displayName = customDisplayName ?? name;
    final isTinna = id == 'tinna';

    return CharacterUnit.createHero(
      id: '${id}_${ownerIndex}_${DateTime.now().millisecondsSinceEpoch}',
      name: displayName,
      presetId: id,
      ownerIndex: ownerIndex,
      avatarAsset: avatarAsset,
      hp: hp,
      shield: 0,
      atk: atk,
      range: range,
      move: move,
      // Tinna 自動開啟能量值：從 0 開始，每回合 +1，上限 6，下限 0
      currentEnergy: isTinna ? 0 : null,
      energyPerTurnDelta: isTinna ? 1 : 0,
      minEnergy: 0,
      maxEnergy: isTinna ? 6 : 100,
    );
  }
}

/// 官方預設角色列表
class HeroPresets {
  static const HeroPreset eris = HeroPreset(
    id: 'eris',
    name: 'Eris',
    avatarAsset: 'photo/eris.png',
    hp: 100,
    atk: 20,
    range: 12,
    move: 5,
    description: '遠程致命狙擊手：生命 100，攻擊力 20，超遠射程 12，移動 5',
  );

  static const HeroPreset luna = HeroPreset(
    id: 'luna',
    name: 'Luna',
    avatarAsset: 'photo/luna.png',
    hp: 150,
    atk: 30,
    range: 3,
    move: 3,
    description: '近戰堅韌破壞者：生命 150，高額攻擊力 30，射程 3，移動 3',
  );

  static const HeroPreset tinna = HeroPreset(
    id: 'tinna',
    name: 'Tinna',
    avatarAsset: null,
    hp: 80,
    atk: 10,
    range: 5,
    move: 3,
    description: '戰術角色 Tinna：生命 80，攻擊力 10，射程 5，移動 3。自帶能量值（0~6，每回合+1）',
  );

  static const HeroPreset custom = HeroPreset(
    id: 'custom',
    name: '自訂角色',
    avatarAsset: null,
    hp: 100,
    atk: 15,
    range: 2,
    move: 3,
    description: '自定義配置：使用預設標準數值（生命 100，攻擊 15，射程 2，移動 3）',
  );

  static const List<HeroPreset> all = [eris, luna, tinna, custom];
}
