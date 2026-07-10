import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/features/product_scan/scan_camera_message.dart';
import 'package:sello/widgets/features/product_scan/scan_overlay.dart';

class ScanCameraArea extends StatelessWidget {
  const ScanCameraArea({
    super.key,
    required this.isInitializingCamera,
    required this.cameraError,
    required this.controller,
    required this.isDetecting,
    this.onRetryCamera,
  });

  final bool isInitializingCamera;
  final String? cameraError;
  final CameraController? controller;
  final bool isDetecting;
  final VoidCallback? onRetryCamera;

  @override
  Widget build(BuildContext context) {
    if (isInitializingCamera) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (cameraError != null) {
      return ScanCameraMessage(
        icon: Icons.videocam_off_rounded,
        message: cameraError!,
        actionLabel: 'Coba lagi',
        onAction: onRetryCamera,
      );
    }

    final activeController = controller;
    if (activeController == null || !activeController.value.isInitialized) {
      return const ScanCameraMessage(
        icon: Icons.videocam_off_rounded,
        message: 'Kamera belum siap.',
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(activeController),
        const ScanOverlay(),
        if (isDetecting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryLight),
                  SizedBox(height: 16),
                  Text(
                    'Mencocokkan dengan katalog...',
                    style: TextStyle(color: AppColors.textOnPrimary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
