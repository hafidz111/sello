enum SubscriptionPlan {
  free,
  pro;

  String get id => name;

  String get label {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Gratis';
      case SubscriptionPlan.pro:
        return 'Pro';
    }
  }

  /// Harga tampilan dummy (bukan harga billing sungguhan).
  String get priceLabel {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Rp 0';
      case SubscriptionPlan.pro:
        return 'Rp 49.000';
    }
  }

  String get billingPeriodLabel {
    switch (this) {
      case SubscriptionPlan.free:
        return 'selamanya';
      case SubscriptionPlan.pro:
        return '/ bulan';
    }
  }

  /// Batas ganti tips edukasi per hari.
  int get educationDailyLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return 1;
      case SubscriptionPlan.pro:
        return 3;
    }
  }

  List<String> get benefits {
    switch (this) {
      case SubscriptionPlan.free:
        return const [
          'Kasir suara & scan',
          'Foto ke konten (segera)',
          'Laporan bisnis (dengan iklan)',
          'Terjemah & ekspor',
          'Katalog digital',
          'Mode offline dasar',
          'Edukasi mikro terbatas (1x/hari)',
        ];
      case SubscriptionPlan.pro:
        return const [
          'Kasir suara & scan',
          'Foto ke konten (segera)',
          'Laporan bisnis tanpa iklan',
          'Terjemah & ekspor',
          'Katalog digital',
          'Mode offline dasar',
          'Edukasi mikro penuh (3x/hari)',
          'Fitur AI lebih leluasa (uji coba)',
        ];
    }
  }

  static SubscriptionPlan fromId(String? value) {
    if (value == SubscriptionPlan.pro.id) return SubscriptionPlan.pro;
    return SubscriptionPlan.free;
  }
}
