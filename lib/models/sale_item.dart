class SaleItem {
  const SaleItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.matchedFromCatalog = false,
    this.matchScore,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final String? productId;
  final bool matchedFromCatalog;
  final double? matchScore;

  int get subtotal => quantity * unitPrice;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Item',
      quantity: _asInt(json['quantity'], fallback: 1),
      unitPrice: _asInt(json['unit_price'], fallback: 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    if (productId != null) 'product_id': productId,
  };

  SaleItem copyWith({
    String? name,
    int? quantity,
    int? unitPrice,
    String? productId,
    bool? matchedFromCatalog,
    double? matchScore,
  }) {
    return SaleItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      productId: productId ?? this.productId,
      matchedFromCatalog: matchedFromCatalog ?? this.matchedFromCatalog,
      matchScore: matchScore ?? this.matchScore,
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
