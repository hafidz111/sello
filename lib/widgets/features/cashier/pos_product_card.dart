import 'package:flutter/material.dart';
import 'package:sello/core/constants/stock_constants.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/product.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/features/product_list/product_thumb_placeholder.dart';

class PosProductCard extends StatelessWidget {
  const PosProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail =
        product.images.isNotEmpty ? product.images.first.publicUrl : null;
    final outOfStock = product.stock <= 0;
    final isLowStock =
        !outOfStock && product.stock <= StockConstants.lowStockThreshold;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      thumbnail != null
                          ? Image.network(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const ColoredBox(
                                color: AppColors.surfaceVariant,
                                child: Center(
                                  child: ProductThumbPlaceholder(),
                                ),
                              ),
                            )
                          : const ColoredBox(
                              color: AppColors.surfaceVariant,
                              child: Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 36,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                      if (outOfStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Text(
                            'Habis',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(product.price),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      outOfStock
                          ? 'Stok 0'
                          : isLowStock
                          ? 'Stok ${product.stock} · menipis'
                          : 'Stok ${product.stock}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: outOfStock || isLowStock
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
