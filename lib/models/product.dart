import 'package:sello/models/product_barcode.dart';
import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/models/product_image.dart';

class Product {
  const Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.codeType,
    this.codeValue,
    this.barcodes = const [],
    this.images = const [],
  });

  final String id;
  final String userId;
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final ProductBarcodeType? codeType;
  final String? codeValue;
  final List<ProductBarcode> barcodes;
  final List<ProductImage> images;

  bool get hasBarcode =>
      barcodes.isNotEmpty || (codeValue != null && codeValue!.trim().isNotEmpty);

  List<String> get allBarcodeValues {
    if (barcodes.isNotEmpty) {
      return barcodes.map((entry) => entry.codeValue).toList();
    }
    final primary = codeValue?.trim();
    if (primary == null || primary.isEmpty) return const [];
    return [primary];
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['product_images'];
    final images = rawImages is List
        ? rawImages
              .whereType<Map<String, dynamic>>()
              .map(ProductImage.fromJson)
              .toList()
        : <ProductImage>[];
    images.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rawBarcodes = json['product_barcodes'];
    final barcodes = rawBarcodes is List
        ? rawBarcodes
              .whereType<Map<String, dynamic>>()
              .map(ProductBarcode.fromJson)
              .toList()
        : <ProductBarcode>[];
    barcodes.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.codeValue.compareTo(b.codeValue);
    });

    ProductBarcode? primaryBarcode;
    for (final entry in barcodes) {
      if (entry.isPrimary) {
        primaryBarcode = entry;
        break;
      }
    }
    primaryBarcode ??= barcodes.isNotEmpty ? barcodes.first : null;

    return Product(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      costPrice: (json['cost_price'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num).toInt(),
      codeType: primaryBarcode?.codeType ??
          ProductBarcodeType.fromId(json['code_type'] as String?),
      codeValue: primaryBarcode?.codeValue ?? json['code_value'] as String?,
      barcodes: barcodes,
      images: images,
    );
  }

  Product copyWith({
    int? stock,
    List<ProductImage>? images,
    ProductBarcodeType? codeType,
    String? codeValue,
    List<ProductBarcode>? barcodes,
    bool clearBarcode = false,
  }) {
    return Product(
      id: id,
      userId: userId,
      name: name,
      price: price,
      costPrice: costPrice,
      stock: stock ?? this.stock,
      codeType: clearBarcode ? null : (codeType ?? this.codeType),
      codeValue: clearBarcode ? null : (codeValue ?? this.codeValue),
      barcodes: clearBarcode ? const [] : (barcodes ?? this.barcodes),
      images: images ?? this.images,
    );
  }
}
