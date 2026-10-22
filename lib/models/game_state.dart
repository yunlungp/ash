import 'character_unit.dart';
import 'game_log.dart';

/// 完整遊戲狀態快照（用於狀態驅動與 Undo 復原機制）
class GameState {
  int roundNumber;
  int activePlayerIndex; // 0 為 Player 1 (左方), 1 為 Player 2 (右方)
  CharacterUnit player1;
  CharacterUnit player2;
  List<CharacterUnit?> player1Minions; // 預設 3 個槽位
  List<CharacterUnit?> player2Minions; // 預設 3 個槽位
  bool player1PassiveEnabled; // P1 小兵數量連動被動開關 (預設開)
  bool player2PassiveEnabled; // P2 小兵數量連動被動開關 (預設開)
  List<GameLog> logs;
  bool isGameOver;
  int? winnerIndex; // 0, 1 或 null
  String? gameOverReason;

  GameState({
    this.roundNumber = 1,
    this.activePlayerIndex = 0,
    required this.player1,
    required this.player2,
    required this.player1Minions,
    required this.player2Minions,
    this.player1PassiveEnabled = true,
    this.player2PassiveEnabled = true,
    List<GameLog>? logs,
    this.isGameOver = false,
    this.winnerIndex,
    this.gameOverReason,
  }) : logs = logs ?? [];

  /// 建立初始遊戲狀態，可指定先攻方與雙方英雄
  factory GameState.initial({
    int startingPlayerIndex = 0,
    CharacterUnit? hero1,
    CharacterUnit? hero2,
  }) {
    final player1Hero = hero1 ??
        CharacterUnit.createHero(id: 'p1_hero', name: '玩家 1', ownerIndex: 0);
    final player2Hero = hero2 ??
        CharacterUnit.createHero(id: 'p2_hero', name: '玩家 2', ownerIndex: 1);
    final startName = startingPlayerIndex == 0 ? player1Hero.name : player2Hero.name;

    return GameState(
      roundNumber: 1,
      activePlayerIndex: startingPlayerIndex,
      player1: player1Hero,
      player2: player2Hero,
      player1Minions: [null, null, null],
      player2Minions: [null, null, null],
      logs: [
        GameLog(
          id: 'init_log',
          timestamp: DateTime.now(),
          round: 1,
          playerIndex: startingPlayerIndex,
          actorName: '系統',
          actionTitle: '遊戲開始',
          detail: '雙方英雄就緒，第 1 回合開始（由 $startName 先攻）',
          type: LogType.system,
        )
      ],
      isGameOver: false,
    );
  }

  /// 深度拷貝，用於 Undo 快照機制
  GameState deepCopy() {
    return GameState(
      roundNumber: roundNumber,
      activePlayerIndex: activePlayerIndex,
      player1: player1.deepCopy(),
      player2: player2.deepCopy(),
      player1Minions: player1Minions.map((m) => m?.deepCopy()).toList(),
      player2Minions: player2Minions.map((m) => m?.deepCopy()).toList(),
      player1PassiveEnabled: player1PassiveEnabled,
      player2PassiveEnabled: player2PassiveEnabled,
      logs: logs.map((l) => l.copyWith()).toList(),
      isGameOver: isGameOver,
      winnerIndex: winnerIndex,
      gameOverReason: gameOverReason,
    );
  }

  /// 取得當前存活小兵數量
  int getAliveMinionsCount(int playerIndex) {
    final list = playerIndex == 0 ? player1Minions : player2Minions;
    return list.where((m) => m != null).length;
  }
}
