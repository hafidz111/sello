import 'package:flutter/foundation.dart';

/// Konfigurasi AdMob Sello.
abstract final class AdMobConfig {
  /// App ID Android/iOS (sudah di Manifest / Info.plist).
  static const appId = 'ca-app-pub-4122766238215136~5990475654';

  /// Unit rewarded produksi (Laporan paket Gratis).
  static const rewardedReportProduction =
      'ca-app-pub-4122766238215136/2564713459';

  /// Unit rewarded uji resmi Google.
  static const rewardedTest = 'ca-app-pub-3940256099942544/5224354917';

  /// Debug pakai iklan uji agar akun AdMob tidak berisiko ditangguhkan.
  static String get rewardedReportUnitId {
    if (kDebugMode) return rewardedTest;
    return rewardedReportProduction;
  }
}
