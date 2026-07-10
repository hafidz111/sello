import 'package:sello/models/product_image.dart';

class Product {
  const Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.stock,
    this.images = const [],
  });

  final String id;
  final String userId;
  final String name;
  final int price;
  final int stock;
  final List<ProductImage> images;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['product_images'];
    final images = rawImages is List
        ? rawImages
              .whereType<Map<String, dynamic>>()
              .map(ProductImage.fromJson)
              .toList()
        : <ProductImage>[];
    images.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Product(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      stock: (json['stock'] as num).toInt(),
      images: images,
    );
  }

  Product copyWith({int? stock, List<ProductImage>? images}) {
    return Product(
      id: id,
      userId: userId,
      name: name,
      price: price,
      stock: stock ?? this.stock,
      images: images ?? this.images,
    );
  }
}
