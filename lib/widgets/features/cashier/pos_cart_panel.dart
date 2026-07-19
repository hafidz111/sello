import 'package:flutter/material.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/pos_cart_line.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class PosCartPanel extends StatelessWidget {
  const PosCartPanel({
    super.key,
    required this.lines,
    required this.customerController,
    required this.isSaving,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
  });

  final List<PosCartLine> lines;
  final TextEditingController customerController;
  final bool isSaving;
  final ValueChanged<PosCartLine> onIncrement;
  final ValueChanged<PosCartLine> onDecrement;
  final ValueChanged<PosCartLine> onRemove;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  int get _total => lines.fold(0, (sum, line) => sum + line.subtotal);

  int get _itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  @override
  Widget build(BuildContext context) {
    final bottomInset = Responsive.floatingBottomNavInset(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text('Keranjang', style: AppTextStyles.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_itemCount item',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (lines.isNotEmpty)
                  TextButton(
                    onPressed: isSaving ? null : onClear,
                    child: const Text('Kosongkan'),
                  ),
              ],
            ),
          ),
          if (lines.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: Text(
                'Tap produk di katalog untuk menambah ke keranjang.',
                style: AppTextStyles.bodySmall,
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: lines.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final line = lines[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.product.name,
                              style: AppTextStyles.titleMedium,
                            ),
                            Text(
                              formatRupiah(line.product.price),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: isSaving ? null : () => onDecrement(line),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${line.quantity}', style: AppTextStyles.titleMedium),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: isSaving ? null : () => onIncrement(line),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      Text(
                        formatRupiah(line.subtotal),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: isSaving ? null : () => onRemove(line),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: customerController,
                enabled: !isSaving,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nama pelanggan (opsional)',
                  hintText: 'Pelanggan umum',
                  prefixIcon: Icon(Icons.person_outline),
                  isDense: true,
                ),
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: AppTextStyles.bodySmall),
                      Text(
                        formatRupiah(_total),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: lines.isEmpty || isSaving ? null : onCheckout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Icon(Icons.point_of_sale_rounded),
                  label: Text(
                    isSaving ? 'Menyimpan...' : 'Catat Penjualan',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
