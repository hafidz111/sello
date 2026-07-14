import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/cashier_mode.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/providers/report_provider.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/cashier/cashier_header.dart';
import 'package:sello/widgets/features/cashier/cashier_mode_selector.dart';
import 'package:sello/widgets/features/cashier/cashier_result_area.dart';
import 'package:sello/widgets/features/cashier/cashier_scan_section.dart';
import 'package:sello/widgets/features/cashier/cashier_voice_panel.dart';
import 'package:speech_to_text/speech_to_text.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _aiService = AiService.instance;
  final _productService = ProductService.instance;
  final _speech = SpeechToText();
  final _customerController = TextEditingController();
  late final NavigationProvider _navigationProvider;

  CashierMode _mode = CashierMode.voice;
  CashierVoiceStatus _voiceStatus = CashierVoiceStatus.idle;
  bool _speechReady = false;
  bool _isSaving = false;

  List<Product> _catalog = const [];
  List<SaleItem> _items = const [];

  int get _grandTotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
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
    try {
      final products = await _productService.fetchProducts(userId);
      if (!mounted) return;
      setState(() => _catalog = products);
    } catch (_) {
      // Katalog kosong tetap boleh input suara; fuzzy match dilewati.
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
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _voiceStatus = CashierVoiceStatus.idle);
      AppSnackbar.error(context, e.message);
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

      await context.read<DashboardProvider>().load(userId);
      if (mounted) {
        await context.read<ReportProvider>().load(userId);
      }

      if (!mounted) return;
      setState(() {
        _items = const [];
        _customerController.clear();
        _isSaving = false;
      });
      await _loadCatalog();
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, 'Gagal menyimpan penjualan.');
    }
  }

  void _clear() {
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
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
          child: CashierVoicePanel(
            status: _voiceStatus,
            onMicTap: _handleMicTap,
          ),
        ),
        Expanded(
          child: CashierResultArea(
            isLoading: _voiceStatus == CashierVoiceStatus.processing,
            isSaving: _isSaving,
            items: _items,
            grandTotal: _grandTotal,
            horizontalPadding: padding,
            customerController: _customerController,
            onClear: _clear,
            onSave: _saveSales,
          ),
        ),
      ],
    );
  }
}
