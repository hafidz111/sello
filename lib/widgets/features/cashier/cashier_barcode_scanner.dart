import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class CashierBarcodeScanner extends StatefulWidget {
  const CashierBarcodeScanner({
    super.key,
    required this.enabled,
    required this.onBarcode,
  });

  final bool enabled;
  final ValueChanged<String> onBarcode;

  @override
  State<CashierBarcodeScanner> createState() => _CashierBarcodeScannerState();
}

class _CashierBarcodeScannerState extends State<CashierBarcodeScanner> {
  MobileScannerController? _controller;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _lastEmittedCode;
  DateTime? _lastEmittedAt;

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

  void _handleDetect(BarcodeCapture capture) {
    if (!widget.enabled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      final now = DateTime.now();
      if (_lastEmittedCode == raw &&
          _lastEmittedAt != null &&
          now.difference(_lastEmittedAt!) < const Duration(seconds: 2)) {
        return;
      }

      _lastEmittedCode = raw;
      _lastEmittedAt = now;
      widget.onBarcode(raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textOnPrimary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initScanner();
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _handleDetect,
        ),
        Center(
          child: Container(
            width: 280,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryLight, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Text(
            'Scan barcode Code 128 atau barcode kemasan',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
