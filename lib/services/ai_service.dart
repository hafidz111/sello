import 'dart:convert';
import 'dart:typed_data';

import 'package:sello/core/config/env.dart';
import 'package:sello/core/constants/gemini_schemas.dart';
import 'package:sello/core/network/network_exception.dart';
import 'package:sello/core/utils/catalog_fuzzy_matcher.dart';
import 'package:sello/models/education_guide.dart';
import 'package:sello/models/export_language.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_detection.dart';
import 'package:sello/models/product_draft.dart';
import 'package:sello/models/product_match_result.dart';
import 'package:sello/models/product_translation_bundle.dart';
import 'package:sello/models/sale_item.dart';
import 'package:sello/services/gemini_api_service.dart';

class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  final _geminiApi = GeminiApiService.instance;

  bool get isConfigured => Env.hasGeminiApiKey;

  /// Prompt singkat untuk kasir jualan (jumlah + nama, harga opsional).
  Future<List<SaleItem>> extractSale(
    String text, {
    List<Product> catalog = const [],
  }) async {
    _ensureConfigured();

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AiException('Teks penjualan masih kosong.');
    }

    final catalogHint = catalog.isEmpty
        ? ''
        : '\nNama produk di katalog toko (pacu pengenalan nama, jangan menambah item):\n'
            '${catalog.map((p) => '- ${p.name}').join('\n')}';

    final raw = await _callGemini(
      () => _geminiApi.createTextInteraction(
        input: trimmed,
        systemInstruction:
            'Kamu asisten kasir UMKM Indonesia untuk PENJUALAN CEPAT. '
            'Ubah ucapan singkat menjadi daftar item (nama, jumlah, harga). '
            'Fokus hanya pada jual/beli/pesan. '
            'Pahami angka informal: "10 ribu"=10000, "2rb"=2000, "1,5 juta"=1500000. '
            'Bila jumlah tidak disebut, anggap 1. Bila harga tidak disebut, isi 0. '
            'Jangan mengarang item di luar ucapan. '
            'Jangan isi modal, stok, atau data daftar produk.$catalogHint',
        schema: GeminiSchemas.sale,
      ),
    );

    final parsed = _parseSaleItems(raw);
    return matchSaleItemsToCatalog(parsed, catalog);
  }

  /// Prompt lengkap untuk mendaftarkan produk baru via suara.
  Future<ProductDraft> extractProductListing(String text) async {
    _ensureConfigured();

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AiException('Deskripsi produk masih kosong.');
    }

    final raw = await _callGemini(
      () => _geminiApi.createTextInteraction(
        input: trimmed,
        systemInstruction:
            'Kamu asisten pendaftaran produk UMKM Indonesia. '
            'Dari ucapan LENGKAP tentang produk baru, ekstrak: '
            'nama produk, harga jual, harga modal/HPP, dan stok awal. '
            'Pahami angka informal Indonesia: "10 ribu"=10000, "2rb"=2000. '
            'Bila harga jual tidak disebut isi 0. Bila modal tidak disebut isi 0. '
            'Bila stok tidak disebut isi 0. '
            'Jangan mengarang merek atau angka yang tidak diucapkan. '
            'Ini BUKAN mode kasir penjualan.',
        schema: GeminiSchemas.productDraft,
      ),
    );

    return _parseProductDraft(raw);
  }

  List<SaleItem> matchSaleItemsToCatalog(
    List<SaleItem> items,
    List<Product> catalog,
  ) {
    if (items.isEmpty || catalog.isEmpty) return items;

    final entries = catalog
        .map((p) => (id: p.id, name: p.name))
        .toList(growable: false);

    return items.map((item) {
      final match = CatalogFuzzyMatcher.bestMatch(item.name, catalog: entries);
      if (match == null) return item;

      Product? product;
      for (final entry in catalog) {
        if (entry.id == match.productId) {
          product = entry;
          break;
        }
      }
      if (product == null) return item;

      final price = item.unitPrice > 0 ? item.unitPrice : product.price;
      return item.copyWith(
        name: product.name,
        unitPrice: price,
        productId: product.id,
        matchedFromCatalog: true,
        matchScore: match.score,
      );
    }).toList();
  }

  Future<EducationGuide> generateEducationTips({
    required String periodLabel,
    required int totalRevenue,
    required int totalProfit,
    required int transactionCount,
    required int unitsSold,
    required int lowStockCount,
    required List<String> topProducts,
    required List<String> topCustomers,
  }) async {
    _ensureConfigured();

    final topProductLines = topProducts.isEmpty
        ? '- (belum ada)'
        : topProducts.map((line) => '- $line').join('\n');
    final topCustomerLines = topCustomers.isEmpty
        ? '- (belum ada)'
        : topCustomers.map((line) => '- $line').join('\n');

    final raw = await _callGemini(
      () => _geminiApi.createTextInteraction(
        input:
            'Periode analisis: $periodLabel\n'
            'Penjualan (Rp): $totalRevenue\n'
            'Laba (Rp): $totalProfit\n'
            'Transaksi: $transactionCount\n'
            'Item terjual: $unitsSold\n'
            'Produk stok menipis: $lowStockCount\n'
            'Produk terlaris:\n$topProductLines\n'
            'Pelanggan utama:\n$topCustomerLines',
        systemInstruction:
            'Kamu mentor singkat di aplikasi Sello (kasir UMKM Indonesia). '
            'Buat tepat 3 tips praktis berdasarkan data. '
            'Bahasa santai, pendek, tanpa jargon. '
            'Setiap tip dan action_hint WAJIB memakai fitur Sello saja: '
            'Kasir (suara/scan), Laporan, Katalog/Produk, atau Edukasi. '
            'JANGAN sarankan download aplikasi lain, Excel, WhatsApp di luar Sello, '
            'atau alat pencatatan di luar aplikasi ini. '
            'Jangan mengarang angka di luar data.',
        schema: GeminiSchemas.educationTips,
      ),
    );

    return _parseEducationGuide(raw);
  }

  Future<Map<ExportLanguage, LocalizedProductCopy>> translateProductCopy({
    required String productName,
    required int priceIdr,
    required int stock,
    String sourceNotes = '',
  }) async {
    _ensureConfigured();

    final notes = sourceNotes.trim().isEmpty
        ? '(tidak ada catatan tambahan)'
        : sourceNotes.trim();

    final raw = await _callGemini(
      () => _geminiApi.createTextInteraction(
        input:
            'Nama produk (ID): $productName\n'
            'Harga jual (IDR): $priceIdr\n'
            'Stok: $stock\n'
            'Catatan penjual (ID): $notes',
        systemInstruction:
            'Kamu copywriter marketplace untuk UMKM Indonesia di aplikasi Sello. '
            'Buat judul, deskripsi, dan tag produk dalam 4 bahasa: '
            'id (Indonesia), en (English), ar (العربية), zh (简体中文). '
            'Deskripsi 2–4 kalimat, persuasif tapi jujur. '
            'Jangan mengarang spesifikasi yang tidak disebut. '
            'Tag 3–6 kata singkat tanpa tanda #. '
            'Untuk ar gunakan Arab yang natural. Untuk zh gunakan Mandarin ringkas.',
        schema: GeminiSchemas.productTranslation,
      ),
    );

    return _parseProductTranslation(raw);
  }

  Future<ProductDetection> detectProduct(Uint8List imageBytes) async {
    _ensureConfigured();

    if (imageBytes.isEmpty) {
      throw const AiException('Gambar dari kamera kosong. Coba lagi.');
    }

    final raw = await _callGemini(
      () => _geminiApi.createVisionInteraction(
        imageBytes: imageBytes,
        prompt:
            'Identifikasi produk yang terlihat di foto ini untuk toko UMKM Indonesia. '
            'Fokus pada nama produk yang paling mungkin, kategori, dan deskripsi kemasan.',
        systemInstruction:
            'Kamu asisten deteksi produk untuk toko UMKM Indonesia. '
            'Dari foto, kenali produk yang terlihat jelas di tengah frame. '
            'Jika tidak yakin, turunkan confidence. Jangan mengarang merek yang tidak terlihat. '
            'Semua teks dalam Bahasa Indonesia.',
        schema: GeminiSchemas.detection,
      ),
    );

    return _parseProductDetection(raw);
  }

  Future<ProductMatchResult> matchProductToCatalog({
    required Uint8List imageBytes,
    required List<Product> catalog,
  }) async {
    _ensureConfigured();

    if (imageBytes.isEmpty) {
      throw const AiException('Gambar dari kamera kosong. Coba lagi.');
    }
    if (catalog.isEmpty) {
      throw const AiException(
        'Belum ada produk terdaftar. Daftar produk dengan foto referensi dulu.',
      );
    }

    final catalogLines = catalog
        .map((p) => '- id: ${p.id}, nama: ${p.name}, harga: ${p.price}')
        .join('\n');

    final raw = await _callGemini(
      () => _geminiApi.createVisionInteraction(
        imageBytes: imageBytes,
        prompt:
            'Foto ini diambil saat scan penjualan di toko UMKM. '
            'Cocokkan produk di foto dengan salah satu entri katalog berikut:\n'
            '$catalogLines\n\n'
            'Pilih produk yang paling mirip secara visual. '
            'Jika tidak ada yang cocok, set is_matched false dan matched_product_id kosong.',
        systemInstruction:
            'Kamu sistem pencocokan produk untuk toko UMKM Indonesia. '
            'Bandingkan tampilan visual produk di foto dengan katalog yang diberikan. '
            'Hanya set is_matched true jika yakin produk di foto sama dengan entri katalog. '
            'Jangan menebak produk di luar daftar.',
        schema: GeminiSchemas.match,
      ),
    );

    return _parseProductMatch(raw, catalog);
  }

  Future<String> summarizeBusinessReport({
    required String periodLabel,
    required int totalRevenue,
    required int totalProfit,
    required int transactionCount,
    required int unitsSold,
    required List<String> topProducts,
    required List<String> topCustomers,
  }) async {
    _ensureConfigured();

    final topProductLines = topProducts.isEmpty
        ? '- (tidak ada)'
        : topProducts.map((line) => '- $line').join('\n');
    final topCustomerLines = topCustomers.isEmpty
        ? '- (tidak ada)'
        : topCustomers.map((line) => '- $line').join('\n');

    final raw = await _callGemini(
      () => _geminiApi.createTextInteraction(
        input:
            'Periode: $periodLabel\n'
            'Penjualan (Rp): $totalRevenue\n'
            'Laba (Rp): $totalProfit\n'
            'Transaksi: $transactionCount\n'
            'Item terjual: $unitsSold\n'
            'Produk terlaris:\n$topProductLines\n'
            'Pelanggan utama:\n$topCustomerLines',
        systemInstruction:
            'Kamu asisten laporan untuk aplikasi Sello (kasir UMKM Indonesia). '
            'Bacakan data dalam 2–4 kalimat singkat. '
            'Bahasa santai dan jelas. '
            'Sebut penjualan, laba, produk terlaris, atau pelanggan utama bila relevan. '
            'Satu saran singkat HARUS memakai fitur di aplikasi Sello '
            '(Kasir, Laporan, Katalog/Produk, atau Edukasi). '
            'JANGAN sarankan download app lain, spreadsheet eksternal, '
            'atau alat di luar Sello. '
            'Jangan mengarang angka. Jangan pakai istilah teknis atau bahasa Inggris.',
        schema: GeminiSchemas.businessInsight,
      ),
    );

    return _parseBusinessInsight(raw);
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const AiException(
        'GEMINI_API_KEY belum diisi di file .env. '
        'Tambahkan kunci dari Google AI Studio.',
      );
    }
  }

  Future<String> _callGemini(Future<String> Function() request) async {
    try {
      return await request();
    } on NetworkException catch (e) {
      throw AiException(e.message);
    } catch (_) {
      throw const AiException(
        'Tidak dapat terhubung ke layanan AI. Cek koneksi internet kamu.',
      );
    }
  }

  List<SaleItem> _parseSaleItems(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
    if (items is! List) {
      throw const AiException('AI tidak menemukan item penjualan.');
    }

    final result = items
        .whereType<Map<String, dynamic>>()
        .map(SaleItem.fromJson)
        .where((item) => item.quantity > 0)
        .toList();

    if (result.isEmpty) {
      throw const AiException(
        'Tidak ada item yang bisa dikenali. Coba ucapkan lebih jelas, '
        'mis. "jual 3 kopi 5 ribu".',
      );
    }

    return result;
  }

  ProductDetection _parseProductDetection(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiException('AI tidak mengembalikan data produk.');
    }

    final detection = ProductDetection.fromJson(decoded);
    if (detection.confidence < 0.15) {
      throw const AiException(
        'Produk tidak terlihat jelas. Dekatkan kamera dan pastikan pencahayaan cukup.',
      );
    }

    return detection;
  }

  String _parseBusinessInsight(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiException('AI tidak mengembalikan ringkasan laporan.');
    }

    final summary = decoded['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      throw const AiException('AI tidak mengembalikan ringkasan laporan.');
    }

    return summary.trim();
  }

  ProductDraft _parseProductDraft(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiException('AI tidak mengembalikan data produk.');
    }

    final draft = ProductDraft.fromJson(decoded);
    if (draft.name.trim().isEmpty) {
      throw const AiException(
        'Nama produk belum jelas. Coba sebutkan nama, harga, dan stok.',
      );
    }
    return draft;
  }

  EducationGuide _parseEducationGuide(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiException('AI tidak mengembalikan tips edukasi.');
    }

    final headline = (decoded['headline'] as String?)?.trim().isNotEmpty == true
        ? (decoded['headline'] as String).trim()
        : 'Tips untuk tokomu';
    final tipsRaw = decoded['tips'];
    if (tipsRaw is! List) {
      throw const AiException('AI tidak mengembalikan daftar tips.');
    }

    final tips = tipsRaw
        .whereType<Map<String, dynamic>>()
        .map(EducationTip.fromJson)
        .where((tip) => tip.body.isNotEmpty)
        .toList();

    if (tips.isEmpty) {
      throw const AiException('Belum ada tips yang bisa ditampilkan.');
    }

    return EducationGuide(
      headline: headline,
      tips: tips.take(3).toList(),
      generatedAt: DateTime.now(),
    );
  }

  Map<ExportLanguage, LocalizedProductCopy> _parseProductTranslation(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiException('AI tidak mengembalikan hasil terjemahan.');
    }

    final result = <ExportLanguage, LocalizedProductCopy>{};
    for (final language in ExportLanguage.values) {
      final localeRaw = decoded[language.code];
      if (localeRaw is! Map<String, dynamic>) {
        throw const AiException(
          'Hasil terjemahan belum lengkap untuk semua bahasa.',
        );
      }
      final copy = LocalizedProductCopy.fromJson(
        localeRaw,
        language: language,
      );
      if (copy.title.isEmpty || copy.description.isEmpty) {
        throw const AiException(
          'Judul atau deskripsi terjemahan masih kosong. Coba lagi.',
        );
      }
      result[language] = copy;
    }
    return result;
  }

  ProductMatchResult _parseProductMatch(String raw, List<Product> catalog) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const AiException('Format jawaban AI tidak dapat dibaca.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiException('AI tidak mengembalikan hasil pencocokan.');
    }

    final rawId = decoded['matched_product_id'];
    final productId = rawId is String && rawId.trim().isNotEmpty
        ? rawId.trim()
        : null;

    Product? matched;
    if (productId != null) {
      for (final product in catalog) {
        if (product.id == productId) {
          matched = product;
          break;
        }
      }
    }

    final result = ProductMatchResult.fromJson(
      decoded,
      matchedProduct: matched,
    );

    if (result.confidence < 0.15) {
      throw const AiException(
        'Produk tidak terlihat jelas. Dekatkan kamera dan pastikan pencahayaan cukup.',
      );
    }

    return result;
  }
}
