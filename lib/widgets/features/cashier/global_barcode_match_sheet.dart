import 'package:flutter/material.dart';
import 'package:sello/models/reference_item.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class GlobalBarcodeMatchSheet extends StatelessWidget {
  const GlobalBarcodeMatchSheet({
    super.key,
    required this.scannedCode,
    required this.reference,
    required this.onRegister,
  });

  final String scannedCode;
  final ReferenceItem reference;
  final VoidCallback onRegister;

  static Future<void> show(
    BuildContext context, {
    required String scannedCode,
    required ReferenceItem reference,
    required VoidCallback onRegister,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GlobalBarcodeMatchSheet(
        scannedCode: scannedCode,
        reference: reference,
        onRegister: onRegister,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Ditemukan di database global', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(reference.name, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Barcode discan: $scannedCode',
              style: AppTextStyles.bodySmall,
            ),
            if (reference.barcodeValues.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                'Barcode terdaftar: ${reference.barcodeValues.join(', ')}',
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRegister();
              },
              child: const Text('Daftar ke katalog toko'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}
