import 'package:flutter/foundation.dart';
import 'package:sello/models/subscription_plan.dart';
import 'package:sello/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _service = SubscriptionService.instance;

  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionPlan get currentPlan => _currentPlan;

  bool get isPro => _currentPlan == SubscriptionPlan.pro;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> load(String userId) async {
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPlan = await _service.loadPlan(userId);
    } on SubscriptionException catch (e) {
      _errorMessage = e.message;
      _currentPlan = SubscriptionPlan.free;
    } catch (_) {
      _errorMessage = 'Gagal memuat paket langganan.';
      _currentPlan = SubscriptionPlan.free;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectPlan(SubscriptionPlan plan) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return false;

    _errorMessage = null;
    notifyListeners();

    try {
      await _service.savePlan(userId: userId, plan: plan);
      _currentPlan = plan;
      notifyListeners();
      return true;
    } on SubscriptionException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Gagal menyimpan paket. Coba lagi nanti.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void resetLocal() {
    _currentPlan = SubscriptionPlan.free;
    _userId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
