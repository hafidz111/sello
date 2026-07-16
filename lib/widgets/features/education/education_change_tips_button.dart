import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class EducationChangeTipsButton extends StatelessWidget {
  const EducationChangeTipsButton({
    super.key,
    required this.enabled,
    required this.isExhausted,
    required this.onPressed,
  });

  final bool enabled;
  final bool isExhausted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  )
                : null,
            color: enabled ? null : AppColors.surfaceVariant,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExhausted
                      ? Icons.lock_clock_rounded
                      : Icons.auto_awesome_rounded,
                  color: enabled ? AppColors.textOnPrimary : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExhausted ? 'Batas harian habis' : 'Ganti tips baru',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: enabled
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExhausted
                          ? 'Upgrade ke Pro atau coba lagi besok'
                          : 'Dapatkan insight lain untuk tokomu',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: enabled
                            ? AppColors.textOnPrimary.withValues(alpha: 0.9)
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: enabled
                    ? AppColors.textOnPrimary
                    : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
