import 'package:flutter/material.dart';

enum LogType {
  statChange,
  buffAdd,
  buffRemove,
  buffTick,
  minionSummon,
  minionDismiss,
  minionTransfer,
  diceRoll,
  turnChange,
  undo,
  gameOver,
  system,
}

class GameLog {
  final String id;
  final DateTime timestamp;
  final int round;
  final int playerIndex; // 0: P1, 1: P2, -1: 系統
  final String actorName; // 例如 "玩家 1", "玩家 2 小兵 #1"
  final String actionTitle; // 例如 "生命值調整", "回合切換"
  final String detail; // 詳細訊息，例如 "HP 100 -> 95 (-5)"
  final LogType type;

  const GameLog({
    required this.id,
    required this.timestamp,
    required this.round,
    required this.playerIndex,
    required this.actorName,
    required this.actionTitle,
    required this.detail,
    required this.type,
  });

  Color get color {
    switch (type) {
      case LogType.statChange:
        return Colors.lightBlueAccent;
      case LogType.buffAdd:
        return Colors.amberAccent;
      case LogType.buffRemove:
        return Colors.orangeAccent;
      case LogType.buffTick:
        return Colors.purpleAccent;
      case LogType.minionSummon:
        return Colors.greenAccent;
      case LogType.minionDismiss:
        return Colors.deepOrangeAccent;
      case LogType.minionTransfer:
        return Colors.tealAccent;
      case LogType.diceRoll:
        return Colors.yellowAccent;
      case LogType.turnChange:
        return Colors.cyanAccent;
      case LogType.undo:
        return Colors.pinkAccent;
      case LogType.gameOver:
        return Colors.redAccent;
      case LogType.system:
        return Colors.white70;
    }
  }

  IconData get icon {
    switch (type) {
      case LogType.statChange:
        return Icons.calculate;
      case LogType.buffAdd:
        return Icons.add_circle_outline;
      case LogType.buffRemove:
        return Icons.remove_circle_outline;
      case LogType.buffTick:
        return Icons.timelapse;
      case LogType.minionSummon:
        return Icons.group_add;
      case LogType.minionDismiss:
        return Icons.person_remove;
      case LogType.minionTransfer:
        return Icons.swap_horiz;
      case LogType.diceRoll:
        return Icons.casino;
      case LogType.turnChange:
        return Icons.sync_alt;
      case LogType.undo:
        return Icons.undo;
      case LogType.gameOver:
        return Icons.emoji_events;
      case LogType.system:
        return Icons.info_outline;
    }
  }

  GameLog copyWith() {
    return GameLog(
      id: id,
      timestamp: timestamp,
      round: round,
      playerIndex: playerIndex,
      actorName: actorName,
      actionTitle: actionTitle,
      detail: detail,
      type: type,
    );
  }
}
