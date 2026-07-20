import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/models/product.dart';

abstract final class BarcodeNormalizer {
  static String normalize(String raw) => raw.trim();

  static bool isEmpty(String? raw) =>
      raw == null || normalize(raw).isEmpty;

  /// Retail barcode umumnya numerik 8–14 digit.
  static ProductBarcodeType inferType(String raw) {
    final value = normalize(raw);
    if (RegExp(r'^\d{8}$').hasMatch(value) ||
        RegExp(r'^\d{12,14}$').hasMatch(value)) {
      return ProductBarcodeType.retail;
    }
    return ProductBarcodeType.code128;
  }

  static Product? findInCatalog(List<Product> catalog, String raw) {
    final needle = normalize(raw);
    if (needle.isEmpty) return null;

    for (final product in catalog) {
      for (final code in product.allBarcodeValues) {
        if (normalize(code) == needle) return product;
      }
    }
    return null;
  }
}
