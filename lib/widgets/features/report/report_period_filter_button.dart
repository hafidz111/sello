import 'package:flutter/material.dart';
import 'package:sello/models/report_period.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';

class ReportPeriodFilterButton extends StatelessWidget {
  const ReportPeriodFilterButton({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.onPickCustomRange,
  });

  final ReportPeriod selected;
  final bool enabled;
  final ValueChanged<ReportPeriod> onSelected;
  final VoidCallback onPickCustomRange;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReportPeriod>(
      enabled: enabled,
      tooltip: 'Filter periode',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surface,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
      onSelected: (period) {
        if (period == ReportPeriod.custom) {
          onPickCustomRange();
          return;
        }
        onSelected(period);
      },
      itemBuilder: (context) {
        return [
          for (final period in ReportPeriod.values)
            PopupMenuItem<ReportPeriod>(
              value: period,
              height: 44,
              child: Row(
                children: [
                  Icon(
                    period == ReportPeriod.custom
                        ? Icons.date_range_rounded
                        : Icons.event_outlined,
                    size: 18,
                    color: period == selected
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      period.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: period == selected
                            ? AppColors.warning
                            : AppColors.textPrimary,
                        fontWeight: period == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (period == selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                ],
              ),
            ),
        ];
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          color: enabled ? AppColors.warning : AppColors.textHint,
        ),
      ),
    );
  }
}
