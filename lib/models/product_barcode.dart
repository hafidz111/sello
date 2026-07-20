import 'package:sello/models/product_barcode_type.dart';

class ProductBarcode {
  const ProductBarcode({
    required this.id,
    required this.productId,
    required this.userId,
    required this.codeValue,
    required this.codeType,
    required this.isPrimary,
  });

  final String id;
  final String productId;
  final String userId;
  final String codeValue;
  final ProductBarcodeType codeType;
  final bool isPrimary;

  factory ProductBarcode.fromJson(Map<String, dynamic> json) {
    return ProductBarcode(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      codeValue: json['code_value'] as String,
      codeType: ProductBarcodeType.fromId(json['code_type'] as String?) ??
          ProductBarcodeType.retail,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}
