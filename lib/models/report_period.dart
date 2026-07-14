enum ReportPeriod {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  custom;

  String get label => switch (this) {
    today => 'Hari ini',
    yesterday => 'Kemarin',
    thisWeek => 'Minggu ini',
    lastWeek => 'Minggu lalu',
    thisMonth => 'Bulan ini',
    lastMonth => 'Bulan lalu',
    thisYear => 'Tahun ini',
    lastYear => 'Tahun lalu',
    custom => 'Rentang',
  };

  bool get isPreset => this != custom;
}

class ReportDateRange {
  const ReportDateRange({
    required this.start,
    required this.endExclusive,
  });

  /// Inclusive local start (00:00).
  final DateTime start;

  /// Exclusive local end (used for DB filters).
  final DateTime endExclusive;

  /// Last inclusive calendar day for UI labels.
  DateTime get endInclusive => endExclusive.subtract(const Duration(days: 1));

  static DateTime startOfDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime startOfWeek(DateTime value) {
    final day = startOfDay(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static ReportDateRange forPeriod(ReportPeriod period, {DateTime? now}) {
    final reference = (now ?? DateTime.now()).toLocal();
    final today = startOfDay(reference);
    final tomorrow = today.add(const Duration(days: 1));

    return switch (period) {
      ReportPeriod.today =>
        ReportDateRange(start: today, endExclusive: tomorrow),
      ReportPeriod.yesterday => ReportDateRange(
        start: today.subtract(const Duration(days: 1)),
        endExclusive: today,
      ),
      ReportPeriod.thisWeek => ReportDateRange(
        start: startOfWeek(today),
        endExclusive: tomorrow,
      ),
      ReportPeriod.lastWeek => () {
        final thisWeekStart = startOfWeek(today);
        return ReportDateRange(
          start: thisWeekStart.subtract(const Duration(days: 7)),
          endExclusive: thisWeekStart,
        );
      }(),
      ReportPeriod.thisMonth => ReportDateRange(
        start: DateTime(today.year, today.month),
        endExclusive: tomorrow,
      ),
      ReportPeriod.lastMonth => () {
        final thisMonthStart = DateTime(today.year, today.month);
        final lastMonthStart = DateTime(today.year, today.month - 1);
        return ReportDateRange(
          start: lastMonthStart,
          endExclusive: thisMonthStart,
        );
      }(),
      ReportPeriod.thisYear => ReportDateRange(
        start: DateTime(today.year),
        endExclusive: tomorrow,
      ),
      ReportPeriod.lastYear => ReportDateRange(
        start: DateTime(today.year - 1),
        endExclusive: DateTime(today.year),
      ),
      ReportPeriod.custom =>
        ReportDateRange(start: today, endExclusive: tomorrow),
    };
  }

  /// Inclusive calendar days from [from] to [to] (order-normalized).
  static ReportDateRange customInclusive({
    required DateTime from,
    required DateTime to,
  }) {
    final a = startOfDay(from);
    final b = startOfDay(to);
    final start = a.isBefore(b) ? a : b;
    final endDay = a.isBefore(b) ? b : a;
    return ReportDateRange(
      start: start,
      endExclusive: endDay.add(const Duration(days: 1)),
    );
  }
}
