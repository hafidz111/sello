import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/sale.dart';
import 'package:sello/models/sales_page_result.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/services/sale_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/cashier/cashier_sale_item_card.dart';

class PosSalesPanel extends StatefulWidget {
  const PosSalesPanel({
    super.key,
    required this.refreshNonce,
    required this.onEdit,
    required this.onDelete,
  });

  final int refreshNonce;
  final Future<void> Function(Sale sale) onEdit;
  final Future<void> Function(Sale sale) onDelete;

  @override
  State<PosSalesPanel> createState() => _PosSalesPanelState();
}

class _PosSalesPanelState extends State<PosSalesPanel> {
  final _saleService = SaleService.instance;

  DateTime _selectedDate = SaleDateRange.startOfDay(DateTime.now());
  int _page = 0;
  bool _isLoading = true;

  SalesDaySummary _summary = SalesDaySummary.empty;
  SalesPageResult? _pageResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didUpdateWidget(covariant PosSalesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshNonce != widget.refreshNonce) {
      _loadData(resetPage: true);
    }
  }

  Future<void> _loadData({bool resetPage = false}) async {
    if (resetPage) {
      _page = 0;
    }

    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().userId;

    try {
      final results = await Future.wait([
        _saleService.fetchSalesDaySummary(
          userId: userId,
          date: _selectedDate,
        ),
        _saleService.fetchSalesPage(
          userId: userId,
          date: _selectedDate,
          page: _page,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as SalesDaySummary;
        _pageResult = results[1] as SalesPageResult;
        _isLoading = false;
      });
    } on SaleException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, 'Gagal memuat riwayat penjualan.');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih tanggal penjualan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = SaleDateRange.startOfDay(picked));
    await _loadData(resetPage: true);
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData(resetPage: true);
  }

  void _goToNextDay() {
    if (SaleDateRange.isToday(_selectedDate)) return;
    final next = _selectedDate.add(const Duration(days: 1));
    if (SaleDateRange.isFutureDay(next)) return;
    setState(() => _selectedDate = next);
    _loadData(resetPage: true);
  }

  void _goToToday() {
    setState(() => _selectedDate = SaleDateRange.startOfDay(DateTime.now()));
    _loadData(resetPage: true);
  }

  Future<void> _goToPage(int page) async {
    if (_pageResult == null) return;
    if (page < 0 || page >= _pageResult!.totalPages) return;
    setState(() => _page = page);
    await _loadData();
  }

  Future<void> _handleEdit(Sale sale) async {
    await widget.onEdit(sale);
    if (mounted) await _loadData();
  }

  Future<void> _handleDelete(Sale sale) async {
    await widget.onDelete(sale);
    if (mounted) {
      final result = _pageResult;
      if (result != null &&
          result.sales.length == 1 &&
          result.hasPrevious &&
          _page > 0) {
        setState(() => _page -= 1);
      }
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _pageResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final pageResult = _pageResult;
    final sales = pageResult?.sales ?? const <Sale>[];
    final horizontalPadding = Responsive.horizontalPadding(context);
    final canGoNext = !SaleDateRange.isToday(_selectedDate);

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          16,
          horizontalPadding,
          Responsive.bottomScrollPadding(context),
        ),
        children: [
          _DateFilterBar(
            dateLabel: SaleDateRange.label(_selectedDate),
            canGoNext: canGoNext,
            onPreviousDay: _goToPreviousDay,
            onNextDay: _goToNextDay,
            onPickDate: _pickDate,
            onToday: _goToToday,
            showTodayButton: !SaleDateRange.isToday(_selectedDate),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            dateLabel: SaleDateRange.label(_selectedDate),
            summary: _summary,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Riwayat penjualan', style: AppTextStyles.titleMedium),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: () => _loadData(),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Muat ulang',
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (sales.isEmpty && !_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: AppColors.textHint.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada penjualan pada ${SaleDateRange.label(_selectedDate).toLowerCase()}',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...sales.map(
              (sale) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        _formatTime(sale.createdAt),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    CashierSaleItemCard(
                      sale: sale,
                      onEdit: () => _handleEdit(sale),
                      onDelete: () => _handleDelete(sale),
                    ),
                  ],
                ),
              ),
            ),
          if (pageResult != null && pageResult.totalCount > 0) ...[
            const SizedBox(height: 8),
            _PaginationBar(
              pageResult: pageResult,
              onPrevious: pageResult.hasPrevious
                  ? () => _goToPage(_page - 1)
                  : null,
              onNext: pageResult.hasNext ? () => _goToPage(_page + 1) : null,
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({
    required this.dateLabel,
    required this.canGoNext,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
    required this.onToday,
    required this.showTodayButton,
  });

  final String dateLabel;
  final bool canGoNext;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;
  final VoidCallback onToday;
  final bool showTodayButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filter tanggal', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: onPreviousDay,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Hari sebelumnya',
              ),
              Expanded(
                child: InkWell(
                  onTap: onPickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(dateLabel, style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: canGoNext ? onNextDay : null,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Hari berikutnya',
              ),
            ],
          ),
          if (showTodayButton)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onToday,
                child: const Text('Kembali ke hari ini'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pageResult,
    required this.onPrevious,
    required this.onNext,
  });

  final SalesPageResult pageResult;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Halaman sebelumnya',
          ),
          Expanded(
            child: Text(
              'Menampilkan ${pageResult.rangeStart}–${pageResult.rangeEnd} '
              'dari ${pageResult.totalCount} · '
              'Hal ${pageResult.page + 1}/${pageResult.totalPages}',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Halaman berikutnya',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.dateLabel,
    required this.summary,
  });

  final String dateLabel;
  final SalesDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan $dateLabel',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(summary.totalRevenue),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: '${summary.transactionCount} transaksi'),
              const SizedBox(width: 8),
              _StatChip(label: '${summary.totalUnits} item terjual'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
