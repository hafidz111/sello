import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/product.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class TranslateProductPicker extends StatelessWidget {
  const TranslateProductPicker({
    super.key,
    required this.products,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final List<Product> products;
  final Product? selected;
  final bool enabled;
  final ValueChanged<Product?> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Product>(
      // ignore: deprecated_member_use
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Pilih produk',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: [
        for (final product in products)
          DropdownMenuItem(
            value: product,
            child: Text(
              '${product.name} · ${formatRupiah(product.price)}',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
      onChanged: enabled ? onSelected : null,
    );
  }
}
