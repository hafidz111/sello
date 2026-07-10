import 'package:flutter/foundation.dart';
import 'package:sello/models/dashboard_stats.dart';
import 'package:sello/services/product_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardStats _stats = DashboardStats.empty;
  bool _isLoading = false;

  DashboardStats get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> load(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await ProductService.instance.fetchDashboardStats(userId);
    } catch (_) {
      _stats = DashboardStats.empty;
    }

    _isLoading = false;
    notifyListeners();
  }
}
