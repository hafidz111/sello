import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/features/product_register/register_photo_slot.dart';

class RegisterFormBody extends StatelessWidget {
  const RegisterFormBody({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.costController,
    required this.stockController,
    required this.photos,
    required this.isSaving,
    required this.onCapturePhoto,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController costController;
  final TextEditingController stockController;
  final Map<String, Uint8List> photos;
  final bool isSaving;
  final ValueChanged<String> onCapturePhoto;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Foto referensi dari berbagai sudut membantu scan mengenali produk saat penjualan.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: _inputDecoration('Nama produk', 'Contoh: Keripik singkong pedas'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Harga jual (Rp)', '10000'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: costController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Harga modal / HPP (Rp)', '7000'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Stok awal (pcs)', '50'),
        ),
        const SizedBox(height: 20),
        Text('Foto referensi', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Minimal 1 foto. Ideal: depan, samping, dan label.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: ProductPhotoAngle.all
              .map(
                (angle) => Expanded(
                  child: RegisterPhotoSlot(
                    label: ProductPhotoAngle.labelFor(angle),
                    bytes: photos[angle],
                    onTap: isSaving ? null : () => onCapturePhoto(angle),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Text('Simpan Produk', style: AppTextStyles.labelLarge),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
