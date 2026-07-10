import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierTotalBar extends StatelessWidget {
  const CashierTotalBar({
    super.key,
    required this.grandTotal,
    required this.padding,
  });

  final int grandTotal;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(padding, 0, padding, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
    );
  }
}
