import 'package:flutter/material.dart';
import 'package:sello/core/constants/app_constants.dart';
import 'package:sello/styles/app_text_styles.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: AppTextStyles.headlineLarge.copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppConstants.appTagline,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
