import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/character_unit.dart';
import '../../utils/arithmetic_parser.dart';

class ArithmeticInputDialog extends StatefulWidget {
  final CharacterUnit? unit;
  final StatType? statType;
  final String? customTitle;
  final String? customSubtitle;
  final int? initialValue;
  final bool allowNegative;
  final Function(String expression)? onConfirm;
  final Function(int newValue)? onConfirmValue;

  const ArithmeticInputDialog({
    super.key,
    this.unit,
    this.statType,
    this.customTitle,
    this.customSubtitle,
    this.initialValue,
    this.allowNegative = false,
    this.onConfirm,
    this.onConfirmValue,
  });

  static Future<void> show({
    required BuildContext context,
    required CharacterUnit unit,
    required StatType statType,
    required Function(String expression) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ArithmeticInputDialog(
        unit: unit,
        statType: statType,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<void> showCustom({
    required BuildContext context,
    required String title,
    required int currentValue,
    String? subtitle,
    bool allowNegative = true,
    required Function(int newValue) onConfirmValue,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ArithmeticInputDialog(
        customTitle: title,
        customSubtitle: subtitle,
        initialValue: currentValue,
        allowNegative: allowNegative,
        onConfirmValue: onConfirmValue,
      ),
    );
  }

  @override
  State<ArithmeticInputDialog> createState() => _ArithmeticInputDialogState();
}

class _ArithmeticInputDialogState extends State<ArithmeticInputDialog> {
  final TextEditingController _controller = TextEditingController();
  late int _currentBaseValue;
  ArithmeticParseResult? _previewResult;

  @override
  void initState() {
    super.initState();
    _currentBaseValue = widget.initialValue ??
        (widget.unit != null && widget.statType != null
            ? widget.unit!.getBaseStat(widget.statType!)
            : 0);

    // 點擊後原本的數值預先填入輸入框，游標預設在文字最末端，方便直接點擊 +、-、*、/
    _controller.text = '$_currentBaseValue';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _controller.addListener(_updatePreview);
    _updatePreview();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _previewResult = null;
      });
      return;
    }

    final res = ArithmeticParser.parseAndCompute(
      currentValue: _currentBaseValue,
      input: text,
      allowNegative: widget.allowNegative,
    );
    setState(() {
      _previewResult = res;
    });
  }

  void _onKeypadTap(String val) {
    final curText = _controller.text;
    final sel = _controller.selection;
    final isOperator = val == '+' || val == '-' || val == '*' || val == '/';

    // 如果輸入的是運算符 (+, -, *, /)，且目前整段文字被全選（如剛打開對話框），
    // 我們不要覆蓋原本數值，而是取消全選並將運算符直接追加到原本數值後方
    if (isOperator && sel.isValid && sel.start == 0 && sel.end == curText.length && curText.isNotEmpty) {
      final newText = curText + val;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }

    if (sel.isValid && sel.start >= 0 && sel.end >= 0) {
      final newText = curText.replaceRange(sel.start, sel.end, val);
      final newOffset = sel.start + val.length;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    } else {
      _controller.value = TextEditingValue(
        text: curText + val,
        selection: TextSelection.collapsed(offset: curText.length + val.length),
      );
    }
  }

  void _onBackspace() {
    final curText = _controller.text;
    if (curText.isEmpty) return;

    final sel = _controller.selection;
    if (sel.isValid && sel.start >= 0 && sel.end > sel.start) {
      final newText = curText.replaceRange(sel.start, sel.end, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start),
      );
    } else {
      final offset = sel.isValid && sel.start > 0 ? sel.start : curText.length;
      if (offset > 0) {
        final newText = curText.substring(0, offset - 1) + curText.substring(offset);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: offset - 1),
        );
      }
    }
  }

  void _onClear() {
    _controller.clear();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final res = ArithmeticParser.parseAndCompute(
      currentValue: _currentBaseValue,
      input: text,
      allowNegative: widget.allowNegative,
    );

    if (res.isValid) {
      widget.onConfirm?.call(text);
      widget.onConfirmValue?.call(res.newValue);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.customTitle ??
        (widget.unit != null && widget.statType != null
            ? '${widget.unit!.name} • ${widget.statType!.displayName}'
            : '數值設定');

    final screenHeight = MediaQuery.of(context).size.height;
    final dialogMaxHeight = math.min(340.0, screenHeight * 0.94);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF161B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: dialogMaxHeight),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 頂部標題與關閉按鈕
              Row(
                children: [
                  const Icon(Icons.calculate, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titleText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '原值: $_currentBaseValue',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 輸入顯示框與計算預覽
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D111A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E3D52)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        readOnly: true, // 不彈出系統軟鍵盤，改用內置專業數字計算鍵盤
                        showCursor: true,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.white30),
                        ),
                      ),
                    ),
                    if (_previewResult != null)
                      Text(
                        _previewResult!.isValid
                            ? '➜ ${_previewResult!.newValue}'
                            : '格式錯誤',
                        style: TextStyle(
                          color: _previewResult!.isValid ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 內置實體數字與運算鍵盤 (4 行配置)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _keyBtn('7'),
                          _keyBtn('8'),
                          _keyBtn('9'),
                          _keyBtn('+', color: const Color(0xFF22354E), textColor: Colors.greenAccent),
                          _keyBtn('-', color: const Color(0xFF22354E), textColor: Colors.redAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        children: [
                          _keyBtn('4'),
                          _keyBtn('5'),
                          _keyBtn('6'),
                          _keyBtn('*', label: '×', color: const Color(0xFF22354E), textColor: Colors.cyanAccent),
                          _keyBtn('/', label: '÷', color: const Color(0xFF22354E), textColor: Colors.purpleAccent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        children: [
                          _keyBtn('1'),
                          _keyBtn('2'),
                          _keyBtn('3'),
                          _keyBtn('C', label: 'C', color: const Color(0xFF382329), textColor: Colors.orangeAccent, onTap: _onClear),
                          _keyBtn('DEL',
                              icon: Icons.backspace_outlined,
                              color: const Color(0xFF2D2638),
                              textColor: Colors.amberAccent,
                              onTap: _onBackspace),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        children: [
                          _keyBtn('0', flex: 2),
                          _keyBtn('00', flex: 1),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  '確定',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyBtn(
    String keyVal, {
    String? label,
    IconData? icon,
    Color? color,
    Color? textColor,
    VoidCallback? onTap,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: color ?? const Color(0xFF1E2534),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap ?? () => _onKeypadTap(keyVal),
            borderRadius: BorderRadius.circular(6),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: textColor ?? Colors.white, size: 17)
                  : Text(
                      label ?? keyVal,
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
