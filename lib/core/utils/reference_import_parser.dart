import 'package:sello/models/reference_import_row.dart';

abstract final class ReferenceImportParser {
  static String normalizeName(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizeCode(String raw) => raw.trim();

  /// Excel/CSV columns: A item, B barcode, C flag (not empty = alt), D alt barcode.
  static ReferenceImportRow? parseSpreadsheetRow(List<dynamic> cells) {
    final item = _cellText(cells, 0);
    final primary = _cellText(cells, 1);
    final flag = _cellText(cells, 2);
    final alternate = _cellText(cells, 3);

    if (item.isEmpty || primary.isEmpty) return null;

    final hasAlternate = flag.isNotEmpty && alternate.isNotEmpty;

    return ReferenceImportRow(
      name: item,
      primaryBarcode: primary,
      alternateBarcode: hasAlternate ? alternate : null,
    );
  }

  static List<ReferenceImportRow> parseSpreadsheetRows(
    List<List<dynamic>> rows, {
    bool skipHeader = true,
  }) {
    final parsed = <ReferenceImportRow>[];
    for (var i = 0; i < rows.length; i++) {
      if (skipHeader && i == 0 && _looksLikeHeader(rows[i])) continue;
      final row = parseSpreadsheetRow(rows[i]);
      if (row != null) parsed.add(row);
    }
    return parsed;
  }

  static bool _looksLikeHeader(List<dynamic> cells) {
    final joined = cells.map(_cellTextFromDynamic).join(' ').toLowerCase();
    return joined.contains('item') ||
        joined.contains('barcode') ||
        joined.contains('nama');
  }

  static String _cellText(List<dynamic> cells, int index) {
    if (index >= cells.length) return '';
    return _cellTextFromDynamic(cells[index]);
  }

  static String _cellTextFromDynamic(dynamic raw) {
    if (raw == null) return '';
    if (raw is num && raw == raw.roundToDouble()) {
      return raw.toInt().toString();
    }
    return raw.toString().trim();
  }
}
