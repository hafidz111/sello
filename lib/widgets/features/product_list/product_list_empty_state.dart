import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ProductListEmptyState extends StatelessWidget {
  const ProductListEmptyState({super.key, required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Belum ada produk',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Daftar produk dengan foto referensi agar scan penjualan bisa mengenali barang.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Daftar Produk Pertama'),
            ),
          ],
        ),
      ),
    );
  }
}
