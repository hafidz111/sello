import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sello/core/utils/barcode_format_mapper.dart';
import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class BarcodeScanResult {
  const BarcodeScanResult({
    required this.value,
    required this.type,
  });

  final String value;
  final ProductBarcodeType type;
}

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({
    super.key,
    this.title = 'Scan Barcode',
    this.hint = 'Arahkan kamera ke barcode produk',
  });

  final String title;
  final String hint;

  static Future<BarcodeScanResult?> open(BuildContext context) {
    return Navigator.of(context).push<BarcodeScanResult>(
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
  }

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  MobileScannerController? _controller;
  bool _isInitializing = true;
  bool _isHandling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initScanner() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
        ],
      );
      _isInitializing = false;
      _errorMessage = null;
    });
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isHandling) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      setState(() => _isHandling = true);
      if (!mounted) return;

      Navigator.of(context).pop(
        BarcodeScanResult(
          value: raw,
          type: BarcodeFormatMapper.resolve(barcode.format),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : _errorMessage != null
                    ? _ErrorState(
                        message: _errorMessage!,
                        onRetry: () {
                          setState(() {
                            _isInitializing = true;
                            _errorMessage = null;
                          });
                          _initScanner();
                        },
                      )
                    : controller == null
                        ? const SizedBox.shrink()
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                controller: controller,
                                onDetect: _handleDetect,
                              ),
                              Center(
                                child: Container(
                                  width: 260,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primaryLight,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            color: AppColors.surface,
            child: Text(
              widget.hint,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
