import 'package:flutter/foundation.dart';
import 'package:sello/models/education_guide.dart';
import 'package:sello/models/education_quota.dart';
import 'package:sello/services/education_service.dart';

class EducationProvider extends ChangeNotifier {
  EducationGuide? _guide;
  EducationQuota _quota = const EducationQuota(used: 0, limit: EducationQuota.dailyLimit);
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  EducationGuide? get guide => _guide;
  EducationQuota get quota => _quota;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  bool get canChangeTips => _quota.canGenerate && !_isLoading;

  Future<void> load(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      final result = await EducationService.instance.loadCachedOrInitial(userId);
      _guide = result.guide;
      _quota = result.quota;
    } on EducationException catch (e) {
      _errorMessage = e.message;
      _quota = await EducationService.instance.getQuota(userId);
    } catch (_) {
      _errorMessage = 'Gagal memuat edukasi. Coba lagi nanti.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeTips(String userId) async {
    if (!_quota.canGenerate) {
      _infoMessage = _quota.statusLabel;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      final result = await EducationService.instance.regenerate(userId);
      _guide = result.guide;
      _quota = result.quota;
      _infoMessage = _quota.statusLabel;
    } on EducationException catch (e) {
      _errorMessage = e.message;
      _quota = await EducationService.instance.getQuota(userId);
    } catch (_) {
      _errorMessage = 'Gagal mengganti tips. Coba lagi nanti.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _infoMessage = null;
  }
}
