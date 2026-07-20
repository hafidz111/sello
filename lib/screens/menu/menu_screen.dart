import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/subscription_provider.dart';
import 'package:sello/screens/features/education_screen.dart';
import 'package:sello/screens/features/pricing_screen.dart';
import 'package:sello/screens/features/product_list_screen.dart';
import 'package:sello/screens/features/reference_barcode_import_screen.dart';
import 'package:sello/screens/features/translate_export_screen.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/common/logout_button.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _openProducts(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );
  }

  Future<void> _openEducation(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EducationScreen()),
    );
  }

  Future<void> _openTranslateExport(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TranslateExportScreen()),
    );
  }

  Future<void> _openReferenceImport(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReferenceBarcodeImportScreen(),
      ),
    );
  }

  Future<void> _openPricing(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PricingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final auth = context.watch<AuthProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final userName = auth.userName ?? 'Pengguna';
    final userEmail = auth.userEmail ?? '-';
    final bottomPad = Responsive.bottomScrollPadding(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 20, padding, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Kelola produk dan akun toko',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 12, padding, 0),
            child: _MenuSection(
              title: 'Toko & Produk',
              children: [
                _MenuTile(
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Produk',
                  subtitle:
                      'Katalog, tambah produk, stok, dan harga dalam satu tempat',
                  onTap: () => _openProducts(context),
                ),
                _MenuTile(
                  icon: Icons.qr_code_2_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Database Barcode Global',
                  subtitle:
                      'Impor Excel/CSV (A item, B barcode, C flag, D barcode kedua)',
                  onTap: () => _openReferenceImport(context),
                ),
                _MenuTile(
                  icon: Icons.translate_rounded,
                  color: const Color(0xFF06B6D4),
                  title: 'Terjemah & Ekspor',
                  subtitle: 'Deskripsi produk ID, EN, AR, ZH siap marketplace',
                  onTap: () => _openTranslateExport(context),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 20, padding, 0),
            child: _MenuSection(
              title: 'Akun',
              children: [
                _AccountCard(
                  userName: userName,
                  userEmail: userEmail,
                  planLabel: subscription.currentPlan.label,
                  isPro: subscription.isPro,
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Paket & Harga',
                  subtitle: 'Lihat paket Gratis dan Pro (uji coba)',
                  onTap: () => _openPricing(context),
                ),
                const SizedBox(height: 2),
                const LogoutButton(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 20, padding, bottomPad),
            child: _MenuSection(
              title: 'Lainnya',
              children: [
                _MenuTile(
                  icon: Icons.cloud_off_rounded,
                  color: const Color(0xFF64748B),
                  title: 'Mode Offline',
                  subtitle: 'Termasuk paket Gratis. Penyimpanan lokal segera hadir',
                  onTap: () => AppSnackbar.info(
                    context,
                    'Mode Offline dasar segera hadir di paket Gratis.',
                  ),
                ),
                _MenuTile(
                  icon: Icons.school_rounded,
                  color: const Color(0xFFEF4444),
                  title: 'Edukasi Mikro',
                  subtitle: 'Tips bisnis singkat dari data penjualan',
                  onTap: () => _openEducation(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.userName,
    required this.userEmail,
    required this.planLabel,
    required this.isPro,
  });

  final String userName;
  final String userEmail;
  final String planLabel;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(userEmail, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPro
                  ? AppColors.primaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              planLabel,
              style: AppTextStyles.labelMedium.copyWith(
                color: isPro ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
