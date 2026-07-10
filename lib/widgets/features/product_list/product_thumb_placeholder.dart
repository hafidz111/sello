import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';

class ProductThumbPlaceholder extends StatelessWidget {
  const ProductThumbPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.textHint),
    );
  }
}
