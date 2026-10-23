import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 根據螢幕尺寸（手機 vs 平板/大螢幕）自動計算縮放因數，讓全 App 尺寸自適應
class UiScale {
  final double scale;
  final bool isTablet;

  UiScale._({required this.scale, required this.isTablet});

  factory UiScale.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // 手機橫屏基準約 800x360 ~ 840x390
    // 平板橫屏基準約 1024x768 ~ 1280x800 或更大
    // 依據螢幕高度與寬度綜合計算 scale，確保不破版且適當放大
    final bool isTablet = width >= 900 || height >= 500;
    
    // 限制縮放比例在 1.0 (標準手機) 到 1.45 (大平板) 之間
    final double rawScale = isTablet ? math.min(1.45, math.max(1.15, height / 400.0)) : 1.0;

    return UiScale._(scale: rawScale, isTablet: isTablet);
  }

  /// 依比例放大數值
  double sp(double val) => (val * scale).roundToDouble();

  /// 依比例放大邊距/尺寸
  double dp(double val) => val * scale;
}
