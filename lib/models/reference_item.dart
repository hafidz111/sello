class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.name,
    required this.barcodeValues,
  });

  final String id;
  final String name;
  final List<String> barcodeValues;

  String? get primaryBarcode {
    for (final value in barcodeValues) {
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}
