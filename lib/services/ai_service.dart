import 'dart:convert';
import 'dart:typed_data';

import 'package:sello/core/config/env.dart';
import 'package:sello/core/constants/gemini_schemas.dart';
import 'package:sello/core/network/network_exception.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_detection.dart';
import 'package:sello/models/product_match_result.dart';
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

  Future<List<SaleItem>> extractSale(String text) async {
    _ensureConfigured();

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AiException('Teks penjualan masih kosong.');
    }

    final raw = await _callGemini(
      () => _geminiApi.createTextInteraction(
        input: trimmed,
        systemInstruction:
            'Kamu asisten kasir untuk UMKM Indonesia. Tugasmu mengubah kalimat '
            'natural tentang penjualan menjadi daftar item terstruktur. '
            'Pahami angka informal Indonesia: "10 ribu"=10000, "2rb"=2000, '
            '"1,5 juta"=1500000. "Harga 10 ribu" biasanya harga per satuan. '
            'Bila jumlah tidak disebut, anggap 1. Bila harga tidak disebut, isi 0. '
            'Jangan mengarang item yang tidak ada di kalimat.',
        schema: GeminiSchemas.sale,
      ),
    );

    return _parseSaleItems(raw);
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
