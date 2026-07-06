import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/constants/feature_data.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/feature_card.dart';
import 'package:sello/widgets/common/logout_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().userName ?? 'Pengguna';
    final padding = Responsive.horizontalPadding(context);
    final gridCount = Responsive.featureGridCount(context);
    final bottomPad = Responsive.bottomScrollPadding(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, userName, padding)),
        SliverToBoxAdapter(child: _buildQuickStats(context, padding)),
        SliverToBoxAdapter(
          child: _buildSectionTitle('Fitur Utama', padding),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: Responsive.featureGridAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final feature = FeatureData.all[index];
                return FeatureCard(
                  feature: feature,
                  compact: true,
                  onTap: () {},
                );
              },
              childCount: FeatureData.all.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildSectionTitle('Semua Fitur', padding),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, bottomPad),
          sliver: SliverList.separated(
            itemCount: FeatureData.all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return FeatureCard(
                feature: FeatureData.all[index],
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String userName, double padding) {
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName! 👋',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apa yang ingin Anda lakukan hari ini?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const LogoutButton(compact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, double padding) {
    final isTablet = Responsive.isTablet(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 8),
      child: isTablet
          ? Row(
              children: const [
                _StatCard(
                  label: 'Penjualan Hari Ini',
                  value: 'Rp 0',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                SizedBox(width: 12),
                _StatCard(
                  label: 'Transaksi',
                  value: '0',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12),
                _StatCard(
                  label: 'Produk Aktif',
                  value: '0',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.accent,
                ),
                SizedBox(width: 12),
                _StatCard(
                  label: 'Stok Menipis',
                  value: '0',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
              ],
            )
          : const Row(
              children: [
                _StatCard(
                  label: 'Penjualan Hari Ini',
                  value: 'Rp 0',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                SizedBox(width: 12),
                _StatCard(
                  label: 'Transaksi',
                  value: '0',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, double padding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 12),
      child: Text(title, style: AppTextStyles.titleLarge),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
