import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sello/styles/app_colors.dart';

/// Field angka: jika isi `0`, fokus langsung menimpa (select all saat fokus).
class OverwriteZeroNumberField extends StatefulWidget {
  const OverwriteZeroNumberField({
    super.key,
    required this.controller,
    required this.decoration,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<OverwriteZeroNumberField> createState() =>
      _OverwriteZeroNumberFieldState();
}

class _OverwriteZeroNumberFieldState extends State<OverwriteZeroNumberField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) return;
    final text = widget.controller.text.trim();
    if (text == '0' || text.isEmpty) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  void _selectAllIfZero() {
    final text = widget.controller.text.trim();
    if (text == '0' || text.isEmpty) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onTap: _selectAllIfZero,
      onChanged: widget.onChanged,
      decoration: widget.decoration,
      cursorColor: AppColors.primary,
    );
  }
}
