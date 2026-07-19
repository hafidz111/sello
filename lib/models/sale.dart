class Sale {
  const Sale({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.total,
    required this.createdAt,
    this.customerName,
  });

  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int unitCost;
  final int total;
  final String? customerName;
  final DateTime createdAt;

  factory Sale.fromJson(Map<String, dynamic> json) {
    final product = json['products'];
    final productName = product is Map<String, dynamic>
        ? (product['name'] as String?)?.trim().isNotEmpty == true
            ? (product['name'] as String).trim()
            : 'Produk'
        : 'Produk';

    return Sale(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      productName: productName,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toInt(),
      unitCost: (json['unit_cost'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num).toInt(),
      customerName: (json['customer_name'] as String?)?.trim().isNotEmpty == true
          ? (json['customer_name'] as String).trim()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Sale copyWith({
    int? quantity,
    int? total,
    String? customerName,
  }) {
    return Sale(
      id: id,
      userId: userId,
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      unitCost: unitCost,
      total: total ?? this.total,
      customerName: customerName ?? this.customerName,
      createdAt: createdAt,
    );
  }
}
