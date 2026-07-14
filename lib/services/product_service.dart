import 'dart:typed_data';

import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/models/dashboard_stats.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductException implements Exception {
  const ProductException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class ProductPhotoAngle {
  static const front = 'front';
  static const side = 'side';
  static const label = 'label';

  static const all = [front, side, label];

  static String labelFor(String angle) => switch (angle) {
    front => 'Depan',
    side => 'Samping',
    label => 'Label',
    _ => angle,
  };
}

class ProductService {
  ProductService._();

  static final ProductService instance = ProductService._();

  static const _bucket = 'product-images';
  static const _matchConfidenceThreshold = 0.65;
  static const _signedUrlSeconds = 3600;

  SupabaseClient get _client => SupabaseConfig.client;

  double get matchConfidenceThreshold => _matchConfidenceThreshold;

  Future<List<Product>> fetchProducts(String userId) async {
    try {
      final rows = await _client
          .from('products')
          .select('*, product_images(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final products = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();

      final withUrls = <Product>[];
      for (final product in products) {
        withUrls.add(
          product.copyWith(images: await _withSignedUrls(product)),
        );
      }
      return withUrls;
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException(
        'Gagal memuat daftar produk. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<Product> createProduct({
    required String userId,
    required String name,
    required int price,
    required int stock,
    required Map<String, Uint8List> imagesByAngle,
  }) async {
    if (name.trim().isEmpty) {
      throw const ProductException('Nama produk wajib diisi.');
    }
    if (imagesByAngle.isEmpty) {
      throw const ProductException('Ambil minimal satu foto referensi produk.');
    }

    try {
      final productRow = await _client
          .from('products')
          .insert({
            'user_id': userId,
            'name': name.trim(),
            'price': price,
            'stock': stock,
          })
          .select()
          .single();

      final productId = productRow['id'] as String;
      final imageRows = <Map<String, dynamic>>[];

      var sortOrder = 0;
      for (final entry in imagesByAngle.entries) {
        final angle = entry.key;
        final bytes = entry.value;
        final path = '$userId/$productId/$angle.jpg';

        await _client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        imageRows.add({
          'product_id': productId,
          'storage_path': path,
          'angle_label': angle,
          'sort_order': sortOrder,
        });
        sortOrder++;
      }

      await _client.from('product_images').insert(imageRows);

      final full = await _client
          .from('products')
          .select('*, product_images(*)')
          .eq('id', productId)
          .single();

      final product = Product.fromJson(full);
      return product.copyWith(images: await _withSignedUrls(product));
    } on StorageException {
      throw const ProductException(
        'Gagal mengunggah foto produk. Pastikan bucket product-images sudah dibuat di Supabase.',
      );
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal menyimpan produk. Coba lagi.');
    }
  }

  Future<void> recordSale({
    required String userId,
    required Product product,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw const ProductException('Jumlah penjualan minimal 1.');
    }

    final total = product.price * quantity;
    final newStock = product.stock - quantity;

    try {
      await _client.from('sales').insert({
        'user_id': userId,
        'product_id': product.id,
        'quantity': quantity,
        'unit_price': product.price,
        'total': total,
      });

      await _client
          .from('products')
          .update({'stock': newStock < 0 ? 0 : newStock})
          .eq('id', product.id);
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal mencatat penjualan. Coba lagi.');
    }
  }

  static const _lowStockThreshold = 5;

  Product? findById(List<Product> catalog, String? productId) {
    if (productId == null) return null;
    for (final product in catalog) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<DashboardStats> fetchDashboardStats(String userId) async {
    try {
      final products = await fetchProducts(userId);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final salesRows = await _client
          .from('sales')
          .select('total')
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String());

      var todayTotal = 0;
      var todayCount = 0;
      for (final row in salesRows as List) {
        if (row is Map<String, dynamic>) {
          todayTotal += (row['total'] as num?)?.toInt() ?? 0;
          todayCount++;
        }
      }

      final lowStock = products
          .where((p) => p.stock <= _lowStockThreshold)
          .length;

      return DashboardStats(
        todaySalesTotal: todayTotal,
        todayTransactionCount: todayCount,
        activeProductCount: products.length,
        lowStockCount: lowStock,
      );
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal memuat ringkasan beranda.');
    }
  }

  Future<List<ProductImage>> _withSignedUrls(Product product) async {
    final images = <ProductImage>[];
    for (final image in product.images) {
      String? url;
      try {
        url = await _client.storage
            .from(_bucket)
            .createSignedUrl(image.storagePath, _signedUrlSeconds);
      } on StorageException {
        url = null;
      }

      images.add(
        ProductImage(
          id: image.id,
          productId: image.productId,
          storagePath: image.storagePath,
          angleLabel: image.angleLabel,
          sortOrder: image.sortOrder,
          publicUrl: url,
        ),
      );
    }
    return images;
  }

  String _mapDbError(PostgrestException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('relation') && msg.contains('does not exist')) {
      return 'Tabel database belum dibuat. Push migrasi supabase/migrations/ ke GitHub.';
    }
    if (msg.contains('row-level security') || msg.contains('rls')) {
      return 'Akses data ditolak. Pastikan kamu sudah masuk dan '
          'integrasi Firebase Auth di Supabase sudah diaktifkan.';
    }
    return 'Terjadi kesalahan database. Coba lagi nanti.';
  }
}
