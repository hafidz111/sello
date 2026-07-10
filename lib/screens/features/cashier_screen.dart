import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/cashier_mode.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/services/ai_service.dart';
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
  final _speech = SpeechToText();
  late final NavigationProvider _navigationProvider;

  CashierMode _mode = CashierMode.voice;
  CashierVoiceStatus _voiceStatus = CashierVoiceStatus.idle;
  bool _speechReady = false;

  List<SaleItem> _items = const [];

  int get _grandTotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _navigationProvider = context.read<NavigationProvider>();
    _initSpeech();
    _navigationProvider.addListener(_onNavigationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingMode());
  }

  @override
  void dispose() {
    _navigationProvider.removeListener(_onNavigationChanged);
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
    if (_voiceStatus != CashierVoiceStatus.idle) return;

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
      final items = await _aiService.extractSale(text);
      if (!mounted) return;
      setState(() {
        _items = items;
        _voiceStatus = CashierVoiceStatus.idle;
      });
      AppSnackbar.success(
        context,
        'Berhasil mencatat ${items.length} item penjualan.',
      );
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _voiceStatus = CashierVoiceStatus.idle);
      AppSnackbar.error(context, e.message);
    }
  }

  void _clear() {
    setState(() => _items = const []);
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
