import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

enum _SnackbarType { success, error, warning, info }

abstract final class AppSnackbar {
  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackbarType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackbarType.error);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _SnackbarType.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackbarType.info);

  static void _show(BuildContext context, String message, _SnackbarType type) {
    final (color, icon) = _styleOf(type);
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 4),
          content: _SnackbarBody(color: color, icon: icon, message: message),
        ),
      );
  }

  static (Color, IconData) _styleOf(_SnackbarType type) {
    switch (type) {
      case _SnackbarType.success:
        return (AppColors.success, Icons.check_circle_rounded);
      case _SnackbarType.error:
        return (AppColors.error, Icons.error_rounded);
      case _SnackbarType.warning:
        return (AppColors.warning, Icons.warning_amber_rounded);
      case _SnackbarType.info:
        return (AppColors.info, Icons.info_rounded);
    }
  }
}

class _SnackbarBody extends StatelessWidget {
  const _SnackbarBody({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
