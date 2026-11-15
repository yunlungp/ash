import 'package:flutter/material.dart';
import 'character_unit.dart';

/// 技能效果形態
enum SkillType {
  passive, // 裝備/持有即常駐生效 (按持有張數加倍)
  active,  // 主動手動發動 (需點擊)
}

/// 技能目標類型
enum SkillTargetType {
  none,            // 無需指定目標 (如自身或全局宣告)
  self,            // 自身
  friendlyUnit,    // 我方任一單位 (英雄或小兵)
  friendlyMinion,  // 我方小兵
  anyUnit,         // 全場任一單位
  enemyUnit,       // 敵方任一單位
}

/// 單項技能效果定義
class SkillEffect {
  final String id;
  final String name;
  final String description;
  final SkillType type;
  final SkillTargetType targetType;
  final int maxUsesPerTurn; // 每回合可發動次數 (每張卡計算)
  final int hpCost;         // 消耗發動者 HP

  const SkillEffect({
    required this.id,
    required this.name,
    required this.description,
    this.type = SkillType.active,
    this.targetType = SkillTargetType.none,
    this.maxUsesPerTurn = 1,
    this.hpCost = 0,
  });
}

/// 技能卡定義 (包含角色固有技能卡與裝備技能卡)
class SkillCard {
  final String id;
  final String heroPresetId; // 綁定的角色 ID，如 'luna'
  final String name;
  final String subtitle;
  final bool isHeroInnate;   // 是否為英雄自身技能 (true 時不可調整張數，固定為 1)
  final int maxCopies;       // 最多持有幾張 (通常為 2)
  final List<SkillEffect> effects;

  const SkillCard({
    required this.id,
    required this.heroPresetId,
    required this.name,
    required this.subtitle,
    this.isHeroInnate = false,
    this.maxCopies = 2,
    required this.effects,
  });
}

/// 官方角色技能資料庫
class SkillCardDatabase {
  // --- Luna 固有技能 ---
  static const SkillCard lunaInnate = SkillCard(
    id: 'luna_innate',
    heroPresetId: 'luna',
    name: 'Luna 角色效果',
    subtitle: '固有能力',
    isHeroInnate: true,
    maxCopies: 1,
    effects: [
      SkillEffect(
        id: 'luna_innate_1',
        name: '攻擊強化',
        description: '1回合1次，回合開始時選擇場上一個單位，直到回合結束攻擊力 +5。',
        type: SkillType.active,
        targetType: SkillTargetType.anyUnit,
        maxUsesPerTurn: 1,
      ),
      SkillEffect(
        id: 'luna_innate_2',
        name: '位置交換',
        description: '扣除自身 10 HP，跟我方的一個單位交換位置。',
        type: SkillType.active,
        targetType: SkillTargetType.friendlyMinion,
        maxUsesPerTurn: 99,
        hpCost: 10,
      ),
    ],
  );

  // --- Luna 技能卡 1 ---
  static const SkillCard lunaCard1 = SkillCard(
    id: 'luna_card_1',
    heroPresetId: 'luna',
    name: '技能卡 1',
    subtitle: '狂暴突破',
    isHeroInnate: false,
    maxCopies: 2,
    effects: [
      SkillEffect(
        id: 'luna_c1_eff1',
        name: '攻速兼備 (被動)',
        description: '【被動】攻擊力 +20，移動力 +1。每回合結束時獲得 10 點護盾（持續至下回合開始）。持有 2 張效果翻倍。',
        type: SkillType.passive,
      ),
      SkillEffect(
        id: 'luna_c1_eff2',
        name: '瀕死替換',
        description: '【條件主動】生命值為 30 或以下時，可棄置此卡抵消一次傷害，並選擇場上一隻單位交換位置。',
        type: SkillType.active,
        targetType: SkillTargetType.anyUnit,
        maxUsesPerTurn: 1,
      ),
    ],
  );

  // --- Luna 技能卡 2 ---
  static const SkillCard lunaCard2 = SkillCard(
    id: 'luna_card_2',
    heroPresetId: 'luna',
    name: '技能卡 2',
    subtitle: '契約召喚',
    isHeroInnate: false,
    maxCopies: 2,
    effects: [
      SkillEffect(
        id: 'luna_c2_eff1',
        name: '契約檢索',
        description: '1回合1次，支付 20 生命，從卡組或墓地將一張有契約名的卡加入手牌。',
        type: SkillType.active,
        targetType: SkillTargetType.none,
        maxUsesPerTurn: 1,
        hpCost: 20,
      ),
      SkillEffect(
        id: 'luna_c2_eff2',
        name: '怪物獻祭 (回血30)',
        description: '獻祭自己場上的一隻小兵，回復生命 30 點。',
        type: SkillType.active,
        targetType: SkillTargetType.friendlyMinion,
        maxUsesPerTurn: 99,
      ),
    ],
  );

  // --- Eris 固有技能 ---
  static const SkillCard erisInnate = SkillCard(
    id: 'eris_innate',
    heroPresetId: 'eris',
    name: 'Eris 角色效果',
    subtitle: '固有能力',
    isHeroInnate: true,
    maxCopies: 1,
    effects: [
      SkillEffect(
        id: 'eris_innate_1',
        name: '放置印記',
        description: '1回合2次，在任意一個攻擊範圍內的格子放置印記（場上最多存在10個印記，被踩中時給予10傷害）。',
        type: SkillType.active,
        targetType: SkillTargetType.none,
        maxUsesPerTurn: 2,
      ),
      SkillEffect(
        id: 'eris_innate_trigger',
        name: '引爆印記傷害',
        description: '對方踩中印記時發動：選擇踩中目標與扣除印記數量，每印記造成 10 (+卡片加成) 點傷害。',
        type: SkillType.active,
        targetType: SkillTargetType.enemyUnit,
        maxUsesPerTurn: 99,
      ),
      SkillEffect(
        id: 'eris_innate_2',
        name: '替罪轉移',
        description: '1回合1次，被攻擊時發動：犧牲一隻 Monster 單位抵消傷害，並可將發動攻擊的敵方單位移動 4 格。',
        type: SkillType.active,
        targetType: SkillTargetType.friendlyMinion,
        maxUsesPerTurn: 1,
      ),
    ],
  );

  // --- Eris 技能卡 1 ---
  static const SkillCard erisCard1 = SkillCard(
    id: 'eris_card_1',
    heroPresetId: 'eris',
    name: '技能卡 1',
    subtitle: '印記擴充',
    isHeroInnate: false,
    maxCopies: 2,
    effects: [
      SkillEffect(
        id: 'eris_c1_eff1',
        name: '印記上限 +5 (被動)',
        description: '【被動】場上印記上限 +5（持有2張則 +10）。',
        type: SkillType.passive,
      ),
      SkillEffect(
        id: 'eris_c1_eff2',
        name: '印記傷害 +5 (被動)',
        description: '【被動】印記被踩中時，給予的傷害 +5（持有2張則 +10）。',
        type: SkillType.passive,
      ),
      SkillEffect(
        id: 'eris_c1_eff3',
        name: '印記穿梭',
        description: '1回合2次，可選擇釋放已佔領的佔領點或扣除 20 生命，傳送至任意印記格子。',
        type: SkillType.active,
        targetType: SkillTargetType.none,
        maxUsesPerTurn: 2,
      ),
    ],
  );

  // --- Eris 技能卡 2 ---
  static const SkillCard erisCard2 = SkillCard(
    id: 'eris_card_2',
    heroPresetId: 'eris',
    name: '技能卡 2',
    subtitle: '印記回收',
    isHeroInnate: false,
    maxCopies: 2,
    effects: [
      SkillEffect(
        id: 'eris_c2_eff1',
        name: '印記上限 +5 (被動)',
        description: '【被動】場上印記上限 +5（持有2張則 +10）。',
        type: SkillType.passive,
      ),
      SkillEffect(
        id: 'eris_c2_eff2',
        name: '回收印記',
        description: '回收場上印記發動效果：【4個】傳送至印記格子 / 【5個】回復20生命 / 【10個】自選任意佔領點佔領。',
        type: SkillType.active,
        targetType: SkillTargetType.none,
        maxUsesPerTurn: 99,
      ),
    ],
  );

  // --- Tinna 固有技能 ---
  static const SkillCard tinnaInnate = SkillCard(
    id: 'tinna_innate',
    heroPresetId: 'tinna',
    name: 'Tinna 角色效果',
    subtitle: '固有能力',
    isHeroInnate: true,
    maxCopies: 1,
    effects: [
      SkillEffect(
        id: 'tinna_innate_2',
        name: '能量/生命召喚',
        description: '1回合1次，可選擇消耗 2 個能量或 10 點生命值，召喚一隻 Lv.1 的小兵。',
        type: SkillType.active,
        targetType: SkillTargetType.none,
        maxUsesPerTurn: 1,
      ),
    ],
  );

  // --- Tinna 技能卡 1 ---
  static const SkillCard tinnaCard1 = SkillCard(
    id: 'tinna_card_1',
    heroPresetId: 'tinna',
    name: '技能卡 1',
    subtitle: '等級光環',
    isHeroInnate: false,
    maxCopies: 2,
    effects: [
      SkillEffect(
        id: 'tinna_c1_eff',
        name: '小兵等級連鎖 (被動)',
        description: '場上有對應等級小兵時獲得效果：【Lv.1】對方回合獲得+5護盾(對方回合結束即消退) / 【Lv.2】Tinna步數+1 / 【Lv.3】我方全體單位攻擊力+5。持有2張數值翻倍。',
        type: SkillType.passive,
      ),
    ],
  );

  // --- Tinna 技能卡 2 ---
  static const SkillCard tinnaCard2 = SkillCard(
    id: 'tinna_card_2',
    heroPresetId: 'tinna',
    name: '技能卡 2',
    subtitle: '捨身守護',
    isHeroInnate: false,
    maxCopies: 2,
    effects: [
      SkillEffect(
        id: 'tinna_c2_eff',
        name: '致命傷害抵消',
        description: '受到致命傷害時發動：抵消該次傷害（生命值不變），並可傳送至我方出生點或佔領點。發動後此卡破壞，或犧牲1隻Lv.3小兵代替破壞。',
        type: SkillType.active,
        targetType: SkillTargetType.none,
        maxUsesPerTurn: 99,
      ),
    ],
  );

  /// 取得指定角色的所有技能卡 (含固有卡與專屬技能卡)
  static List<SkillCard> getCardsForHero(String heroPresetId) {
    if (heroPresetId == 'luna') {
      return [lunaInnate, lunaCard1, lunaCard2];
    }
    if (heroPresetId == 'eris') {
      return [erisInnate, erisCard1, erisCard2];
    }
    if (heroPresetId == 'tinna') {
      return [tinnaInnate, tinnaCard1, tinnaCard2];
    }
    return [];
  }
}
