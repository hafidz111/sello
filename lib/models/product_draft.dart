class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.notes = '',
  });

  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final String notes;

  factory ProductDraft.fromJson(Map<String, dynamic> json) {
    return ProductDraft(
      name: (json['name'] as String?)?.trim() ?? '',
      price: _asInt(json['price'], fallback: 0),
      costPrice: _asInt(json['cost_price'], fallback: 0),
      stock: _asInt(json['stock'], fallback: 0),
      notes: (json['notes'] as String?)?.trim() ?? '',
    );
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) return int.parse(digits);
    }
    return fallback;
  }
}
