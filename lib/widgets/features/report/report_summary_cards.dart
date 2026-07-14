import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/business_report.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ReportSummaryCards extends StatelessWidget {
  const ReportSummaryCards({super.key, required this.report});

  final BusinessReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _SummaryTile(
              label: 'Penjualan',
              value: formatRupiah(report.totalRevenue),
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _SummaryTile(
              label: 'Laba',
              value: formatRupiah(report.totalProfit),
              icon: Icons.trending_up_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryTile(
              label: 'Transaksi',
              value: '${report.transactionCount}',
              icon: Icons.receipt_long_rounded,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),
            _SummaryTile(
              label: 'Item',
              value: '${report.unitsSold}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
