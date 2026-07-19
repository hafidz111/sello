import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/features/cashier/cashier_centered_message.dart';
import 'package:sello/widgets/features/cashier/cashier_customer_field.dart';
import 'package:sello/widgets/features/cashier/cashier_sale_item_card.dart';

class CashierResultArea extends StatelessWidget {
  const CashierResultArea({
    super.key,
    required this.isLoading,
    required this.isSaving,
    required this.items,
    required this.grandTotal,
    required this.horizontalPadding,
    required this.customerController,
    required this.onClear,
    required this.onSave,
  });

  final bool isLoading;
  final bool isSaving;
  final List<SaleItem> items;
  final int grandTotal;
  final double horizontalPadding;
  final TextEditingController customerController;
  final VoidCallback onClear;
  final VoidCallback onSave;

  bool get _isEmpty => items.isEmpty && !isLoading;

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) {
      return const CashierCenteredMessage(
        icon: Icons.receipt_long_rounded,
        color: AppColors.textHint,
        title: 'Belum ada catatan',
        message:
            'Ketuk mikrofon untuk mencatat penjualan lewat suara singkat, '
            'atau pindah ke mode Scan untuk kenali produk dari kamera.',
      );
    }

    final matchedCount = items.where((item) => item.matchedFromCatalog).length;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              8,
            ),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$matchedCount/${items.length} item cocok katalog',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isSaving ? null : onClear,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset'),
                    ),
                  ],
                );
              }
              return CashierSaleItemCard(item: items[index - 1]);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
          child: CashierCustomerField(
            controller: customerController,
            enabled: !isSaving && !isLoading,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            Responsive.bottomScrollPadding(context) > 90
                ? 12
                : 12,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    Text(
                      formatRupiah(grandTotal),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSaving || isLoading || matchedCount == 0
                      ? null
                      : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    isSaving ? 'Menyimpan...' : 'Simpan penjualan',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
