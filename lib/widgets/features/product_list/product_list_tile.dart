import 'package:flutter/material.dart';
import 'package:sello/core/constants/stock_constants.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/product.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/features/product_list/product_thumb_placeholder.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    this.onTap,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail =
        product.images.isNotEmpty ? product.images.first.publicUrl : null;
    final isLowStock = product.stock <= StockConstants.lowStockThreshold;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbnail != null
                    ? Image.network(
                        thumbnail,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ProductThumbPlaceholder(),
                      )
                    : const ProductThumbPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${formatRupiah(product.price)} · Stok ${product.stock} pcs',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (product.hasBarcode)
                      Text(
                        product.allBarcodeValues.length > 1
                            ? 'Barcode ${product.allBarcodeValues.join(' / ')}'
                            : 'Barcode ${product.allBarcodeValues.first}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (isLowStock)
                      Text(
                        'Stok menipis',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
