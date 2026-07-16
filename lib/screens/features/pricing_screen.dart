import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/subscription_plan.dart';
import 'package:sello/providers/subscription_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/pricing/pricing_plan_card.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  Future<void> _selectPlan(
    BuildContext context,
    SubscriptionPlan plan,
  ) async {
    final provider = context.read<SubscriptionProvider>();
    final ok = await provider.selectPlan(plan);
    if (!context.mounted) return;

    if (!ok) {
      AppSnackbar.error(
        context,
        provider.errorMessage ?? 'Gagal menyimpan paket. Coba lagi.',
      );
      provider.clearError();
      return;
    }

    if (plan == SubscriptionPlan.pro) {
      AppSnackbar.success(
        context,
        'Pembayaran belum aktif. Paket Pro disimpan di server untuk uji coba.',
      );
    } else {
      AppSnackbar.info(
        context,
        'Paket Gratis aktif di server. Kamu bisa upgrade ke Pro kapan saja.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final subscription = context.watch<SubscriptionProvider>();
    final current = subscription.currentPlan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paket & Harga'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        children: [
          Text(
            'Pilih paket yang cocok untuk toko kamu',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Paket aktif sekarang: ${current.label}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Harga contoh, pembayaran belum terhubung.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          PricingPlanCard(
            plan: SubscriptionPlan.free,
            isActive: current == SubscriptionPlan.free,
            onSelect: () => _selectPlan(context, SubscriptionPlan.free),
          ),
          const SizedBox(height: 12),
          PricingPlanCard(
            plan: SubscriptionPlan.pro,
            isActive: current == SubscriptionPlan.pro,
            onSelect: () => _selectPlan(context, SubscriptionPlan.pro),
          ),
        ],
      ),
    );
  }
}
