import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sello/services/rewarded_ad_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';

/// Memburamkan isi laporan sampai user menonton iklan reward.
class ReportWatchGate extends StatefulWidget {
  const ReportWatchGate({
    super.key,
    required this.child,
    required this.locked,
    required this.onUnlocked,
    this.onUpgradeTap,
    this.fillViewport = false,
  });

  final Widget child;
  final bool locked;
  final VoidCallback onUnlocked;
  final VoidCallback? onUpgradeTap;

  /// Isi satu halaman penuh (blur + overlay di tengah layar).
  final bool fillViewport;

  @override
  State<ReportWatchGate> createState() => _ReportWatchGateState();
}

class _ReportWatchGateState extends State<ReportWatchGate> {
  final _ads = RewardedAdService.instance;

  bool _isBusy = false;
  String _statusText = 'Tonton iklan untuk melihat laporan';

  @override
  void initState() {
    super.initState();
    if (widget.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preload());
    }
  }

  @override
  void didUpdateWidget(covariant ReportWatchGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !oldWidget.locked) {
      _preload();
    }
  }

  Future<void> _preload() async {
    await _ads.loadReportRewardedAd();
    if (!mounted || !widget.locked) return;
    setState(() {
      _statusText = _ads.isReady
          ? 'Iklan siap. Ketuk tombol di bawah.'
          : 'Menyiapkan iklan...';
    });
  }

  Future<void> _watchAd() async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _statusText = 'Membuka iklan...';
    });

    var earned = false;
    await _ads.showReportRewardedAd(
      onUserEarnedReward: (RewardItem reward) {
        earned = true;
      },
      onFailedToShow: () {
        if (!mounted) return;
        AppSnackbar.warning(
          context,
          'Iklan gagal ditampilkan. Periksa koneksi lalu coba lagi.',
        );
      },
    );

    if (!mounted) return;

    if (earned) {
      AppSnackbar.success(context, 'Laporan terbuka. Selamat membaca.');
      widget.onUnlocked();
      setState(() {
        _isBusy = false;
        _statusText = 'Laporan terbuka';
      });
      return;
    }

    setState(() {
      _isBusy = false;
      _statusText = _ads.isReady
          ? 'Iklan belum selesai. Tonton sampai habis untuk membuka laporan.'
          : 'Iklan belum siap. Ketuk lagi untuk memuat.';
    });

    if (!_ads.isReady) {
      await _preload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.locked) {
      return widget.child;
    }

    final gate = Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.9,
              child: widget.fillViewport
                  ? SizedBox.expand(child: widget.child)
                  : widget.child,
            ),
          ),
        ),
        ColoredBox(
          color: AppColors.textPrimary.withValues(alpha: 0.32),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.warning,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Laporan dikunci',
                        style: AppTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Paket Gratis: tonton iklan singkat untuk membuka isi laporan.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isBusy ? null : _watchAd,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                  ),
                                )
                              : const Icon(Icons.play_circle_fill_rounded),
                          label: Text(
                            _isBusy ? 'Menyiapkan...' : 'Tonton untuk buka',
                            style: AppTextStyles.labelLarge,
                          ),
                        ),
                      ),
                      if (widget.onUpgradeTap != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: widget.onUpgradeTap,
                          child: Text(
                            'Upgrade ke Pro tanpa iklan',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.fillViewport) {
      return SizedBox.expand(child: gate);
    }
    return gate;
  }
}
