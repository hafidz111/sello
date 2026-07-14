import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/report_period.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/report_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/report/report_empty_state.dart';
import 'package:sello/widgets/features/report/report_insight_card.dart';
import 'package:sello/widgets/features/report/report_period_selector.dart';
import 'package:sello/widgets/features/report/report_ranked_list.dart';
import 'package:sello/widgets/features/report/report_summary_cards.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    final userId = context.read<AuthProvider>().userId;
    await context.read<ReportProvider>().load(userId);
    _showErrorIfAny();
  }

  Future<void> _onPeriodSelected(ReportPeriod period) async {
    final userId = context.read<AuthProvider>().userId;
    await context.read<ReportProvider>().setPeriod(userId, period);
    _showErrorIfAny();
  }

  Future<void> _pickCustomRange() async {
    final provider = context.read<ReportProvider>();
    final initial = DateTimeRange(
      start: provider.customRange.start,
      end: provider.customRange.endInclusive,
    );
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: initial,
      helpText: 'Pilih rentang tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      saveText: 'Terapkan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.warning,
              onPrimary: AppColors.textOnPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    final userId = context.read<AuthProvider>().userId;
    await context.read<ReportProvider>().setCustomRange(
      userId,
      from: picked.start,
      to: picked.end,
    );
    _showErrorIfAny();
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthProvider>().userId;
    await context.read<ReportProvider>().load(userId);
    _showErrorIfAny();
  }

  void _showErrorIfAny() {
    if (!mounted) return;
    final error = context.read<ReportProvider>().errorMessage;
    if (error != null) {
      AppSnackbar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final bottomPad = Responsive.bottomScrollPadding(context);
    final reportState = context.watch<ReportProvider>();
    final report = reportState.report;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 20, padding, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Laporan Bisnis', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Filter periode atau pilih rentang tanggal, lalu baca ringkasan AI.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ReportPeriodSelector(
                    selected: reportState.period,
                    onSelected:
                        reportState.isLoading ? (_) {} : _onPeriodSelected,
                    onPickCustomRange:
                        reportState.isLoading ? () {} : _pickCustomRange,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _rangeLabel(report.rangeStart, report.rangeEndInclusive),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (reportState.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!report.hasSales)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 12, padding, bottomPad),
                child: Column(
                  children: [
                    ReportInsightCard(insight: report.insight),
                    const SizedBox(height: 12),
                    ReportEmptyState(
                      periodLabel: reportState.period.label.toLowerCase(),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 12, padding, bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportSummaryCards(report: report),
                    const SizedBox(height: 12),
                    ReportRankedList(
                      title: 'Produk terlaris',
                      emptyMessage: 'Belum ada produk terjual di periode ini.',
                      items: report.topProducts
                          .map(
                            (p) => ReportMetricRow(
                              title: p.productName,
                              revenue: p.revenue,
                              profit: p.profit,
                              transactionCount: p.transactionCount,
                              itemCount: p.quantitySold,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    ReportRankedList(
                      title: 'Pelanggan utama',
                      emptyMessage: 'Belum ada data pelanggan di periode ini.',
                      items: report.topCustomers
                          .map(
                            (c) => ReportMetricRow(
                              title: c.customerName,
                              revenue: c.revenue,
                              profit: c.profit,
                              transactionCount: c.transactionCount,
                              itemCount: c.quantitySold,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    ReportInsightCard(insight: report.insight),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _rangeLabel(DateTime start, DateTime endInclusive) {
    String fmt(DateTime d) {
      final local = d.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      return '$day/$month/${local.year}';
    }

    return 'Periode: ${fmt(start)} – ${fmt(endInclusive)}';
  }
}
