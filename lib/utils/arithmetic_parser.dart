/// 算術解析結果
class ArithmeticParseResult {
  final bool isValid;
  final int newValue;
  final String? errorMessage;
  final String operationSummary;

  const ArithmeticParseResult({
    required this.isValid,
    required this.newValue,
    this.errorMessage,
    required this.operationSummary,
  });
}

class ArithmeticParser {
  /// 計算新數值
  ///
  /// 支援格式：
  /// - `+N` (加法，例如 +5)
  /// - `-N` (減法，例如 -10)
  /// - `*N` 或 `xN` (乘法，例如 *2)
  /// - `/N` (除法，例如 /2，整數除法，避免除以0)
  /// - `A+B`, `A-B`, `A*B`, `A/B` (原本數值運算式，例如 80-10, 80+5, 10*2)
  /// - `%N` (百分比計算，例如 %50 表示原值的 50%)
  /// - `+N%` (加百分比，例如 +20%)
  /// - `-N%` (減百分比，例如 -20%)
  /// - `N` (純數字，直接覆寫為新數值)
  static ArithmeticParseResult parseAndCompute({
    required int currentValue,
    required String input,
    bool allowNegative = false,
  }) {
    final raw = input.trim().replaceAll(' ', '');
    if (raw.isEmpty) {
      return ArithmeticParseResult(
        isValid: false,
        newValue: currentValue,
        errorMessage: '請輸入運算式或數值',
        operationSummary: '$currentValue (無變動)',
      );
    }

    try {
      // 0. 支援一般二元算式（當輸入框帶有原本數值時，如 80+10, 80-20, 80*2, 80/2）
      final binaryMatch = RegExp(r'^(\d+)([\+\-\*xX\/])(\d+)$').firstMatch(raw);
      if (binaryMatch != null) {
        final a = int.parse(binaryMatch.group(1)!);
        final op = binaryMatch.group(2)!;
        final b = int.parse(binaryMatch.group(3)!);
        int res;
        String opSymbol;

        if (op == '+') {
          res = a + b;
          opSymbol = '+';
        } else if (op == '-') {
          res = a - b;
          opSymbol = '-';
        } else if (op == '*' || op == 'x' || op == 'X') {
          res = a * b;
          opSymbol = '×';
        } else if (op == '/') {
          if (b == 0) return _error(currentValue, '除數不能為 0');
          res = (a / b).round();
          opSymbol = '÷';
        } else {
          res = a;
          opSymbol = '?';
        }

        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$a $opSymbol $b = $finalVal',
        );
      }
      // 1. 加百分比模式: +20%
      if (raw.startsWith('+') && raw.endsWith('%')) {
        final pctStr = raw.substring(1, raw.length - 1);
        final pct = double.tryParse(pctStr);
        if (pct == null) {
          return _error(currentValue, '無效的百分比數字');
        }
        final delta = (currentValue * (pct / 100.0)).round();
        final res = currentValue + delta;
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue + $delta (+$pct%) = $finalVal',
        );
      }

      // 2. 減百分比模式: -20%
      if (raw.startsWith('-') && raw.endsWith('%')) {
        final pctStr = raw.substring(1, raw.length - 1);
        final pct = double.tryParse(pctStr);
        if (pct == null) {
          return _error(currentValue, '無效的百分比數字');
        }
        final delta = (currentValue * (pct / 100.0)).round();
        final res = currentValue - delta;
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue - $delta (-$pct%) = $finalVal',
        );
      }

      // 3. 純百分比模式: %50 或 50% (代表當前數值的 50%)
      if (raw.startsWith('%') || raw.endsWith('%')) {
        final pctStr = raw.replaceAll('%', '');
        final pct = double.tryParse(pctStr);
        if (pct == null) {
          return _error(currentValue, '無效的百分比格式');
        }
        final res = (currentValue * (pct / 100.0)).round();
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue × $pct% = $finalVal',
        );
      }

      // 4. 乘法: *2, x2, X2
      if (raw.startsWith('*') || raw.startsWith('x') || raw.startsWith('X')) {
        final multiplierStr = raw.substring(1);
        final multiplier = double.tryParse(multiplierStr);
        if (multiplier == null) {
          return _error(currentValue, '無效的乘數');
        }
        final res = (currentValue * multiplier).round();
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue × $multiplierStr = $finalVal',
        );
      }

      // 5. 除法: /2
      if (raw.startsWith('/')) {
        final divisorStr = raw.substring(1);
        final divisor = double.tryParse(divisorStr);
        if (divisor == null) {
          return _error(currentValue, '無效的除數');
        }
        if (divisor == 0) {
          return _error(currentValue, '除數不能為 0');
        }
        final res = (currentValue / divisor).round();
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue ÷ $divisorStr = $finalVal',
        );
      }

      // 6. 加法: +5
      if (raw.startsWith('+')) {
        final numStr = raw.substring(1);
        final delta = int.tryParse(numStr);
        if (delta == null) {
          return _error(currentValue, '無效的加數');
        }
        final res = currentValue + delta;
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue + $delta = $finalVal',
        );
      }

      // 7. 減法: -10
      if (raw.startsWith('-')) {
        final numStr = raw.substring(1);
        final delta = int.tryParse(numStr);
        if (delta == null) {
          return _error(currentValue, '無效的減數');
        }
        final res = currentValue - delta;
        final finalVal = allowNegative ? res : (res < 0 ? 0 : res);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue - $delta = $finalVal',
        );
      }

      // 8. 純數字覆寫: 25
      final directVal = int.tryParse(raw);
      if (directVal != null) {
        final finalVal = allowNegative ? directVal : (directVal < 0 ? 0 : directVal);
        return ArithmeticParseResult(
          isValid: true,
          newValue: finalVal,
          operationSummary: '$currentValue → $finalVal (直接指定)',
        );
      }

      return _error(currentValue, '不支援的輸入格式。請使用如 +5, -10, *2, /2, %50 或純數字');
    } catch (e) {
      return _error(currentValue, '解析錯誤: $e');
    }
  }

  static ArithmeticParseResult _error(int current, String message) {
    return ArithmeticParseResult(
      isValid: false,
      newValue: current,
      errorMessage: message,
      operationSummary: '$current (無變動)',
    );
  }
}
