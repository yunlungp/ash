import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_unit.dart';
import '../providers/battle_provider.dart';
import '../utils/ui_scale.dart';
import 'dialogs/character_select_dialog.dart';
import 'dialogs/dice_dialog.dart';
import 'dialogs/history_dialog.dart';
import 'dialogs/game_over_dialog.dart';

class CenterControlPanel extends StatelessWidget {
  const CenterControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BattleProvider>();
    final activePlayerIndex = provider.activePlayerIndex;
    final isP1Active = activePlayerIndex == 0;
    final activeColor = isP1Active ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    final ui = UiScale.of(context);
    final panelWidth = ui.dp(106.0);

    return Container(
      width: panelWidth,
      padding: EdgeInsets.symmetric(horizontal: ui.dp(5), vertical: ui.dp(6)),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(ui.dp(12)),
        border: Border.all(color: const Color(0xFF263244), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. 上方：回合數與當前行動標籤
          Container(
            padding: EdgeInsets.symmetric(horizontal: ui.dp(8), vertical: ui.dp(3)),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(35),
              borderRadius: BorderRadius.circular(ui.dp(14)),
              border: Border.all(color: Colors.amber.withAlpha(120)),
            ),
            child: Text(
              'ROUND ${provider.roundNumber}',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: ui.sp(11),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(height: ui.dp(3)),
          // 當前行動方指示標籤
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: ui.dp(6), vertical: ui.dp(3)),
            decoration: BoxDecoration(
              color: activeColor.withAlpha(45),
              borderRadius: BorderRadius.circular(ui.dp(6)),
              border: Border.all(color: activeColor, width: 1.0),
            ),
            child: Text(
              isP1Active ? '◀ P1' : 'P2 ▶',
              style: TextStyle(
                color: activeColor,
                fontSize: ui.sp(10),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 2. 正中間：大按鈕「結束回合」
          Expanded(
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: Tooltip(
                  message: '結算當前效果倒數與毒素/再生/能量，並將行動權交給對手',
                  child: ElevatedButton(
                    onPressed: provider.isGameOver ? null : () => provider.nextTurn(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: ui.dp(4), vertical: ui.dp(8)),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ui.dp(10)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync_alt, size: ui.dp(22)),
                        SizedBox(height: ui.dp(3)),
                        Text(
                          '結束回合',
                          style: TextStyle(
                            fontSize: ui.sp(13),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. 最下方：骰子與其他控制按鈕（復原與紀錄只顯示 icon）
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 甩骰子按鈕
              SizedBox(
                width: double.infinity,
                height: ui.dp(34),
                child: ElevatedButton.icon(
                  onPressed: () {
                    DiceDialog.show(
                      context: context,
                      onRoll: (sides, result) {
                        provider.rollDice(
                          sides: sides,
                          rollerName: provider.activePlayerName,
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.casino, size: ui.dp(16), color: Colors.black),
                  label: Text(
                    '骰子',
                    style: TextStyle(
                      fontSize: ui.sp(11.5),
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent.shade700,
                    foregroundColor: Colors.black,
                    elevation: 2,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ui.dp(8))),
                  ),
                ),
              ),
              SizedBox(height: ui.dp(5)),

              // 復原 (Undo) 與 歷史紀錄 雙按鈕並列
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: ui.dp(32),
                      child: Tooltip(
                        message: '復原上一步 (可復原: ${provider.undoCount})',
                        child: OutlinedButton(
                          onPressed: provider.canUndo ? () => provider.undo() : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.pinkAccent,
                            disabledForegroundColor: Colors.white24,
                            side: BorderSide(
                              color: provider.canUndo
                                  ? Colors.pinkAccent.withAlpha(160)
                                  : Colors.white12,
                              width: 1.0,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ui.dp(6))),
                          ),
                          child: Icon(Icons.undo, size: ui.dp(17)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ui.dp(4)),
                  Expanded(
                    child: SizedBox(
                      height: ui.dp(32),
                      child: Tooltip(
                        message: '戰局歷史紀錄 (${provider.logs.length}筆)',
                        child: OutlinedButton(
                          onPressed: () {
                            HistoryDialog.show(
                              context: context,
                              logs: provider.logs,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.cyanAccent,
                            side: BorderSide(color: Colors.cyanAccent.withAlpha(160), width: 1.0),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ui.dp(6))),
                          ),
                          child: Icon(Icons.history, size: ui.dp(17)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ui.dp(5)),

              // 結束遊戲按鈕
              SizedBox(
                width: double.infinity,
                height: ui.dp(30),
                child: Tooltip(
                  message: '提前結束遊戲',
                  child: OutlinedButton(
                    onPressed: () => _confirmEndGame(context, provider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withAlpha(140), width: 1.0),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ui.dp(6))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: ui.dp(14)),
                        SizedBox(width: ui.dp(3)),
                        Text(
                          '結束',
                          style: TextStyle(fontSize: ui.sp(10.5), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmEndGame(BuildContext context, BattleProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2430),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('確定提前結束遊戲？', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '此操作將結束當前對戰局面。您可以重新開始新遊戲或檢視戰局歷史。',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('繼續遊戲', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.manualEndGame();
              GameOverDialog.show(
                context: context,
                winnerIndex: null,
                title: '遊戲已結束',
                reason: '玩家已手動結束對戰，所有狀態已清空鎖定。',
                onRestart: () {
                  CharacterSelectDialog.show(
                    context: context,
                    initialStartingPlayer: 0,
                    onConfirm: ({
                      required CharacterUnit hero1,
                      required CharacterUnit hero2,
                      required int startingPlayerIndex,
                    }) {
                      provider.restartGame(
                        startingPlayerIndex: startingPlayerIndex,
                        hero1: hero1,
                        hero2: hero2,
                      );
                    },
                  );
                },
              );
            },
            child: const Text('確定結束', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}