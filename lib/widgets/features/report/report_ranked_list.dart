import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ReportMetricRow {
  const ReportMetricRow({
    required this.title,
    required this.revenue,
    required this.profit,
    required this.transactionCount,
    required this.itemCount,
  });

  final String title;
  final int revenue;
  final int profit;
  final int transactionCount;
  final int itemCount;
}

class ReportRankedList extends StatelessWidget {
  const ReportRankedList({
    super.key,
    required this.title,
    required this.placeholderTitle,
    required this.items,
  });

  final String title;
  final String placeholderTitle;
  final List<ReportMetricRow> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.isEmpty
        ? [
            ReportMetricRow(
              title: placeholderTitle,
              revenue: 0,
              profit: 0,
              transactionCount: 0,
              itemCount: 0,
            ),
          ]
        : items;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          for (var i = 0; i < visibleItems.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _RankedItem(rank: i + 1, item: visibleItems[i]),
          ],
        ],
      ),
    );
  }
}

class _RankedItem extends StatelessWidget {
  const _RankedItem({required this.rank, required this.item});

  final int rank;
  final ReportMetricRow item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$rank',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(label: 'Penjualan', value: formatRupiah(item.revenue)),
            _MetricChip(label: 'Laba', value: formatRupiah(item.profit)),
            _MetricChip(label: 'Transaksi', value: '${item.transactionCount}'),
            _MetricChip(label: 'Item', value: '${item.itemCount}'),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
