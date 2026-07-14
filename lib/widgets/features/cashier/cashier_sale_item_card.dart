import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierSaleItemCard extends StatelessWidget {
  const CashierSaleItemCard({super.key, required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final matched = item.matchedFromCatalog;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matched ? AppColors.success.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.quantity}x',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '@ ${formatRupiah(item.unitPrice)}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  matched
                      ? 'Cocok katalog'
                      : 'Belum cocok katalog',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: matched ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupiah(item.subtotal),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
