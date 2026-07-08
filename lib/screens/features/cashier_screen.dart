import 'package:flutter/material.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _controller = TextEditingController();
  final _aiService = AiService.instance;

  bool _isLoading = false;
  List<SaleItem> _items = const [];

  static const _examples = [
    'Jual 5 keripik singkong 10 ribu',
    '2 teh botol 4rb sama 1 roti bakar 15000',
    '3 kopi susu harga 8 ribu',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _grandTotal =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _extract() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      AppSnackbar.warning(context, 'Tulis dulu penjualannya, ya.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final items = await _aiService.extractSale(text);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
      AppSnackbar.success(
        context,
        'Berhasil mencatat ${items.length} item penjualan.',
      );
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, e.message);
    }
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _items = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 0),
          child: _Header(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
          child: _InputCard(
            controller: _controller,
            examples: _examples,
            isLoading: _isLoading,
            onSubmit: _extract,
            onExampleTap: (text) {
              _controller.text = text;
              _extract();
            },
          ),
        ),
        Expanded(
          child: _ResultArea(
            isLoading: _isLoading,
            items: _items,
            grandTotal: _grandTotal,
            horizontalPadding: padding,
            onClear: _clear,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kasir Cerdas', style: AppTextStyles.titleLarge),
                  Text(
                    'Tulis penjualan pakai bahasa sehari-hari',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.examples,
    required this.isLoading,
    required this.onSubmit,
    required this.onExampleTap,
  });

  final TextEditingController controller;
  final List<String> examples;
  final bool isLoading;
  final VoidCallback onSubmit;
  final ValueChanged<String> onExampleTap;

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
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Contoh: jual 5 keripik singkong 10 ribu...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: examples.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final text = examples[index];
                return ActionChip(
                  label: Text(text, style: AppTextStyles.bodySmall),
                  backgroundColor: AppColors.primaryContainer,
                  side: BorderSide.none,
                  onPressed: isLoading ? null : () => onExampleTap(text),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              isLoading ? 'Memproses...' : 'Catat dengan AI',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultArea extends StatelessWidget {
  const _ResultArea({
    required this.isLoading,
    required this.items,
    required this.grandTotal,
    required this.horizontalPadding,
    required this.onClear,
  });

  final bool isLoading;
  final List<SaleItem> items;
  final int grandTotal;
  final double horizontalPadding;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoading) {
      return const _CenteredMessage(
        icon: Icons.receipt_long_rounded,
        color: AppColors.textHint,
        title: 'Belum ada catatan',
        message:
            'Tulis penjualanmu di atas, lalu AI akan merapikannya jadi '
            'daftar item, jumlah, dan harga.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              Responsive.bottomScrollPadding(context),
            ),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} item terdeteksi',
                      style: AppTextStyles.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset'),
                    ),
                  ],
                );
              }
              return _SaleItemCard(item: items[index - 1]);
            },
          ),
        ),
        _TotalBar(grandTotal: grandTotal, padding: horizontalPadding),
      ],
    );
  }
}

class _SaleItemCard extends StatelessWidget {
  const _SaleItemCard({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.quantity}x',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '@ ${formatRupiah(item.unitPrice)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupiah(item.subtotal),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.grandTotal, required this.padding});

  final int grandTotal;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(padding, 0, padding, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          Text(
            formatRupiah(grandTotal),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Memformat angka jadi "Rp 12.500".
String formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}
