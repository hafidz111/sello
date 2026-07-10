import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/product.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ScanClaimedProductCard extends StatelessWidget {
  const ScanClaimedProductCard({
    super.key,
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final subtotal = product.price * quantity;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${formatRupiah(product.price)} / pcs · Stok ${product.stock}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Subtotal: ${formatRupiah(subtotal)}',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
