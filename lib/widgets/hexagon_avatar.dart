import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 繪製尖頭朝上/正立的六邊形路徑剪裁
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final radius = math.min(w, h) / 2;

    for (int i = 0; i < 6; i++) {
      // 尖頭朝上: -pi/2 起始
      final angle = -math.pi / 2 + (i * 2 * math.pi / 6);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 繪製六邊形外邊框
class HexagonBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  HexagonBorderPainter({
    required this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final radius = (math.min(w, h) - borderWidth) / 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 6);
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexagonBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

/// 依據圖片或自定義字元顯示的六邊形 Avatar 元件
class HexagonAvatar extends StatelessWidget {
  final String? imageAsset;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final Widget? fallbackChild;

  const HexagonAvatar({
    super.key,
    this.imageAsset,
    this.size = 40.0,
    this.borderColor = const Color(0xFF3B82F6),
    this.borderWidth = 2.0,
    this.fallbackChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 內部內容 (剪裁為六邊形)
          ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              width: size,
              height: size,
              color: const Color(0xFF161E2E),
              child: imageAsset != null
                  ? Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stackTrace) =>
                          fallbackChild ?? const Icon(Icons.shield, color: Colors.white70),
                    )
                  : fallbackChild ??
                      Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            color: borderColor,
                            fontSize: size * 0.45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
          ),
          // 外邊框
          Positioned.fill(
            child: CustomPaint(
              painter: HexagonBorderPainter(
                borderColor: borderColor,
                borderWidth: borderWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
