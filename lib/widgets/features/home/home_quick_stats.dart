import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/features/home/home_stat_card.dart';

class HomeQuickStats extends StatelessWidget {
  const HomeQuickStats({super.key, required this.padding});

  final double padding;

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final stats = context.watch<DashboardProvider>().stats;
    final salesLabel = formatRupiah(stats.todaySalesTotal);
    final txLabel = '${stats.todayTransactionCount}';

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 8),
      child: isTablet
          ? Row(
              children: [
                HomeStatCard(
                  label: 'Penjualan Hari Ini',
                  value: salesLabel,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                HomeStatCard(
                  label: 'Transaksi',
                  value: txLabel,
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                HomeStatCard(
                  label: 'Produk Aktif',
                  value: '${stats.activeProductCount}',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                HomeStatCard(
                  label: 'Stok Menipis',
                  value: '${stats.lowStockCount}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
              ],
            )
          : Row(
              children: [
                HomeStatCard(
                  label: 'Penjualan Hari Ini',
                  value: salesLabel,
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                HomeStatCard(
                  label: 'Transaksi',
                  value: txLabel,
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
    );
  }
}
