import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_unit.dart';
import '../providers/battle_provider.dart';
import 'dialogs/character_select_dialog.dart';
import '../main.dart';

/// 應用程式主入口首頁 (Main Page)
/// 展示 "Ash Bound" 震撼主標題，提示使用者隨意點擊螢幕開始遊戲
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onScreenTapped(BuildContext context) {
    final provider = context.read<BattleProvider>();
    final navigator = Navigator.of(context);

    // 彈出選擇 Player 1 和 Player 2 角色的彈窗
    CharacterSelectDialog.show(
      context: context,
      initialStartingPlayer: provider.activePlayerIndex,
      onConfirm: ({
        required CharacterUnit hero1,
        required CharacterUnit hero2,
        required int startingPlayerIndex,
      }) {
        // 設定角色與先攻
        provider.restartGame(
          startingPlayerIndex: startingPlayerIndex,
          hero1: hero1,
          hero2: hero2,
        );

        // 導向對戰主戰場
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const BattleFieldScreen(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onScreenTapped(context),
        child: Stack(
          children: [
            // 背景微光與六邊形網格裝飾氛圍
            Positioned.fill(
              child: CustomPaint(
                painter: _TitleBackgroundPainter(),
              ),
            ),

            // 主內容中央標題與呼吸燈提示
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 頂部副標題
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withAlpha(90)),
                    ),
                    child: const Text(
                      'BOARD GAME BATTLE SYSTEM',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 主標題: Ash Bound (帶發光漸變效果)
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD54F),
                        Color(0xFFFF8A65),
                        Color(0xFFFF5252),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Ash Bound',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    '戰 局 數 據 紀 錄 與 戰 鬥 決 策 終 端',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 點擊螢幕開始遊戲提示 (帶呼吸效果)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white30, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '點 擊 螢 幕 開 始 遊 戲',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 繪製未來科技風六邊形背景裝飾
class _TitleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (double r = 80; r <= 320; r += 70) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = -math.pi / 2 + (i * 2 * math.pi / 6);
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
