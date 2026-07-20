import 'package:flutter/material.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/services/reference_barcode_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';

class ReferenceBarcodeImportScreen extends StatefulWidget {
  const ReferenceBarcodeImportScreen({super.key});

  @override
  State<ReferenceBarcodeImportScreen> createState() =>
      _ReferenceBarcodeImportScreenState();
}

class _ReferenceBarcodeImportScreenState
    extends State<ReferenceBarcodeImportScreen> {
  final _service = ReferenceBarcodeService.instance;

  bool _isLoadingCount = true;
  bool _isImporting = false;
  int _itemCount = 0;
  String? _lastResultMessage;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    setState(() => _isLoadingCount = true);
    try {
      final count = await _service.countItems();
      if (!mounted) return;
      setState(() {
        _itemCount = count;
        _isLoadingCount = false;
      });
    } on ReferenceBarcodeException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCount = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCount = false);
      AppSnackbar.error(context, 'Gagal memuat database barcode global.');
    }
  }

  Future<void> _importFile() async {
    if (_isImporting) return;
    setState(() {
      _isImporting = true;
      _lastResultMessage = null;
    });

    try {
      final result = await _service.importFromPicker();
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _lastResultMessage =
            'Impor selesai: ${result.itemsImported} item, '
            '${result.barcodesImported} barcode'
            '${result.rowsSkipped > 0 ? ', ${result.rowsSkipped} baris dilewati' : ''}.';
      });
      AppSnackbar.success(context, 'Database barcode global berhasil diperbarui.');
      await _loadCount();
    } on ReferenceBarcodeException catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      AppSnackbar.error(context, 'Gagal mengimpor file barcode.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Database Barcode Global'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        children: [
          Text(
            'Impor file Excel/CSV dengan kolom A–D: '
            'A item, B barcode utama, C penanda barcode kedua, D barcode alternatif.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contoh baris', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Indomie Goreng | 8991111111111 | Indomie Goreng | 8992222222222',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _isLoadingCount
                      ? 'Memuat jumlah item...'
                      : 'Item di database global: $_itemCount',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          if (_lastResultMessage != null) ...[
            const SizedBox(height: 12),
            Text(_lastResultMessage!, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isImporting ? null : _importFile,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isImporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(
              _isImporting ? 'Mengimpor...' : 'Pilih File Excel / CSV',
              style: AppTextStyles.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
