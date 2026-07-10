import 'package:flutter/material.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/cashier/cashier_header.dart';
import 'package:sello/widgets/features/cashier/cashier_input_card.dart';
import 'package:sello/widgets/features/cashier/cashier_result_area.dart';

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
          child: const CashierHeader(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
          child: CashierInputCard(
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
          child: CashierResultArea(
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
