/// Satu baris item penjualan hasil ekstraksi AI dari kalimat natural.
class SaleItem {
  const SaleItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  /// Nama produk, mis. "Keripik Singkong".
  final String name;

  /// Jumlah yang terjual (pcs). Minimal 1.
  final int quantity;

  /// Harga satuan dalam Rupiah. 0 bila AI tidak menemukan harga.
  final int unitPrice;

  /// Total untuk baris ini (quantity * unitPrice).
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
      };

  SaleItem copyWith({String? name, int? quantity, int? unitPrice}) {
    return SaleItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  /// Menerima int, double, atau String angka dari respons AI.
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
