import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

enum CashierVoiceStatus {
  idle,
  listening,
  processing,
}

class CashierVoicePanel extends StatelessWidget {
  const CashierVoicePanel({
    super.key,
    required this.status,
    required this.onMicTap,
  });

  final CashierVoiceStatus status;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    final isListening = status == CashierVoiceStatus.listening;
    final isProcessing = status == CashierVoiceStatus.processing;
    final isBusy = isListening || isProcessing;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            _statusLabel,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: isBusy ? null : onMicTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isListening
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                      )
                    : AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: isListening ? 24 : 12,
                    spreadRadius: isListening ? 4 : 0,
                  ),
                ],
              ),
              child: isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 40,
                      color: AppColors.textOnPrimary,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isBusy ? 'Tunggu sebentar...' : 'Ketuk mikrofon untuk mulai',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String get _statusLabel {
    return switch (status) {
      CashierVoiceStatus.idle =>
        'Ucapkan penjualan singkat, mis. "jual 3 kopi". Nama akan dicocokkan ke katalog.',
      CashierVoiceStatus.listening => 'Mendengarkan...',
      CashierVoiceStatus.processing =>
        'AI merapikan catatan dan mencocokkan katalog...',
    };
  }
}
