import 'package:flutter/material.dart';
import 'package:sello/models/export_language.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class TranslateLanguageTabs extends StatelessWidget {
  const TranslateLanguageTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ExportLanguage selected;
  final ValueChanged<ExportLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final language in ExportLanguage.values) ...[
            if (language != ExportLanguage.values.first) const SizedBox(width: 8),
            ChoiceChip(
              label: Text('${language.shortLabel} · ${language.label}'),
              selected: language == selected,
              onSelected: (_) => onSelected(language),
              selectedColor: const Color(0xFF06B6D4),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: language == selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: language == selected
                    ? const Color(0xFF06B6D4)
                    : AppColors.border,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
