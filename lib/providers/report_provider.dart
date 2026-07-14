import 'package:flutter/foundation.dart';
import 'package:sello/models/business_report.dart';
import 'package:sello/models/report_period.dart';
import 'package:sello/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportPeriod _period = ReportPeriod.today;
  ReportDateRange _customRange =
      ReportDateRange.forPeriod(ReportPeriod.custom);
  BusinessReport _report = BusinessReport.empty(ReportPeriod.today);
  bool _isLoading = false;
  String? _errorMessage;

  ReportPeriod get period => _period;
  ReportDateRange get customRange => _customRange;
  BusinessReport get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await ReportService.instance.fetchReport(
        userId: userId,
        period: _period,
        customRange: _period == ReportPeriod.custom ? _customRange : null,
      );
    } on ReportException catch (e) {
      _errorMessage = e.message;
      _report = BusinessReport.empty(_period);
    } catch (_) {
      _errorMessage = 'Gagal memuat laporan. Coba lagi nanti.';
      _report = BusinessReport.empty(_period);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPeriod(String userId, ReportPeriod period) {
    if (_period == period && period != ReportPeriod.custom && !_isLoading) {
      return Future.value();
    }
    _period = period;
    return load(userId);
  }

  Future<void> setCustomRange(
    String userId, {
    required DateTime from,
    required DateTime to,
  }) {
    _period = ReportPeriod.custom;
    _customRange = ReportDateRange.customInclusive(from: from, to: to);
    return load(userId);
  }
}
