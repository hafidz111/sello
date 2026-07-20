import 'dart:math';

import 'package:sello/core/constants/barcode_constants.dart';
import 'package:sello/models/product_barcode_type.dart';

abstract final class BarcodeGenerator {
  static final _random = Random();

  static String createInternalCode128() {
    final suffixLength =
        BarcodeConstants.internalCodeLength -
        BarcodeConstants.internalPrefix.length;
    final buffer = StringBuffer(BarcodeConstants.internalPrefix);
    for (var i = 0; i < suffixLength; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }

  static ProductBarcodeType get internalType => ProductBarcodeType.code128;
}
