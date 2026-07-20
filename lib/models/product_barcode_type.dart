enum ProductBarcodeType {
  retail,
  code128;

  String get id => name;

  String get label => switch (this) {
    retail => 'Barcode kemasan',
    code128 => 'Code 128 toko',
  };

  static ProductBarcodeType? fromId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final type in ProductBarcodeType.values) {
      if (type.id == raw) return type;
    }
    return null;
  }
}
