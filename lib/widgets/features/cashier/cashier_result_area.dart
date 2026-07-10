import 'package:flutter/material.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/features/cashier/cashier_centered_message.dart';
import 'package:sello/widgets/features/cashier/cashier_sale_item_card.dart';
import 'package:sello/widgets/features/cashier/cashier_total_bar.dart';

class CashierResultArea extends StatelessWidget {
  const CashierResultArea({
    super.key,
    required this.isLoading,
    required this.items,
    required this.grandTotal,
    required this.horizontalPadding,
    required this.onClear,
  });

  final bool isLoading;
  final List<SaleItem> items;
  final int grandTotal;
  final double horizontalPadding;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoading) {
      return const CashierCenteredMessage(
        icon: Icons.receipt_long_rounded,
        color: AppColors.textHint,
        title: 'Belum ada catatan',
        message:
            'Ketuk mikrofon untuk mencatat penjualan lewat suara, '
            'atau pindah ke mode Scan untuk kenali produk dari kamera.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              Responsive.bottomScrollPadding(context),
            ),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} item terdeteksi',
                      style: AppTextStyles.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: onClear,
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
        CashierTotalBar(grandTotal: grandTotal, padding: horizontalPadding),
      ],
    );
  }
}
