class ProductImage {
  const ProductImage({
    required this.id,
    required this.productId,
    required this.storagePath,
    required this.angleLabel,
    required this.sortOrder,
    this.publicUrl,
  });

  final String id;
  final String productId;
  final String storagePath;
  final String angleLabel;
  final int sortOrder;
  final String? publicUrl;

  factory ProductImage.fromJson(
    Map<String, dynamic> json, {
    String? publicUrl,
  }) {
    return ProductImage(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      storagePath: json['storage_path'] as String,
      angleLabel: json['angle_label'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      publicUrl: publicUrl,
    );
  }
}
