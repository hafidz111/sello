import 'package:flutter/material.dart';
import 'package:sello/models/feature_item.dart';
import 'package:sello/styles/app_colors.dart';

abstract final class FeatureData {
  static const List<FeatureItem> all = [
    FeatureItem(
      id: 'voice_cashier',
      title: 'Kasir Suara & Teks',
      description:
          'Catat penjualan dengan kalimat natural. AI ekstrak item, harga, stok otomatis.',
      icon: Icons.mic_rounded,
      color: AppColors.primary,
      route: '/cashier',
    ),
    FeatureItem(
      id: 'product_scan',
      title: 'Scan Produk',
      description:
          'Scan/foto produk → AI kenali produknya, lalu isi jumlah (pcs) → penjualan tercatat.',
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF7C3AED),
      route: '/product-scan',
    ),
    FeatureItem(
      id: 'photo_to_content',
      title: 'Foto ke Konten',
      description:
          'Unggah foto → AI hasilkan caption IG/TikTok, hashtag lokal & copy iklan.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFEC4899),
      route: '/content',
    ),
    FeatureItem(
      id: 'whatsapp_assistant',
      title: 'Asisten WhatsApp',
      description:
          'Chatbot AI merespons FAQ, cek stok & proses order via WhatsApp Business.',
      icon: Icons.chat_rounded,
      color: Color(0xFF22C55E),
      route: '/whatsapp',
    ),
    FeatureItem(
      id: 'business_report',
      title: 'Laporan Bisnis',
      description:
          'Ringkasan harian/mingguan dalam bahasa manusia yang mudah dipahami.',
      icon: Icons.analytics_rounded,
      color: Color(0xFFF59E0B),
      route: '/report',
    ),
    FeatureItem(
      id: 'translate_export',
      title: 'Terjemah & Ekspor',
      description:
          'Deskripsi produk ID, EN, AR, ZH untuk pasar internasional.',
      icon: Icons.translate_rounded,
      color: Color(0xFF06B6D4),
      route: '/translate',
    ),
    FeatureItem(
      id: 'digital_catalog',
      title: 'Katalog Digital',
      description: 'Toko online mini yang bisa dibagikan lewat link/WhatsApp.',
      icon: Icons.storefront_rounded,
      color: Color(0xFF8B5CF6),
      route: '/catalog',
    ),
    FeatureItem(
      id: 'offline_mode',
      title: 'Mode Offline',
      description:
          'Pencatatan transaksi tanpa internet, sinkron otomatis saat online.',
      icon: Icons.cloud_off_rounded,
      color: Color(0xFF64748B),
      route: '/offline',
    ),
    FeatureItem(
      id: 'micro_education',
      title: 'Edukasi Mikro',
      description: 'Tips bisnis personal dari AI berdasarkan data penjualan Anda.',
      icon: Icons.school_rounded,
      color: Color(0xFFEF4444),
      route: '/education',
    ),
  ];
}
