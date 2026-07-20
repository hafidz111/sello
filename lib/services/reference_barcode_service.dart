import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/core/utils/reference_import_parser.dart';
import 'package:sello/models/reference_import_row.dart';
import 'package:sello/models/reference_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReferenceBarcodeException implements Exception {
  const ReferenceBarcodeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReferenceBarcodeService {
  ReferenceBarcodeService._();

  static final ReferenceBarcodeService instance = ReferenceBarcodeService._();

  static const _itemsTable = 'reference_items';
  static const _barcodesTable = 'reference_barcodes';

  SupabaseClient get _client => SupabaseConfig.client;

  Future<ReferenceItem?> findByCode(String codeValue) async {
    final normalized = ReferenceImportParser.normalizeCode(codeValue);
    if (normalized.isEmpty) return null;

    try {
      final barcodeRow = await _client
          .from(_barcodesTable)
          .select('item_id, code_value, is_primary')
          .eq('code_value', normalized)
          .maybeSingle();

      if (barcodeRow == null) return null;

      final itemId = barcodeRow['item_id'] as String;
      final itemRow = await _client
          .from(_itemsTable)
          .select('id, name')
          .eq('id', itemId)
          .maybeSingle();

      if (itemRow == null) return null;

      final allBarcodes = await _client
          .from(_barcodesTable)
          .select('code_value')
          .eq('item_id', itemId)
          .order('is_primary', ascending: false);

      final values = (allBarcodes as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['code_value'] as String)
          .toList();

      return ReferenceItem(
        id: itemRow['id'] as String,
        name: itemRow['name'] as String,
        barcodeValues: values,
      );
    } on PostgrestException catch (e) {
      throw ReferenceBarcodeException(_mapDbError(e));
    } catch (e) {
      if (e is ReferenceBarcodeException) rethrow;
      throw const ReferenceBarcodeException(
        'Gagal mencari barcode di database referensi.',
      );
    }
  }

  Future<int> countItems() async {
    try {
      final rows = await _client.from(_itemsTable).select('id');
      return (rows as List).length;
    } on PostgrestException catch (e) {
      throw ReferenceBarcodeException(_mapDbError(e));
    } catch (_) {
      throw const ReferenceBarcodeException(
        'Gagal memuat jumlah database barcode.',
      );
    }
  }

  Future<ReferenceImportResult> importRows(List<ReferenceImportRow> rows) async {
    if (rows.isEmpty) {
      throw const ReferenceBarcodeException(
        'File tidak berisi data barcode yang valid.',
      );
    }

    var itemsImported = 0;
    var barcodesImported = 0;
    var rowsSkipped = 0;

    try {
      for (final row in rows) {
        final normalizedName = ReferenceImportParser.normalizeName(row.name);
        if (normalizedName.isEmpty || row.primaryBarcode.isEmpty) {
          rowsSkipped++;
          continue;
        }

        final itemId = await _upsertItem(
          name: row.name.trim(),
          normalizedName: normalizedName,
        );
        itemsImported++;

        final primaryOk = await _upsertBarcode(
          itemId: itemId,
          codeValue: row.primaryBarcode,
          isPrimary: true,
        );
        if (primaryOk) barcodesImported++;

        final alt = row.alternateBarcode?.trim();
        if (alt != null && alt.isNotEmpty) {
          final altOk = await _upsertBarcode(
            itemId: itemId,
            codeValue: alt,
            isPrimary: false,
          );
          if (altOk) barcodesImported++;
        }
      }

      return ReferenceImportResult(
        itemsImported: itemsImported,
        barcodesImported: barcodesImported,
        rowsSkipped: rowsSkipped,
      );
    } on PostgrestException catch (e) {
      throw ReferenceBarcodeException(_mapDbError(e));
    } catch (e) {
      if (e is ReferenceBarcodeException) rethrow;
      throw const ReferenceBarcodeException(
        'Gagal mengimpor database barcode. Coba lagi nanti.',
      );
    }
  }

  Future<ReferenceImportResult> importFromPicker() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
    );

    if (picked == null) {
      throw const ReferenceBarcodeException('Tidak ada file yang dipilih.');
    }

    final extension = (picked.extension ?? picked.path?.split('.').last ?? '')
        .toLowerCase();

    List<int> bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      throw const ReferenceBarcodeException(
        'File tidak bisa dibaca. Coba pilih ulang.',
      );
    }

    final rows = switch (extension) {
      'csv' => _parseCsvBytes(bytes),
      'xlsx' || 'xls' => _parseExcelBytes(bytes),
      _ => throw ReferenceBarcodeException(
        'Format .$extension belum didukung. Gunakan CSV atau XLSX.',
      ),
    };

    return importRows(rows);
  }

  List<ReferenceImportRow> _parseCsvBytes(List<int> bytes) {
    final content = String.fromCharCodes(bytes);
    final table = const CsvToListConverter().convert(content);
    return ReferenceImportParser.parseSpreadsheetRows(
      table.cast<List<dynamic>>(),
    );
  }

  List<ReferenceImportRow> _parseExcelBytes(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const ReferenceBarcodeException(
        'File Excel kosong atau tidak terbaca.',
      );
    }

    final sheet = excel.tables.values.first;
    final table = <List<dynamic>>[];
    for (final row in sheet.rows) {
      table.add(row.map((cell) => cell?.value).toList());
    }

    return ReferenceImportParser.parseSpreadsheetRows(table);
  }

  Future<String> _upsertItem({
    required String name,
    required String normalizedName,
  }) async {
    final existing = await _client
        .from(_itemsTable)
        .select('id')
        .eq('normalized_name', normalizedName)
        .maybeSingle();

    if (existing != null) {
      final id = existing['id'] as String;
      await _client.from(_itemsTable).update({'name': name}).eq('id', id);
      return id;
    }

    final inserted = await _client
        .from(_itemsTable)
        .insert({
          'name': name,
          'normalized_name': normalizedName,
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }

  Future<bool> _upsertBarcode({
    required String itemId,
    required String codeValue,
    required bool isPrimary,
  }) async {
    final normalized = ReferenceImportParser.normalizeCode(codeValue);
    if (normalized.isEmpty) return false;

    final existing = await _client
        .from(_barcodesTable)
        .select('id, item_id')
        .eq('code_value', normalized)
        .maybeSingle();

    if (existing != null) {
      final existingItemId = existing['item_id'] as String;
      if (existingItemId != itemId) {
        throw ReferenceBarcodeException(
          'Barcode $normalized sudah dipakai item lain di database global.',
        );
      }
      await _client
          .from(_barcodesTable)
          .update({'is_primary': isPrimary})
          .eq('id', existing['id']);
      return false;
    }

    await _client.from(_barcodesTable).insert({
      'item_id': itemId,
      'code_value': normalized,
      'is_primary': isPrimary,
    });
    return true;
  }

  String _mapDbError(PostgrestException error) {
    final combined =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''} ${error.code ?? ''}'
            .toLowerCase();

    if (combined.contains('relation') && combined.contains('does not exist')) {
      return 'Tabel database barcode belum siap. Push migrasi Supabase terbaru.';
    }
    if (combined.contains('23505') || combined.contains('duplicate key')) {
      return 'Ada barcode ganda di database. Periksa file Excel kamu.';
    }
    return 'Gagal memproses database barcode. Coba lagi nanti.';
  }
}
