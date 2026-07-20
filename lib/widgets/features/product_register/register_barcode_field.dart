import 'package:flutter/material.dart';
import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/screens/features/barcode_scan_screen.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class RegisterBarcodeField extends StatelessWidget {
  const RegisterBarcodeField({
    super.key,
    required this.controller,
    required this.codeType,
    required this.enabled,
    required this.onCodeTypeChanged,
    required this.onScanResult,
    this.title = 'Barcode produk',
    this.hint =
        'Scan barcode kemasan (EAN/UPC) atau kosongkan agar Sello buat Code 128 otomatis.',
  });

  final TextEditingController controller;
  final ProductBarcodeType? codeType;
  final bool enabled;
  final String title;
  final String hint;
  final ValueChanged<ProductBarcodeType?> onCodeTypeChanged;
  final void Function(BarcodeScanResult result) onScanResult;

  Future<void> _scan(BuildContext context) async {
    final result = await BarcodeScanScreen.open(context);
    if (result == null) return;
    onScanResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(hint, style: AppTextStyles.bodySmall),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: 'Kode barcode',
            hintText: 'Kosongkan untuk buat otomatis',
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: IconButton(
              onPressed: enabled ? () => _scan(context) : null,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Scan barcode',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        if (controller.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Kemasan'),
                selected: codeType == ProductBarcodeType.retail,
                onSelected: enabled
                    ? (_) => onCodeTypeChanged(ProductBarcodeType.retail)
                    : null,
              ),
              ChoiceChip(
                label: const Text('Code 128'),
                selected: codeType == ProductBarcodeType.code128,
                onSelected: enabled
                    ? (_) => onCodeTypeChanged(ProductBarcodeType.code128)
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
