import 'dart:typed_data';

import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/core/constants/stock_constants.dart';
import 'package:sello/core/utils/barcode_generator.dart';
import 'package:sello/core/utils/barcode_normalizer.dart';
import 'package:sello/models/dashboard_stats.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_barcode_type.dart';
import 'package:sello/models/product_image.dart';
import 'package:sello/services/stock_alert_service.dart';
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
  static const _barcodesTable = 'product_barcodes';
  static const _productSelect = '*, product_images(*), product_barcodes(*)';
  static const _matchConfidenceThreshold = 0.65;
  static const _signedUrlSeconds = 3600;

  SupabaseClient get _client => SupabaseConfig.client;

  double get matchConfidenceThreshold => _matchConfidenceThreshold;

  Future<List<Product>> fetchProducts(String userId) async {
    try {
      final rows = await _client
          .from('products')
          .select(_productSelect)
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

  Future<Product?> fetchProductById({
    required String userId,
    required String productId,
  }) async {
    try {
      final row = await _client
          .from('products')
          .select(_productSelect)
          .eq('user_id', userId)
          .eq('id', productId)
          .maybeSingle();

      if (row == null) return null;
      final product = Product.fromJson(row);
      return product.copyWith(images: await _withSignedUrls(product));
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal memuat detail produk.');
    }
  }

  Future<Product?> findProductByCode({
    required String userId,
    required String codeValue,
  }) async {
    final normalized = BarcodeNormalizer.normalize(codeValue);
    if (normalized.isEmpty) return null;

    try {
      final barcodeRow = await _client
          .from(_barcodesTable)
          .select('product_id')
          .eq('user_id', userId)
          .eq('code_value', normalized)
          .maybeSingle();

      final productId = barcodeRow?['product_id'] as String?;
      Map<String, dynamic>? row;

      if (productId != null) {
        row = await _client
            .from('products')
            .select(_productSelect)
            .eq('user_id', userId)
            .eq('id', productId)
            .maybeSingle();
      } else {
        row = await _client
            .from('products')
            .select(_productSelect)
            .eq('user_id', userId)
            .eq('code_value', normalized)
            .maybeSingle();
      }

      if (row == null) return null;
      final product = Product.fromJson(row);
      return product.copyWith(images: await _withSignedUrls(product));
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal mencari produk dari barcode.');
    }
  }

  Product? findProductByCodeInCatalog(List<Product> catalog, String codeValue) {
    return BarcodeNormalizer.findInCatalog(catalog, codeValue);
  }

  Future<Product> updateProduct({
    required String userId,
    required String productId,
    required String name,
    required int price,
    required int costPrice,
    required int stock,
    ProductBarcodeType? codeType,
    String? codeValue,
    String? alternateCodeValue,
    ProductBarcodeType? alternateCodeType,
    bool clearBarcode = false,
    Map<String, Uint8List> newImagesByAngle = const {},
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ProductException('Nama produk wajib diisi.');
    }
    if (price < 0 || costPrice < 0 || stock < 0) {
      throw const ProductException(
        'Harga jual, modal, dan stok tidak boleh negatif.',
      );
    }

    final barcodeEntries = _buildBarcodeEntries(
      codeType: codeType,
      codeValue: codeValue,
      alternateCodeType: alternateCodeType,
      alternateCodeValue: alternateCodeValue,
      clearBarcode: clearBarcode,
    );
    if (barcodeEntries != null) {
      await _ensureUniqueBarcodes(
        userId: userId,
        entries: barcodeEntries,
        excludeProductId: productId,
      );
    }

    try {
      final updatePayload = <String, dynamic>{
        'name': trimmed,
        'price': price,
        'cost_price': costPrice,
        'stock': stock,
      };
      if (clearBarcode) {
        updatePayload['code_type'] = null;
        updatePayload['code_value'] = null;
      } else if (barcodeEntries != null && barcodeEntries.isNotEmpty) {
        final primary = barcodeEntries.firstWhere((entry) => entry.isPrimary);
        updatePayload['code_type'] = primary.codeType.id;
        updatePayload['code_value'] = primary.codeValue;
      }

      await _client
          .from('products')
          .update(updatePayload)
          .eq('id', productId)
          .eq('user_id', userId);

      if (clearBarcode) {
        await _client
            .from(_barcodesTable)
            .delete()
            .eq('product_id', productId)
            .eq('user_id', userId);
      } else if (barcodeEntries != null) {
        await _replaceProductBarcodes(
          userId: userId,
          productId: productId,
          entries: barcodeEntries,
        );
      }

      if (newImagesByAngle.isNotEmpty) {
        final existing = await _client
            .from('product_images')
            .select('id, angle_label, sort_order')
            .eq('product_id', productId);

        final byAngle = <String, Map<String, dynamic>>{};
        for (final row in existing as List) {
          if (row is Map<String, dynamic>) {
            final angle = row['angle_label'] as String?;
            if (angle != null) byAngle[angle] = row;
          }
        }

        var nextSort = byAngle.values.fold<int>(
          0,
          (max, row) {
            final order = (row['sort_order'] as num?)?.toInt() ?? 0;
            return order >= max ? order + 1 : max;
          },
        );

        for (final entry in newImagesByAngle.entries) {
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

          final current = byAngle[angle];
          if (current != null) {
            await _client
                .from('product_images')
                .update({
                  'storage_path': path,
                  'angle_label': angle,
                })
                .eq('id', current['id']);
          } else {
            await _client.from('product_images').insert({
              'product_id': productId,
              'storage_path': path,
              'angle_label': angle,
              'sort_order': nextSort,
            });
            nextSort++;
          }
        }
      }

      final updated = await fetchProductById(
        userId: userId,
        productId: productId,
      );
      if (updated == null) {
        throw const ProductException('Produk tidak ditemukan setelah diubah.');
      }
      return updated;
    } on ProductException {
      rethrow;
    } on StorageException {
      throw const ProductException(
        'Gagal mengunggah foto produk. Coba lagi nanti.',
      );
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal memperbarui produk. Coba lagi.');
    }
  }

  Future<void> deleteProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final sales = await _client
          .from('sales')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .limit(1);

      if ((sales as List).isNotEmpty) {
        throw const ProductException(
          'Produk tidak bisa dihapus karena sudah ada di catatan penjualan. '
          'Kamu masih bisa mengubah data atau stoknya.',
        );
      }

      final images = await _client
          .from('product_images')
          .select('storage_path')
          .eq('product_id', productId);

      final paths = (images as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['storage_path'] as String?)
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList();

      if (paths.isNotEmpty) {
        try {
          await _client.storage.from(_bucket).remove(paths);
        } on StorageException {
          // Lanjut hapus baris produk meskipun file storage gagal dibersihkan.
        }
      }

      await _client
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('user_id', userId);
    } on ProductException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal menghapus produk. Coba lagi.');
    }
  }

  Future<Product> createProduct({
    required String userId,
    required String name,
    required int price,
    required int costPrice,
    required int stock,
    required Map<String, Uint8List> imagesByAngle,
    ProductBarcodeType? codeType,
    String? codeValue,
    String? alternateCodeValue,
    ProductBarcodeType? alternateCodeType,
    bool autoGenerateBarcode = true,
  }) async {
    if (name.trim().isEmpty) {
      throw const ProductException('Nama produk wajib diisi.');
    }
    if (imagesByAngle.isEmpty) {
      throw const ProductException('Ambil minimal satu foto referensi produk.');
    }
    if (costPrice < 0) {
      throw const ProductException('Harga modal tidak boleh negatif.');
    }

    var barcodeEntries = _buildBarcodeEntries(
      codeType: codeType,
      codeValue: codeValue,
      alternateCodeType: alternateCodeType,
      alternateCodeValue: alternateCodeValue,
    );

    if ((barcodeEntries == null || barcodeEntries.isEmpty) &&
        autoGenerateBarcode) {
      final generated = await _generateUniqueInternalBarcode(userId: userId);
      barcodeEntries = [
        _BarcodeEntry(
          codeType: generated.codeType,
          codeValue: generated.codeValue,
          isPrimary: true,
        ),
      ];
    } else if (barcodeEntries != null && barcodeEntries.isNotEmpty) {
      await _ensureUniqueBarcodes(
        userId: userId,
        entries: barcodeEntries,
      );
    }

    try {
      final insertPayload = <String, dynamic>{
        'user_id': userId,
        'name': name.trim(),
        'price': price,
        'cost_price': costPrice,
        'stock': stock,
      };
      if (barcodeEntries != null && barcodeEntries.isNotEmpty) {
        final primary = barcodeEntries.firstWhere((entry) => entry.isPrimary);
        insertPayload['code_type'] = primary.codeType.id;
        insertPayload['code_value'] = primary.codeValue;
      }

      final productRow = await _client
          .from('products')
          .insert(insertPayload)
          .select()
          .single();

      final productId = productRow['id'] as String;

      if (barcodeEntries != null && barcodeEntries.isNotEmpty) {
        await _replaceProductBarcodes(
          userId: userId,
          productId: productId,
          entries: barcodeEntries,
        );
      }
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
          .select(_productSelect)
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
    String? customerName,
  }) async {
    if (quantity <= 0) {
      throw const ProductException('Jumlah penjualan minimal 1.');
    }

    final total = product.price * quantity;
    final previousStock = product.stock;
    final newStock = previousStock - quantity;
    final trimmedCustomer = customerName?.trim();
    final clampedStock = newStock < 0 ? 0 : newStock;

    try {
      await _client.from('sales').insert({
        'user_id': userId,
        'product_id': product.id,
        'quantity': quantity,
        'unit_price': product.price,
        'unit_cost': product.costPrice,
        'total': total,
        if (trimmedCustomer != null && trimmedCustomer.isNotEmpty)
          'customer_name': trimmedCustomer,
      });

      await _client
          .from('products')
          .update({'stock': clampedStock})
          .eq('id', product.id);
    } on PostgrestException catch (e) {
      throw ProductException(_mapDbError(e));
    } catch (_) {
      throw const ProductException('Gagal mencatat penjualan. Coba lagi.');
    }

    try {
      await StockAlertService.instance.notifyIfLowAfterSale(
        userId: userId,
        productId: product.id,
        productName: product.name,
        previousStock: previousStock,
        newStock: clampedStock,
      );
    } catch (_) {
      // Penjualan sudah tersimpan; notifikasi gagal tidak membatalkan transaksi.
    }
  }

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
          .where((p) => p.stock <= StockConstants.lowStockThreshold)
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

  Future<({ProductBarcodeType codeType, String codeValue})>
  _generateUniqueInternalBarcode({
    required String userId,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = BarcodeGenerator.createInternalCode128();
      final inBarcodes = await _client
          .from(_barcodesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('code_value', candidate)
          .maybeSingle();
      if (inBarcodes != null) continue;

      final inProducts = await _client
          .from('products')
          .select('id')
          .eq('user_id', userId)
          .eq('code_value', candidate)
          .maybeSingle();
      if (inProducts == null) {
        return (
          codeType: BarcodeGenerator.internalType,
          codeValue: candidate,
        );
      }
    }
    throw const ProductException(
      'Gagal membuat barcode otomatis. Coba lagi atau scan barcode manual.',
    );
  }

  List<_BarcodeEntry>? _buildBarcodeEntries({
    ProductBarcodeType? codeType,
    String? codeValue,
    ProductBarcodeType? alternateCodeType,
    String? alternateCodeValue,
    bool clearBarcode = false,
  }) {
    if (clearBarcode) return null;

    final primary = BarcodeNormalizer.normalize(codeValue ?? '');
    if (primary.isEmpty) return null;

    final entries = <_BarcodeEntry>[
      _BarcodeEntry(
        codeType: codeType ?? BarcodeNormalizer.inferType(primary),
        codeValue: primary,
        isPrimary: true,
      ),
    ];

    final alternate = BarcodeNormalizer.normalize(alternateCodeValue ?? '');
    if (alternate.isNotEmpty && alternate != primary) {
      entries.add(
        _BarcodeEntry(
          codeType: alternateCodeType ?? BarcodeNormalizer.inferType(alternate),
          codeValue: alternate,
          isPrimary: false,
        ),
      );
    }

    return entries;
  }

  Future<void> _replaceProductBarcodes({
    required String userId,
    required String productId,
    required List<_BarcodeEntry> entries,
  }) async {
    await _client
        .from(_barcodesTable)
        .delete()
        .eq('product_id', productId)
        .eq('user_id', userId);

    if (entries.isEmpty) return;

    await _client.from(_barcodesTable).insert(
      entries
          .map(
            (entry) => {
              'product_id': productId,
              'user_id': userId,
              'code_value': entry.codeValue,
              'code_type': entry.codeType.id,
              'is_primary': entry.isPrimary,
            },
          )
          .toList(),
    );
  }

  Future<void> _ensureUniqueBarcodes({
    required String userId,
    required List<_BarcodeEntry> entries,
    String? excludeProductId,
  }) async {
    for (final entry in entries) {
      final normalized = BarcodeNormalizer.normalize(entry.codeValue);
      if (normalized.isEmpty) continue;

      final row = await _client
          .from(_barcodesTable)
          .select('product_id, code_value')
          .eq('user_id', userId)
          .eq('code_value', normalized)
          .maybeSingle();

      if (row != null) {
        final existingProductId = row['product_id'] as String?;
        if (excludeProductId != null && existingProductId == excludeProductId) {
          continue;
        }
        throw ProductException(
          'Barcode $normalized sudah dipakai produk lain di toko kamu.',
        );
      }

      final legacy = await _client
          .from('products')
          .select('id, name')
          .eq('user_id', userId)
          .eq('code_value', normalized)
          .maybeSingle();

      if (legacy != null) {
        final existingId = legacy['id'] as String?;
        if (excludeProductId != null && existingId == excludeProductId) continue;
        final existingName = legacy['name'] as String? ?? 'produk lain';
        throw ProductException(
          'Barcode $normalized sudah dipakai oleh "$existingName".',
        );
      }
    }
  }

  String _mapDbError(PostgrestException error) {
    final msg = error.message.toLowerCase();
    final details = '${error.details ?? ''} ${error.hint ?? ''}'.toLowerCase();
    final combined = '$msg $details ${error.code ?? ''}';

    if (combined.contains('relation') && combined.contains('does not exist')) {
      return 'Tabel database belum dibuat. Push migrasi supabase/migrations/ ke GitHub.';
    }
    if (combined.contains('22p02') ||
        (combined.contains('invalid input syntax') &&
            combined.contains('uuid'))) {
      return 'Identitas pengguna tidak cocok dengan format database. '
          'Pastikan migrasi perbaikan Firebase UID sudah diterapkan di Supabase.';
    }
    if (combined.contains('jwt') ||
        combined.contains('unauthorized') ||
        combined.contains('pgrst301') ||
        error.code == 'PGRST301') {
      return 'Sesi autentikasi ditolak database. Pastikan kamu sudah masuk '
          'dan Firebase Auth sudah dihubungkan di Supabase '
          '(Authentication → Third-party Auth → Firebase, Project ID sello-62633).';
    }
    if (combined.contains('row-level security') ||
        combined.contains('rls') ||
        combined.contains('42501') ||
        combined.contains('permission denied') ||
        combined.contains('violates row-level')) {
      return 'Akses data ditolak. Pastikan kamu sudah masuk dan '
          'integrasi Firebase Auth di Supabase sudah diaktifkan.';
    }
    if (combined.contains('23505') ||
        combined.contains('duplicate key') ||
        combined.contains('products_user_code_value_uidx')) {
      return 'Barcode sudah dipakai produk lain di toko kamu. '
          'Gunakan barcode yang berbeda.';
    }
    if (combined.contains('code_type') ||
        combined.contains('code_value') ||
        combined.contains('product_barcodes') ||
        combined.contains('reference_barcodes') ||
        combined.contains('42703')) {
      return 'Kolom barcode belum siap. Push migrasi barcode ke Supabase.';
    }
    return 'Terjadi kesalahan database. Coba lagi nanti.';
  }
}

class _BarcodeEntry {
  const _BarcodeEntry({
    required this.codeType,
    required this.codeValue,
    required this.isPrimary,
  });

  final ProductBarcodeType codeType;
  final String codeValue;
  final bool isPrimary;
}
