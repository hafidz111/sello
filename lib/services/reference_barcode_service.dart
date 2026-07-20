import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/core/utils/barcode_normalizer.dart';
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
    final normalized = BarcodeNormalizer.normalize(codeValue);
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

  String _mapDbError(PostgrestException error) {
    final combined =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''} ${error.code ?? ''}'
            .toLowerCase();

    if (combined.contains('relation') && combined.contains('does not exist')) {
      return 'Tabel database barcode belum siap. Push migrasi Supabase terbaru.';
    }
    return 'Gagal memproses database barcode. Coba lagi nanti.';
  }
}
