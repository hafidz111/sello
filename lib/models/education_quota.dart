class EducationQuota {
  const EducationQuota({
    required this.used,
    required this.limit,
  });

  static const dailyLimit = 3;

  final int used;
  final int limit;

  int get remaining => (limit - used).clamp(0, limit);
  bool get canGenerate => remaining > 0;
  bool get isExhausted => !canGenerate;

  String get statusLabel {
    if (isExhausted) {
      return 'Batas harian habis ($limit/$limit). Coba lagi besok.';
    }
    return 'Sisa kesempatan hari ini: $remaining dari $limit';
  }
}
