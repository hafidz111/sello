class ReferenceImportRow {
  const ReferenceImportRow({
    required this.name,
    required this.primaryBarcode,
    this.alternateBarcode,
  });

  final String name;
  final String primaryBarcode;
  final String? alternateBarcode;

  List<String> get allBarcodes {
    final values = <String>[primaryBarcode];
    final alt = alternateBarcode?.trim();
    if (alt != null && alt.isNotEmpty && alt != primaryBarcode) {
      values.add(alt);
    }
    return values;
  }
}

class ReferenceImportResult {
  const ReferenceImportResult({
    required this.itemsImported,
    required this.barcodesImported,
    required this.rowsSkipped,
  });

  final int itemsImported;
  final int barcodesImported;
  final int rowsSkipped;
}
