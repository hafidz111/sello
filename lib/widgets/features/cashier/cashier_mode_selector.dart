import 'package:flutter/material.dart';
import 'package:sello/models/cashier_mode.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/features/cashier/cashier_mode_button.dart';

class CashierModeSelector extends StatelessWidget {
  const CashierModeSelector({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.onDarkBackground = false,
  });

  final CashierMode mode;
  final ValueChanged<CashierMode> onModeChanged;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final selectedColor = onDarkBackground
        ? AppColors.textOnPrimary
        : AppColors.primary;
    final unselectedColor = onDarkBackground
        ? AppColors.textOnPrimary.withValues(alpha: 0.6)
        : AppColors.textSecondary;
    final backgroundColor = onDarkBackground
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.surfaceVariant;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: CashierModeButton(
              icon: Icons.edit_note_rounded,
              label: 'Manual',
              isSelected: mode == CashierMode.manual,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onModeChanged(CashierMode.manual),
            ),
          ),
          Expanded(
            child: CashierModeButton(
              icon: Icons.mic_rounded,
              label: 'Suara',
              isSelected: mode == CashierMode.voice,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onModeChanged(CashierMode.voice),
            ),
          ),
          Expanded(
            child: CashierModeButton(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              isSelected: mode == CashierMode.scan,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              onTap: () => onModeChanged(CashierMode.scan),
            ),
          ),
        ],
      ),
    );
  }
}
