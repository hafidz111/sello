import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class TranslateExportActions extends StatelessWidget {
  const TranslateExportActions({
    super.key,
    required this.enabled,
    required this.isExporting,
    required this.onExportJson,
    required this.onExportText,
  });

  final bool enabled;
  final bool isExporting;
  final VoidCallback onExportJson;
  final VoidCallback onExportText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled && !isExporting ? onExportJson : null,
            icon: const Icon(Icons.data_object_rounded),
            label: const Text('Ekspor JSON'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF06B6D4),
              side: const BorderSide(color: Color(0xFF06B6D4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled && !isExporting ? onExportText : null,
            icon: isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.share_rounded),
            label: Text(
              isExporting ? 'Menyiapkan...' : 'Ekspor teks',
              style: AppTextStyles.labelLarge,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
