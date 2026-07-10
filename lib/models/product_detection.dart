class ProductDetection {
  const ProductDetection({
    required this.productName,
    required this.category,
    required this.description,
    required this.confidence,
  });

  final String productName;
  final String category;
  final String description;
  final double confidence;

  int get confidencePercent => (confidence * 100).round().clamp(0, 100);

  factory ProductDetection.fromJson(Map<String, dynamic> json) {
    return ProductDetection(
      productName: _readString(
        json['product_name'],
        fallback: 'Produk tidak dikenal',
      ),
      category: _readString(json['category'], fallback: 'Umum'),
      description: _readString(json['description'], fallback: ''),
      confidence: _readConfidence(json['confidence']),
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
