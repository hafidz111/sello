import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/product.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierManualPanel extends StatelessWidget {
  const CashierManualPanel({
    super.key,
    required this.catalog,
    required this.isLoadingCatalog,
    required this.isSaving,
    required this.selectedProduct,
    required this.quantity,
    required this.customerController,
    required this.onProductChanged,
    required this.onDecrementQuantity,
    required this.onIncrementQuantity,
    required this.onSubmit,
    required this.onOpenRegister,
  });

  final List<Product> catalog;
  final bool isLoadingCatalog;
  final bool isSaving;
  final Product? selectedProduct;
  final int quantity;
  final TextEditingController customerController;
  final ValueChanged<Product?> onProductChanged;
  final VoidCallback onDecrementQuantity;
  final VoidCallback onIncrementQuantity;
  final VoidCallback onSubmit;
  final VoidCallback onOpenRegister;

  int get _subtotal => (selectedProduct?.price ?? 0) * quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catat penjualan manual', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Pilih produk dari katalog, atur jumlah, lalu simpan ke Supabase.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
          if (isLoadingCatalog)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (catalog.isEmpty)
            _EmptyCatalog(onOpenRegister: onOpenRegister)
          else ...[
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Produk',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  hint: const Text('Pilih produk'),
                  items: catalog
                      .map(
                        (product) => DropdownMenuItem(
                          value: product,
                          child: Text(
                            '${product.name} · ${formatRupiah(product.price)} · stok ${product.stock}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isSaving ? null : onProductChanged,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Jumlah', style: AppTextStyles.bodyMedium),
                const Spacer(),
                IconButton(
                  onPressed: isSaving || quantity <= 1
                      ? null
                      : onDecrementQuantity,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$quantity', style: AppTextStyles.titleLarge),
                IconButton(
                  onPressed: isSaving ? null : onIncrementQuantity,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: customerController,
              enabled: !isSaving,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Nama pelanggan (opsional)',
                hintText: 'Pelanggan umum',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            if (selectedProduct != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: AppTextStyles.bodyMedium),
                    Text(
                      formatRupiah(_subtotal),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isSaving || selectedProduct == null ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_shopping_cart_rounded),
                label: Text(isSaving ? 'Menyimpan...' : 'Catat Penjualan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.onOpenRegister});

  final VoidCallback onOpenRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: AppColors.textHint,
        ),
        const SizedBox(height: 8),
        Text(
          'Belum ada produk di katalog.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenRegister,
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Daftar Produk'),
        ),
      ],
    );
  }
}
