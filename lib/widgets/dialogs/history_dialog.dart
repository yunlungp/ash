import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/game_log.dart';

class HistoryDialog extends StatefulWidget {
  final List<GameLog> logs;

  const HistoryDialog({
    super.key,
    required this.logs,
  });

  static Future<void> show({
    required BuildContext context,
    required List<GameLog> logs,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => HistoryDialog(logs: logs),
    );
  }

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  LogType? _filterType;

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filterType == null
        ? widget.logs
        : widget.logs.where((l) => l.type == _filterType).toList();
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: math.min(340.0, screenHeight * 0.94),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題列
              Row(
                children: [
                  const Icon(Icons.history_edu, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '對戰歷史操作紀錄 (${widget.logs.length} 筆)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(color: Color(0xFF334055), height: 12),

              // 分類過濾 Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('全部 (${widget.logs.length})', null),
                    _filterChip('數值調整', LogType.statChange),
                    _filterChip('效果增減', LogType.buffAdd),
                    _filterChip('小兵異動', LogType.minionSummon),
                    _filterChip('陣營轉移', LogType.minionTransfer),
                    _filterChip('甩骰子', LogType.diceRoll),
                    _filterChip('回合切換', LogType.turnChange),
                    _filterChip('復原動作', LogType.undo),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 紀錄列表
              Expanded(
                child: filteredLogs.isEmpty
                    ? const Center(
                        child: Text(
                          '尚無此分類的操作紀錄',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF141923),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2C384C)),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          itemCount: filteredLogs.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(color: Color(0xFF222B3B), height: 1),
                          itemBuilder: (ctx, i) {
                            final log = filteredLogs[i];
                            final timeStr =
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 時間與回合
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'R${log.round} $timeStr',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Icon 標記
                                  Icon(log.icon, size: 16, color: log.color),
                                  const SizedBox(width: 8),

                                  // 行動者與動作
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              log.actorName,
                                              style: TextStyle(
                                                color: log.playerIndex == 0
                                                    ? Colors.blueAccent
                                                    : log.playerIndex == 1
                                                        ? Colors.redAccent
                                                        : Colors.amberAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: log.color.withAlpha(30),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                log.actionTitle,
                                                style: TextStyle(
                                                  color: log.color,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          log.detail,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, LogType? type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selected: isSelected,
        selectedColor: Colors.cyanAccent,
        backgroundColor: const Color(0xFF141923),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? Colors.cyanAccent : const Color(0xFF334055),
          ),
        ),
        onSelected: (val) {
          setState(() {
            _filterType = isSelected ? null : type;
          });
        },
      ),
    );
  }
}
