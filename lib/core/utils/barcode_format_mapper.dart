import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sello/models/product_barcode_type.dart';

abstract final class BarcodeFormatMapper {
  static ProductBarcodeType resolve(BarcodeFormat? format) {
    return switch (format) {
      BarcodeFormat.ean13 ||
      BarcodeFormat.ean8 ||
      BarcodeFormat.upcA ||
      BarcodeFormat.upcE =>
        ProductBarcodeType.retail,
      _ => ProductBarcodeType.code128,
    };
  }
}
