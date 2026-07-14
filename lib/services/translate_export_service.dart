import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sello/core/utils/currency.dart';
import 'package:sello/models/export_language.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_translation_bundle.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/services/product_service.dart';

class TranslateExportException implements Exception {
  const TranslateExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TranslateExportService {
  TranslateExportService._();

  static final TranslateExportService instance = TranslateExportService._();

  final _productService = ProductService.instance;
  final _aiService = AiService.instance;

  Future<List<Product>> loadProducts(String userId) async {
    try {
      return await _productService.fetchProducts(userId);
    } on ProductException catch (e) {
      throw TranslateExportException(e.message);
    } catch (_) {
      throw const TranslateExportException(
        'Gagal memuat katalog produk. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<ProductTranslationBundle> translateProduct({
    required Product product,
    String sourceNotes = '',
  }) async {
    if (!_aiService.isConfigured) {
      throw const TranslateExportException(
        'GEMINI_API_KEY belum diisi. Tambahkan kunci AI di file .env.',
      );
    }

    try {
      final locales = await _aiService.translateProductCopy(
        productName: product.name,
        priceIdr: product.price,
        stock: product.stock,
        sourceNotes: sourceNotes,
      );

      return ProductTranslationBundle(
        product: product,
        sourceNotes: sourceNotes.trim(),
        locales: locales,
        createdAt: DateTime.now(),
      );
    } on AiException catch (e) {
      throw TranslateExportException(e.message);
    } catch (_) {
      throw const TranslateExportException(
        'Gagal menerjemahkan produk. Coba lagi nanti.',
      );
    }
  }

  /// Fallback lokal tanpa AI (bila user hanya mau skema dasar ID).
  ProductTranslationBundle buildLocalFallback({
    required Product product,
    String sourceNotes = '',
  }) {
    final notes = sourceNotes.trim();
    final idDescription = notes.isEmpty
        ? '${product.name}. Harga ${formatRupiah(product.price)}. Stok ${product.stock} pcs.'
        : '${product.name}. $notes Harga ${formatRupiah(product.price)}.';

    LocalizedProductCopy locale(ExportLanguage language, String title, String description) {
      return LocalizedProductCopy(
        language: language,
        title: title,
        description: description,
        tags: [product.name, 'umkm', 'produk'],
      );
    }

    return ProductTranslationBundle(
      product: product,
      sourceNotes: notes,
      locales: {
        ExportLanguage.id: locale(ExportLanguage.id, product.name, idDescription),
        ExportLanguage.en: locale(
          ExportLanguage.en,
          product.name,
          '${product.name}. Price ${formatRupiah(product.price)}. Stock ${product.stock} pcs.',
        ),
        ExportLanguage.ar: locale(
          ExportLanguage.ar,
          product.name,
          '${product.name}. السعر ${product.price} روبية. المخزون ${product.stock}.',
        ),
        ExportLanguage.zh: locale(
          ExportLanguage.zh,
          product.name,
          '${product.name}。价格 ${product.price} 印尼盾。库存 ${product.stock} 件。',
        ),
      },
      createdAt: DateTime.now(),
    );
  }

  Future<void> shareJson(ProductTranslationBundle bundle) async {
    final dir = await getTemporaryDirectory();
    final safeName = bundle.product.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final file = File(
      '${dir.path}/sello_product_${safeName.isEmpty ? bundle.product.id : safeName}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(bundle.toExportJson()),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Ekspor produk ${bundle.product.name}',
        text: 'Skema ekspor produk Sello (JSON)',
      ),
    );
  }

  Future<void> shareText(ProductTranslationBundle bundle) async {
    final dir = await getTemporaryDirectory();
    final safeName = bundle.product.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final file = File(
      '${dir.path}/sello_product_${safeName.isEmpty ? bundle.product.id : safeName}.txt',
    );
    await file.writeAsString(bundle.toMarketplaceText());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: 'Deskripsi produk ${bundle.product.name}',
        text: 'Ekspor teks marketplace Sello',
      ),
    );
  }
}
