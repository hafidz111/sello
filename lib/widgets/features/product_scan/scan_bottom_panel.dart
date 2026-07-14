import 'package:flutter/material.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_match_result.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/features/cashier/cashier_customer_field.dart';
import 'package:sello/widgets/features/product_scan/scan_claimed_product_card.dart';
import 'package:sello/widgets/features/product_scan/scan_match_card.dart';

class ScanBottomPanel extends StatelessWidget {
  const ScanBottomPanel({
    super.key,
    required this.isLoadingCatalog,
    required this.catalogCount,
    required this.lastMatch,
    required this.claimedProduct,
    required this.quantity,
    required this.isDetecting,
    required this.isRecording,
    required this.canDetect,
    required this.customerController,
    required this.onOpenRegister,
    required this.onDetect,
    required this.onRecordSale,
    required this.onResetScan,
    required this.onDecrementQuantity,
    required this.onIncrementQuantity,
  });

  final bool isLoadingCatalog;
  final int catalogCount;
  final ProductMatchResult? lastMatch;
  final Product? claimedProduct;
  final int quantity;
  final bool isDetecting;
  final bool isRecording;
  final bool canDetect;
  final TextEditingController customerController;
  final VoidCallback onOpenRegister;
  final VoidCallback onDetect;
  final VoidCallback onRecordSale;
  final VoidCallback onResetScan;
  final VoidCallback onDecrementQuantity;
  final VoidCallback onIncrementQuantity;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final claimed = claimedProduct;
    final match = lastMatch;
    final catalogIsEmpty = catalogCount == 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoadingCatalog)
            const Center(child: CircularProgressIndicator())
          else if (catalogIsEmpty) ...[
            Text(
              'Belum ada produk di katalog. Daftar produk dengan foto referensi dulu.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenRegister,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Daftar Produk'),
            ),
          ] else ...[
            Text(
              'Arahkan kamera ke produk, lalu ketuk deteksi.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (match != null && claimed == null) ...[
              ScanMatchCard(match: match, isClaimed: false),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onOpenRegister,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Daftar Produk Baru'),
              ),
              const SizedBox(height: 8),
            ],
            if (claimed != null) ...[
              ScanClaimedProductCard(product: claimed, quantity: quantity),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: quantity > 1 ? onDecrementQuantity : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$quantity pcs', style: AppTextStyles.titleLarge),
                  ),
                  IconButton.filled(
                    onPressed: onIncrementQuantity,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CashierCustomerField(
                controller: customerController,
                enabled: !isRecording,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isRecording ? null : onRecordSale,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isRecording
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  isRecording ? 'Menyimpan...' : 'Catat Penjualan',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              TextButton(onPressed: onResetScan, child: const Text('Scan ulang')),
            ] else ...[
              FilledButton.icon(
                onPressed: isDetecting || !canDetect ? null : onDetect,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                label: Text(
                  isDetecting ? 'Mendeteksi...' : 'Deteksi Produk',
                  style: AppTextStyles.labelLarge,
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
          Text(
            '$catalogCount produk di katalog. Arahkan kamera ke produk atau barcode.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
