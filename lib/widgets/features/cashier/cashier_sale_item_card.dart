import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/sale.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierSaleItemCard extends StatelessWidget {
  const CashierSaleItemCard({
    super.key,
    this.item,
    this.sale,
    this.isPending = false,
    this.onEdit,
    this.onDelete,
    this.onRemovePending,
  }) : assert(
         (item != null && sale == null) || (item == null && sale != null),
         'Provide either item or sale',
       );

  final SaleItem? item;
  final Sale? sale;
  final bool isPending;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRemovePending;

  String get _name => sale?.productName ?? item!.name;

  int get _quantity => sale?.quantity ?? item!.quantity;

  int get _unitPrice => sale?.unitPrice ?? item!.unitPrice;

  int get _subtotal => sale?.total ?? item!.subtotal;

  String? get _customerName => sale?.customerName;

  @override
  Widget build(BuildContext context) {
    final matched = item?.matchedFromCatalog ?? true;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPending
                  ? AppColors.warning.withValues(alpha: 0.12)
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_quantity}x',
              style: AppTextStyles.titleMedium.copyWith(
                color: isPending ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_name, style: AppTextStyles.titleMedium),
                    ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Draft',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@ ${formatRupiah(_unitPrice)}',
                  style: AppTextStyles.bodySmall,
                ),
                if (item != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    matched
                        ? 'Cocok katalog'
                        : 'Belum cocok katalog',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: matched ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ] else if (_customerName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pelanggan: $_customerName',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(_subtotal),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
              if (onEdit != null || onDelete != null || onRemovePending != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Ubah',
                      ),
                    if (onDelete != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        tooltip: 'Hapus',
                      ),
                    if (onRemovePending != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemovePending,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        tooltip: 'Buang draft',
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
