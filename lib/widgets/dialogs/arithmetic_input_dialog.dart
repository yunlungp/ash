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
    _controller.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
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

  void _appendOrSet(String snippet) {
    if (snippet.startsWith('+') ||
        snippet.startsWith('-') ||
        snippet.startsWith('*') ||
        snippet.startsWith('/') ||
        snippet.startsWith('%')) {
      _controller.text = snippet;
    } else {
      _controller.text = snippet;
    }
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
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
    final subtitleText = widget.customSubtitle ??
        (widget.unit != null && widget.statType != null
            ? '目前基礎值: $_currentBaseValue (最終連動值: ${widget.unit!.getEffectiveStat(widget.statType!)})'
            : '目前數值: $_currentBaseValue');

    final screenHeight = MediaQuery.of(context).size.height;
    final dialogMaxHeight = math.min(330.0, screenHeight * 0.94);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: const Color(0xFF1E2430),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3B4860), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: dialogMaxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 標題與當前數值
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calculate, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitleText,
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(color: Color(0xFF334055), height: 14),

                // 輸入框
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        decoration: InputDecoration(
                          hintText: '輸入運算式 (如 +5, -10, *2, /2, %50)',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(70),
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF141923),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF455570)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.amber, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.edit, color: Colors.white54, size: 16),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                                  onPressed: () => _controller.clear(),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('確定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 快捷按鈕組
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _quickChip('-10', Colors.red.shade400),
                    _quickChip('-5', Colors.red.shade400),
                    _quickChip('-1', Colors.red.shade400),
                    _quickChip('+1', Colors.green.shade400),
                    _quickChip('+5', Colors.green.shade400),
                    _quickChip('+10', Colors.green.shade400),
                    _quickChip('*2', Colors.blue.shade300),
                    _quickChip('/2', Colors.purple.shade300),
                    _quickChip('%50', Colors.orange.shade300),
                  ],
                ),

                const SizedBox(height: 8),

                // 即時計算預覽
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131822),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _previewResult?.isValid == false
                          ? Colors.redAccent.withAlpha(100)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _previewResult?.isValid == true
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        size: 15,
                        color: _previewResult?.isValid == true
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _previewResult == null
                              ? '提示: 填入運算式後將自動依據當前數值計算'
                              : _previewResult!.isValid
                                  ? '計算預覽: ${_previewResult!.operationSummary}'
                                  : '格式錯誤: ${_previewResult!.errorMessage}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _previewResult == null
                                ? Colors.white54
                                : _previewResult!.isValid
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickChip(String label, Color color) {
    return InkWell(
      onTap: () => _appendOrSet(label),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(120), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
