import 'package:flutter/material.dart';
import 'package:sello/models/product_match_result.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ScanMatchCard extends StatelessWidget {
  const ScanMatchCard({
    super.key,
    required this.match,
    required this.isClaimed,
  });

  final ProductMatchResult match;
  final bool isClaimed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isClaimed ? AppColors.primaryContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isClaimed ? Icons.check_circle_rounded : Icons.help_outline_rounded,
            color: isClaimed ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.productName, style: AppTextStyles.titleMedium),
                Text(
                  isClaimed
                      ? 'Cocok dengan katalog (${match.confidencePercent}%)'
                      : 'Belum cocok dengan katalog (${match.confidencePercent}%)',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
