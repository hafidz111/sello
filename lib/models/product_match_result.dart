import 'package:sello/models/product.dart';

class ProductMatchResult {
  const ProductMatchResult({
    required this.productId,
    required this.productName,
    required this.confidence,
    required this.isMatched,
    this.matchedProduct,
  });

  final String? productId;

  final String productName;
  final double confidence;
  final bool isMatched;
  final Product? matchedProduct;

  int get confidencePercent => (confidence * 100).round().clamp(0, 100);

  factory ProductMatchResult.fromJson(
    Map<String, dynamic> json, {
    Product? matchedProduct,
  }) {
    final rawId = json['matched_product_id'];
    final productId = rawId is String && rawId.trim().isNotEmpty
        ? rawId.trim()
        : null;

    return ProductMatchResult(
      productId: productId,
      productName: _readString(json['product_name'], fallback: 'Tidak dikenal'),
      confidence: _readConfidence(json['confidence']),
      isMatched: json['is_matched'] == true,
      matchedProduct: matchedProduct,
    );
  }

  static String _readString(Object? value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static double _readConfidence(Object? value) {
    if (value is num) return value.toDouble().clamp(0.0, 1.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed.clamp(0.0, 1.0);
    }
    return 0.0;
  }
}
