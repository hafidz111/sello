import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierInputCard extends StatelessWidget {
  const CashierInputCard({
    super.key,
    required this.controller,
    required this.examples,
    required this.isLoading,
    required this.onSubmit,
    required this.onExampleTap,
  });

  final TextEditingController controller;
  final List<String> examples;
  final bool isLoading;
  final VoidCallback onSubmit;
  final ValueChanged<String> onExampleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Contoh: jual 5 keripik singkong 10 ribu...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: examples.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final text = examples[index];
                return ActionChip(
                  label: Text(text, style: AppTextStyles.bodySmall),
                  backgroundColor: AppColors.primaryContainer,
                  side: BorderSide.none,
                  onPressed: isLoading ? null : () => onExampleTap(text),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              isLoading ? 'Memproses...' : 'Catat dengan AI',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
