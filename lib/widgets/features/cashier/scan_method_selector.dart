import 'package:flutter/material.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

enum ScanCaptureMode {
  barcode,
  visual;

  String get label => switch (this) {
    barcode => 'Barcode',
    visual => 'Foto',
  };
}

class ScanMethodSelector extends StatelessWidget {
  const ScanMethodSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ScanCaptureMode mode;
  final ValueChanged<ScanCaptureMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in ScanCaptureMode.values)
            Expanded(
              child: Material(
                color: mode == option
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(option),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      option.label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: mode == option
                            ? AppColors.textOnPrimary
                            : AppColors.textOnPrimary.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
