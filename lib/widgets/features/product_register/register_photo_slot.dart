import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class RegisterPhotoSlot extends StatelessWidget {
  const RegisterPhotoSlot({
    super.key,
    required this.label,
    required this.onTap,
    this.bytes,
    this.networkUrl,
  });

  final String label;
  final Uint8List? bytes;
  final String? networkUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null || (networkUrl != null && networkUrl!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (bytes != null)
                          Image.memory(bytes!, fit: BoxFit.cover)
                        else
                          Image.network(
                            networkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppColors.surfaceVariant,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              label,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(label, style: AppTextStyles.bodySmall),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
