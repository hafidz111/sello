import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sello/core/config/env.dart';
import 'package:sello/models/sale_item.dart';

/// Dilempar saat pemanggilan AI gagal, dengan pesan yang ramah pengguna.
class AiException implements Exception {
  const AiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Lapisan tunggal untuk semua interaksi dengan model AI (Gemini).
///
/// Dipanggil langsung dari aplikasi memakai `GEMINI_API_KEY` di `.env`.
/// Catatan keamanan: memanggil langsung dari klien membuat API key ikut
/// terbundel di aplikasi. Cocok untuk demo, tetapi untuk rilis produksi
/// sebaiknya dipindah ke proxy sisi server (mis. Supabase Edge Function).
class AiService {
  AiService._();

  static final AiService instance = AiService._();

  /// Nama model default. Bisa ditimpa lewat `GEMINI_MODEL` di `.env`
  /// (mis. 'gemini-2.0-flash-lite' yang kuota gratisnya lebih longgar).
  static const String _defaultModelName = 'gemini-2.0-flash';

  String get _modelName => Env.geminiModel ?? _defaultModelName;

  GenerativeModel? _saleModel;

  bool get isConfigured => Env.hasGeminiApiKey;

  GenerativeModel _buildSaleModel() {
    final schema = Schema.object(
      properties: {
        'items': Schema.array(
          items: Schema.object(
            properties: {
              'name': Schema.string(
                description: 'Nama produk yang dijual.',
              ),
              'quantity': Schema.integer(
                description: 'Jumlah unit yang terjual (pcs), minimal 1.',
              ),
              'unit_price': Schema.integer(
                description:
                    'Harga per satuan dalam Rupiah tanpa titik/koma. '
                    '0 bila tidak disebutkan.',
              ),
            },
            requiredProperties: ['name', 'quantity', 'unit_price'],
          ),
        ),
      },
      requiredProperties: ['items'],
    );

    return GenerativeModel(
      model: _modelName,
      apiKey: Env.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
      systemInstruction: Content.system(
        'Kamu asisten kasir untuk UMKM Indonesia. Tugasmu mengubah kalimat '
        'natural tentang penjualan menjadi daftar item terstruktur. '
        'Pahami angka informal Indonesia: "10 ribu"=10000, "2rb"=2000, '
        '"1,5 juta"=1500000. "Harga 10 ribu" biasanya harga per satuan. '
        'Bila jumlah tidak disebut, anggap 1. Bila harga tidak disebut, isi 0. '
        'Jangan mengarang item yang tidak ada di kalimat.',
      ),
    );
  }

  /// Mengekstrak daftar penjualan dari kalimat natural.
  ///
  /// Contoh input: "Tadi jual 5 keripik singkong 10 ribu sama 2 teh botol 4rb".
  Future<List<SaleItem>> extractSale(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AiException('Teks penjualan masih kosong.');
    }
    if (!isConfigured) {
      throw const AiException(
        'GEMINI_API_KEY belum diisi di file .env. '
        'Tambahkan API key Gemini kamu lalu jalankan ulang aplikasi.',
      );
    }

    final model = _saleModel ??= _buildSaleModel();

    late final GenerateContentResponse response;
    try {
      response = await model.generateContent([Content.text(trimmed)]);
    } on GenerativeAIException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('quota') ||
          msg.contains('rate') ||
          msg.contains('resource_exhausted') ||
          msg.contains('429')) {
        throw const AiException(
          'Kuota AI habis untuk sementara. Tunggu ~1 menit lalu coba lagi, '
          'atau ganti model ke "gemini-2.0-flash-lite" di file .env '
          '(GEMINI_MODEL). Pastikan API key dibuat dari Google AI Studio.',
        );
      }
      throw AiException('Gagal memanggil AI: ${e.message}');
    } catch (_) {
      throw const AiException(
        'Tidak dapat terhubung ke layanan AI. Cek koneksi internet kamu.',
      );
    }

    final raw = response.text;
    if (raw == null || raw.isEmpty) {
      throw const AiException('AI tidak mengembalikan hasil. Coba lagi.');
    }

    return _parseSaleItems(raw);
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
        'Tidak ada item yang bisa dikenali. Coba tulis lebih jelas, '
        'mis. "jual 3 kopi 5 ribu".',
      );
    }

    return result;
  }
}
