import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/models/cashier_mode.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

Future<void> showCashierModeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Cara catat penjualan', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Pilih cara yang paling nyaman untuk Anda.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              _ModeOption(
                icon: Icons.edit_note_rounded,
                title: 'Manual',
                subtitle: 'Pilih produk dan jumlah secara langsung',
                onTap: () => _select(sheetContext, CashierMode.manual),
              ),
              const SizedBox(height: 10),
              _ModeOption(
                icon: Icons.mic_rounded,
                title: 'Suara',
                subtitle: 'Ucapkan nama barang dan jumlahnya',
                onTap: () => _select(sheetContext, CashierMode.voice),
              ),
              const SizedBox(height: 10),
              _ModeOption(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan',
                subtitle: 'Scan produk lewat kamera atau barcode',
                onTap: () => _select(sheetContext, CashierMode.scan),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _select(BuildContext context, CashierMode mode) {
  Navigator.of(context).pop();
  context.read<NavigationProvider>().openCashier(mode: mode);
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
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
    );
  }
}
