import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sello/models/export_language.dart';
import 'package:sello/models/product_translation_bundle.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';

class TranslateResultCard extends StatelessWidget {
  const TranslateResultCard({
    super.key,
    required this.language,
    required this.copy,
  });

  final ExportLanguage language;
  final LocalizedProductCopy copy;

  Future<void> _copyAll(BuildContext context) async {
    final text = [
      copy.title,
      '',
      copy.description,
      if (copy.tags.isNotEmpty) '',
      if (copy.tags.isNotEmpty) copy.tags.join(', '),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      AppSnackbar.success(context, 'Teks ${language.label} disalin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  language.label,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: const Color(0xFF06B6D4),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyAll(context),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Salin'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection:
                language.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Judul', style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(copy.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Text('Deskripsi', style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(copy.description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          if (copy.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Tag', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in copy.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(tag, style: AppTextStyles.bodySmall),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
