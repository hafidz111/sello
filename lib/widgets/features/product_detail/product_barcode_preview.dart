import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ProductBarcodePreview extends StatelessWidget {
  const ProductBarcodePreview({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final codes = product.allBarcodeValues;
    if (codes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Barcode belum tersedia. Simpan produk untuk buat Code 128 otomatis '
          'atau scan barcode kemasan.',
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < codes.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == codes.length - 1 ? 0 : 12),
            child: _BarcodeCard(
              code: codes[i],
              label: i == 0
                  ? (product.codeType?.label ?? ProductBarcodeType.retail.label)
                  : 'Barcode alternatif',
            ),
          ),
      ],
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          BarcodeWidget(
            barcode: _resolveBarcode(code),
            data: code,
            height: 72,
            drawText: true,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Barcode _resolveBarcode(String code) {
    if (RegExp(r'^\d{13}$').hasMatch(code)) {
      return Barcode.ean13();
    }
    if (RegExp(r'^\d{8}$').hasMatch(code)) {
      return Barcode.ean8();
    }
    return Barcode.code128();
  }
}
