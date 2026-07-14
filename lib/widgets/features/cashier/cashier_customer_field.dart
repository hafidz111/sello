import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierCustomerField extends StatelessWidget {
  const CashierCustomerField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onDarkBackground = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final fill = onDarkBackground
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.surface;
    final textColor =
        onDarkBackground ? AppColors.textOnPrimary : AppColors.textPrimary;
    final hintColor =
        onDarkBackground ? Colors.white70 : AppColors.textHint;

    return TextField(
      controller: controller,
      enabled: enabled,
      style: AppTextStyles.bodyMedium.copyWith(color: textColor),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Nama pelanggan (opsional)',
        hintText: 'Contoh: Bu Siti',
        labelStyle: AppTextStyles.bodySmall.copyWith(color: hintColor),
        hintStyle: AppTextStyles.bodySmall.copyWith(color: hintColor),
        prefixIcon: Icon(Icons.person_outline_rounded, color: hintColor),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: onDarkBackground
                ? Colors.white24
                : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: onDarkBackground
                ? Colors.white24
                : AppColors.border,
          ),
        ),
      ),
    );
  }
}
