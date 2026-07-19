import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/cashier_mode.dart';
import 'package:sello/models/pos_cart_line.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/sale.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/providers/report_provider.dart';
import 'package:sello/screens/features/product_register_screen.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/services/sale_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/cashier/cashier_header.dart';
import 'package:sello/widgets/features/cashier/cashier_mode_selector.dart';
import 'package:sello/widgets/features/cashier/cashier_result_area.dart';
import 'package:sello/widgets/features/cashier/cashier_scan_section.dart';
import 'package:sello/widgets/features/cashier/cashier_voice_panel.dart';
import 'package:sello/widgets/features/cashier/pos_cart_panel.dart';
import 'package:sello/widgets/features/cashier/pos_product_card.dart';
import 'package:sello/widgets/features/cashier/pos_sales_panel.dart';
import 'package:speech_to_text/speech_to_text.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  final _aiService = AiService.instance;
  final _productService = ProductService.instance;
  final _saleService = SaleService.instance;
  final _speech = SpeechToText();
  final _customerController = TextEditingController();
  late final NavigationProvider _navigationProvider;
  late final TabController _posTabController;

  CashierMode _mode = CashierMode.manual;
  CashierVoiceStatus _voiceStatus = CashierVoiceStatus.idle;
  bool _speechReady = false;
  bool _isSaving = false;
  bool _isLoadingCatalog = false;

  List<Product> _catalog = const [];
  List<SaleItem> _items = const [];
  List<PosCartLine> _cartLines = const [];
  int _salesRefreshNonce = 0;

  int get _grandTotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _posTabController = TabController(length: 2, vsync: this);
    _navigationProvider = context.read<NavigationProvider>();
    _initSpeech();
    _navigationProvider.addListener(_onNavigationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingMode();
      _loadCatalog();
    });
  }

  @override
  void dispose() {
    _posTabController.dispose();
    _navigationProvider.removeListener(_onNavigationChanged);
    _customerController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _onNavigationChanged() {
    _applyPendingMode();
  }

  void _applyPendingMode() {
    final pending = _navigationProvider.consumePendingCashierMode();
    if (pending != null && mounted) {
      setState(() => _mode = pending);
    }
  }

  Future<void> _loadCatalog() async {
    final userId = context.read<AuthProvider>().userId;
    setState(() => _isLoadingCatalog = true);
    try {
      final products = await _productService.fetchProducts(userId);
      if (!mounted) return;
      setState(() {
        _catalog = products;
        _isLoadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCatalog = false);
    }
  }

  Future<void> _refreshAfterMutation() async {
    final userId = context.read<AuthProvider>().userId;
    await Future.wait([
      _loadCatalog(),
      context.read<DashboardProvider>().load(userId),
      context.read<ReportProvider>().load(userId),
    ]);
    if (mounted) {
      setState(() => _salesRefreshNonce++);
    }
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProductRegisterScreen()),
    );
    if (created == true && mounted) {
      await _loadCatalog();
    }
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      AppSnackbar.warning(context, '${product.name} sudah habis.');
      return;
    }

    final lines = List<PosCartLine>.from(_cartLines);
    final index = lines.indexWhere((line) => line.product.id == product.id);

    if (index >= 0) {
      final line = lines[index];
      if (line.quantity >= product.stock) {
        AppSnackbar.warning(
          context,
          'Stok ${product.name} hanya ${product.stock}.',
        );
        return;
      }
      lines[index] = PosCartLine(
        product: product,
        quantity: line.quantity + 1,
      );
    } else {
      lines.add(PosCartLine(product: product));
    }

    setState(() => _cartLines = lines);
  }

  void _incrementCartLine(PosCartLine line) {
    if (line.quantity >= line.product.stock) {
      AppSnackbar.warning(
        context,
        'Stok ${line.product.name} hanya ${line.product.stock}.',
      );
      return;
    }
    setState(() {
      _cartLines = _cartLines
          .map(
            (entry) => entry.product.id == line.product.id
                ? PosCartLine(
                    product: entry.product,
                    quantity: entry.quantity + 1,
                  )
                : entry,
          )
          .toList();
    });
  }

  void _decrementCartLine(PosCartLine line) {
    setState(() {
      _cartLines = _cartLines
          .map(
            (entry) => entry.product.id == line.product.id
                ? PosCartLine(
                    product: entry.product,
                    quantity: entry.quantity - 1,
                  )
                : entry,
          )
          .where((entry) => entry.quantity > 0)
          .toList();
    });
  }

  void _removeCartLine(PosCartLine line) {
    setState(() {
      _cartLines = _cartLines
          .where((entry) => entry.product.id != line.product.id)
          .toList();
    });
  }

  void _clearCart() {
    setState(() {
      _cartLines = const [];
      _customerController.clear();
    });
  }

  Future<void> _checkoutCart() async {
    if (_cartLines.isEmpty) return;

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().userId;
    final customerName = _customerController.text.trim();
    final lineCount = _cartLines.length;

    try {
      final stockByProductId = {
        for (final product in _catalog) product.id: product.stock,
      };

      for (final line in _cartLines) {
        final currentStock =
            stockByProductId[line.product.id] ?? line.product.stock;
        await _saleService.createSale(
          userId: userId,
          product: line.product.copyWith(stock: currentStock),
          quantity: line.quantity,
          customerName: customerName.isEmpty ? null : customerName,
        );
        stockByProductId[line.product.id] = currentStock - line.quantity;
      }

      if (!mounted) return;
      _clearCart();
      await _refreshAfterMutation();
      if (!mounted) return;

      AppSnackbar.success(
        context,
        '$lineCount penjualan tercatat'
        '${customerName.isEmpty ? '' : ' untuk $customerName'}.',
      );
      _posTabController.animateTo(1);
    } on SaleException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal mencatat penjualan.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editSale(Sale sale) async {
    final result = await showDialog<({int quantity, String? customerName})>(
      context: context,
      builder: (context) => _SaleEditDialog(
        productName: sale.productName,
        initialQuantity: sale.quantity,
        initialCustomerName: sale.customerName,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await _saleService.updateSale(
        saleId: sale.id,
        quantity: result.quantity,
        customerName: result.customerName,
      );
      if (!mounted) return;
      await _refreshAfterMutation();
      if (!mounted) return;
      AppSnackbar.success(context, 'Penjualan diperbarui.');
    } on SaleException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal memperbarui penjualan.');
    }
  }

  Future<void> _deleteSale(Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus penjualan'),
        content: Text(
          'Hapus ${sale.quantity}x ${sale.productName} dari laporan hari ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _saleService.deleteSale(sale.id);
      if (!mounted) return;
      await _refreshAfterMutation();
      if (!mounted) return;
      AppSnackbar.success(context, 'Penjualan dihapus.');
    } on SaleException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal menghapus penjualan.');
    }
  }

  Future<void> _initSpeech() async {
    final ready = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() => _voiceStatus = CashierVoiceStatus.idle);
      },
      onStatus: (status) {
        if (!mounted || status != 'notListening') return;
        if (_voiceStatus == CashierVoiceStatus.listening) {
          setState(() => _voiceStatus = CashierVoiceStatus.idle);
        }
      },
    );
    if (mounted) {
      setState(() => _speechReady = ready);
    }
  }

  Future<void> _handleMicTap() async {
    if (_voiceStatus != CashierVoiceStatus.idle || _isSaving) return;

    if (!_aiService.isConfigured) {
      AppSnackbar.warning(
        context,
        'Mode suara butuh GEMINI_API_KEY di .env. Pakai mode Manual.',
      );
      return;
    }

    if (!_speechReady) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        if (!mounted) return;
        AppSnackbar.warning(
          context,
          'Izin mikrofon ditolak. Aktifkan izin mikrofon di pengaturan perangkat.',
        );
        return;
      }
      await _initSpeech();
      if (!_speechReady) {
        if (!mounted) return;
        AppSnackbar.error(
          context,
          'Pengenalan suara tidak tersedia di perangkat ini.',
        );
        return;
      }
    }

    if (_speech.isListening) {
      await _speech.stop();
      return;
    }

    setState(() => _voiceStatus = CashierVoiceStatus.listening);

    await _speech.listen(
      onResult: (result) async {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        await _speech.stop();
        if (!mounted) return;
        if (text.isEmpty) {
          setState(() => _voiceStatus = CashierVoiceStatus.idle);
          AppSnackbar.warning(
            context,
            'Suara tidak terdengar jelas. Coba lagi.',
          );
          return;
        }
        await _extractFromVoice(text);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _extractFromVoice(String text) async {
    setState(() => _voiceStatus = CashierVoiceStatus.processing);

    try {
      if (_catalog.isEmpty) {
        await _loadCatalog();
      }
      final items = await _aiService.extractSale(text, catalog: _catalog);
      if (!mounted) return;
      setState(() {
        _items = items;
        _voiceStatus = CashierVoiceStatus.idle;
      });
      final matched = items.where((item) => item.matchedFromCatalog).length;
      AppSnackbar.success(
        context,
        'Terdeteksi ${items.length} item, $matched cocok katalog.',
      );
    } on AiException catch (error) {
      if (!mounted) return;
      setState(() => _voiceStatus = CashierVoiceStatus.idle);
      AppSnackbar.error(context, error.message);
    }
  }

  Future<void> _saveSales() async {
    final matched = _items.where((item) => item.matchedFromCatalog).toList();
    if (matched.isEmpty) {
      AppSnackbar.warning(
        context,
        'Belum ada item yang cocok katalog. Daftarkan produk dulu atau sebut nama lebih jelas.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().userId;
    final customerName = _customerController.text.trim();

    try {
      for (final item in matched) {
        Product? product;
        for (final entry in _catalog) {
          if (entry.id == item.productId) {
            product = entry;
            break;
          }
        }
        if (product == null) continue;

        await _productService.recordSale(
          userId: userId,
          product: product,
          quantity: item.quantity,
          customerName: customerName.isEmpty ? null : customerName,
        );
      }

      if (!mounted) return;
      AppSnackbar.success(
        context,
        'Berhasil menyimpan ${matched.length} penjualan'
        '${customerName.isEmpty ? '' : ' untuk $customerName'}.',
      );

      await _refreshAfterMutation();

      if (!mounted) return;
      setState(() {
        _items = const [];
        _customerController.clear();
        _isSaving = false;
      });
    } on ProductException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, 'Gagal menyimpan penjualan.');
    }
  }

  void _clearVoiceItems() {
    setState(() {
      _items = const [];
      _customerController.clear();
    });
  }

  void _setMode(CashierMode mode) {
    if (_mode == mode) return;
    if (_speech.isListening) {
      _speech.stop();
    }
    setState(() {
      _mode = mode;
      _voiceStatus = CashierVoiceStatus.idle;
    });
  }

  Widget _buildPosCatalogTab(double padding) {
    if (_isLoadingCatalog) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_catalog.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 48,
                color: AppColors.textHint.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada produk di katalog',
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Daftar produk dulu agar bisa dijual lewat POS.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openRegister,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Daftar Produk'),
              ),
            ],
          ),
        ),
      );
    }

    final gridCount = Responsive.featureGridCount(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Katalog Produk',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _openRegister,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(padding, 12, padding, 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: Responsive.isTablet(context) ? 0.78 : 0.72,
            ),
            itemCount: _catalog.length,
            itemBuilder: (context, index) {
              final product = _catalog[index];
              return PosProductCard(
                product: product,
                onTap: () => _addToCart(product),
              );
            },
          ),
        ),
        PosCartPanel(
          lines: _cartLines,
          customerController: _customerController,
          isSaving: _isSaving,
          onIncrement: _incrementCartLine,
          onDecrement: _decrementCartLine,
          onRemove: _removeCartLine,
          onClear: _clearCart,
          onCheckout: _checkoutCart,
        ),
      ],
    );
  }

  Widget _buildManualPos(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _posTabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Katalog'),
            Tab(text: 'Laporan'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _posTabController,
            children: [
              _buildPosCatalogTab(padding),
              PosSalesPanel(
                refreshNonce: _salesRefreshNonce,
                onEdit: _editSale,
                onDelete: _deleteSale,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);

    if (_mode == CashierMode.scan) {
      return ColoredBox(
        color: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 12),
              child: CashierModeSelector(
                mode: _mode,
                onModeChanged: _setMode,
                onDarkBackground: true,
              ),
            ),
            const Expanded(child: CashierScanSection()),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 0),
          child: const CashierHeader(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
          child: CashierModeSelector(
            mode: _mode,
            onModeChanged: _setMode,
          ),
        ),
        if (_mode == CashierMode.voice)
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
            child: CashierVoicePanel(
              status: _voiceStatus,
              onMicTap: _handleMicTap,
              isAiConfigured: _aiService.isConfigured,
            ),
          ),
        Expanded(
          child: _mode == CashierMode.manual
              ? _buildManualPos(padding)
              : CashierResultArea(
                  isLoading: _voiceStatus == CashierVoiceStatus.processing,
                  isSaving: _isSaving,
                  items: _items,
                  grandTotal: _grandTotal,
                  horizontalPadding: padding,
                  customerController: _customerController,
                  onClear: _clearVoiceItems,
                  onSave: _saveSales,
                ),
        ),
      ],
    );
  }
}

class _SaleEditDialog extends StatefulWidget {
  const _SaleEditDialog({
    required this.productName,
    required this.initialQuantity,
    this.initialCustomerName,
  });

  final String productName;
  final int initialQuantity;
  final String? initialCustomerName;

  @override
  State<_SaleEditDialog> createState() => _SaleEditDialogState();
}

class _SaleEditDialogState extends State<_SaleEditDialog> {
  late int _quantity;
  late final TextEditingController _customerController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _customerController = TextEditingController(
      text: widget.initialCustomerName ?? '',
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah penjualan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.productName),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customerController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama pelanggan (opsional)',
              hintText: 'Pelanggan umum',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (quantity: _quantity, customerName: _customerController.text),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
