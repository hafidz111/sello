import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/education_provider.dart';
import 'package:sello/providers/subscription_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/education/education_change_tips_button.dart';
import 'package:sello/widgets/features/education/education_empty_state.dart';
import 'package:sello/widgets/features/education/education_tip_card.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  int get _educationDailyLimit =>
      context.read<SubscriptionProvider>().currentPlan.educationDailyLimit;

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    final provider = context.read<EducationProvider>();
    await provider.load(userId, dailyLimit: _educationDailyLimit);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearMessages();
    }
  }

  Future<void> _changeTips() async {
    final userId = context.read<AuthProvider>().userId;
    final provider = context.read<EducationProvider>();
    await provider.changeTips(userId, dailyLimit: _educationDailyLimit);
    if (!mounted) return;

    if (provider.errorMessage != null) {
      AppSnackbar.warning(context, provider.errorMessage!);
      provider.clearMessages();
      return;
    }
    if (provider.infoMessage != null) {
      AppSnackbar.info(context, provider.infoMessage!);
      provider.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final state = context.watch<EducationProvider>();
    final isPro = context.watch<SubscriptionProvider>().isPro;
    final guide = state.guide;
    final quota = state.quota;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edukasi Mikro'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        children: [
          Text(
            'Tips praktis dari data penjualan 30 hari terakhir.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isPro
                ? 'Paket Pro: hingga ${quota.limit} tips per hari.'
                : 'Paket Gratis: terbatas ${quota.limit} tips per hari.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quota.statusLabel,
            style: AppTextStyles.bodySmall.copyWith(
              color: quota.isExhausted
                  ? AppColors.warning
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (guide == null || guide.isEmpty)
            EducationEmptyState(onRetry: _changeTips)
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan AI',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(guide.headline, style: AppTextStyles.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < guide.tips.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              EducationTipCard(tip: guide.tips[i], index: i + 1),
            ],
            const SizedBox(height: 20),
            EducationChangeTipsButton(
              enabled: state.canChangeTips,
              isExhausted: quota.isExhausted,
              onPressed: _changeTips,
            ),
          ],
        ],
      ),
    );
  }
}
