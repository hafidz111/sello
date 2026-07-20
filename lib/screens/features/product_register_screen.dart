import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/barcode_normalizer.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/screens/features/barcode_scan_screen.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/product_register/register_form_body.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ProductRegisterScreen extends StatefulWidget {
  const ProductRegisterScreen({
    super.key,
    this.initialName,
    this.initialPrimaryBarcode,
    this.initialAlternateBarcode,
  });

  final String? initialName;
  final String? initialPrimaryBarcode;
  final String? initialAlternateBarcode;

  @override
  State<ProductRegisterScreen> createState() => _ProductRegisterScreenState();
}

class _ProductRegisterScreenState extends State<ProductRegisterScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _costController = TextEditingController(text: '0');
  final _stockController = TextEditingController(text: '0');
  final _barcodeController = TextEditingController();
  final _alternateBarcodeController = TextEditingController();
  final _picker = ImagePicker();
  final _productService = ProductService.instance;
  final _aiService = AiService.instance;
  final _speech = SpeechToText();

  final Map<String, Uint8List> _photos = {};
  bool _isSaving = false;
  bool _isListeningVoice = false;
  bool _speechReady = false;
  ProductBarcodeType? _barcodeType;
  ProductBarcodeType? _alternateBarcodeType;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _barcodeController.text = widget.initialPrimaryBarcode ?? '';
    _alternateBarcodeController.text = widget.initialAlternateBarcode ?? '';
    if (_barcodeController.text.isNotEmpty) {
      _barcodeType = BarcodeNormalizer.inferType(_barcodeController.text);
    }
    if (_alternateBarcodeController.text.isNotEmpty) {
      _alternateBarcodeType = BarcodeNormalizer.inferType(
        _alternateBarcodeController.text,
      );
    }
    _initSpeech();
    _barcodeController.addListener(_onBarcodeTextChanged);
    _alternateBarcodeController.addListener(_onBarcodeTextChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _alternateBarcodeController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ready = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListeningVoice = false);
      },
    );
    if (mounted) setState(() => _speechReady = ready);
  }

  void _onBarcodeTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleBarcodeScan(BarcodeScanResult result) {
    setState(() {
      _barcodeController.text = result.value;
      _barcodeType = result.type;
    });
  }

  void _handleAlternateBarcodeScan(BarcodeScanResult result) {
    setState(() {
      _alternateBarcodeController.text = result.value;
      _alternateBarcodeType = result.type;
    });
  }

  Future<void> _capturePhoto(String angle) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _photos[angle] = bytes);
  }

  Future<void> _fillFromVoice() async {
    if (_isSaving || _isListeningVoice) return;

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

    setState(() => _isListeningVoice = true);
    await _speech.listen(
      onResult: (result) async {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        await _speech.stop();
        if (!mounted) return;
        if (text.isEmpty) {
          setState(() => _isListeningVoice = false);
          AppSnackbar.warning(context, 'Suara tidak terdengar jelas. Coba lagi.');
          return;
        }
        await _extractProductListing(text);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _extractProductListing(String text) async {
    try {
      final draft = await _aiService.extractProductListing(text);
      if (!mounted) return;
      setState(() {
        _nameController.text = draft.name;
        _priceController.text = '${draft.price}';
        _costController.text = '${draft.costPrice}';
        _stockController.text = '${draft.stock}';
        _isListeningVoice = false;
      });
      AppSnackbar.success(
        context,
        'Form terisi dari suara. Cek lagi lalu ambil foto referensi.',
      );
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _isListeningVoice = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isListeningVoice = false);
      AppSnackbar.error(context, 'Gagal membaca deskripsi produk dari suara.');
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price =
        int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    final costPrice =
        int.tryParse(_costController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    final stock =
        int.tryParse(_stockController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    if (name.isEmpty) {
      AppSnackbar.warning(context, 'Nama produk wajib diisi.');
      return;
    }
    if (_photos.isEmpty) {
      AppSnackbar.warning(context, 'Ambil minimal satu foto referensi produk.');
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().userId;

    try {
      final barcodeText = _barcodeController.text.trim();
      final alternateText = _alternateBarcodeController.text.trim();
      await _productService.createProduct(
        userId: userId,
        name: name,
        price: price,
        costPrice: costPrice,
        stock: stock,
        imagesByAngle: Map.from(_photos),
        codeType: barcodeText.isEmpty ? null : _barcodeType,
        codeValue: barcodeText.isEmpty ? null : barcodeText,
        alternateCodeType:
            alternateText.isEmpty ? null : _alternateBarcodeType,
        alternateCodeValue: alternateText.isEmpty ? null : alternateText,
        autoGenerateBarcode: barcodeText.isEmpty,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Produk berhasil didaftarkan.');
      Navigator.of(context).pop(true);
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, 'Gagal menyimpan produk. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        child: RegisterFormBody(
          nameController: _nameController,
          priceController: _priceController,
          costController: _costController,
          stockController: _stockController,
          barcodeController: _barcodeController,
          alternateBarcodeController: _alternateBarcodeController,
          barcodeType: _barcodeType,
          alternateBarcodeType: _alternateBarcodeType,
          photos: _photos,
          isSaving: _isSaving,
          isListeningVoice: _isListeningVoice,
          onCapturePhoto: _capturePhoto,
          onFillFromVoice: _fillFromVoice,
          onBarcodeTypeChanged: (type) => setState(() => _barcodeType = type),
          onAlternateBarcodeTypeChanged: (type) =>
              setState(() => _alternateBarcodeType = type),
          onScanResult: _handleBarcodeScan,
          onAlternateScanResult: _handleAlternateBarcodeScan,
          onSave: _save,
        ),
      ),
    );
  }
}
