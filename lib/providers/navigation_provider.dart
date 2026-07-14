import 'package:flutter/foundation.dart';
import 'package:sello/models/cashier_mode.dart';

class NavigationProvider extends ChangeNotifier {
  static const int berandaIndex = 0;
  static const int laporanIndex = 1;
  static const int centerActionIndex = 2;
  static const int kontenIndex = 3;
  static const int menuIndex = 4;

  int _currentIndex = berandaIndex;
  CashierMode? _pendingCashierMode;

  int get currentIndex => _currentIndex;
  CashierMode? get pendingCashierMode => _pendingCashierMode;

  /// Maps bottom-nav index to IndexedStack screen index.
  /// Center action (index 2) is not a screen; it opens a mode picker.
  int get screenIndex {
    if (_currentIndex < centerActionIndex) return _currentIndex;
    return _currentIndex - 1;
  }

  void setIndex(int index) {
    if (index == centerActionIndex) return;
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void openCashier({CashierMode mode = CashierMode.voice}) {
    _pendingCashierMode = mode;
    _currentIndex = berandaIndex;
    notifyListeners();
  }

  CashierMode? consumePendingCashierMode() {
    final mode = _pendingCashierMode;
    _pendingCashierMode = null;
    return mode;
  }
}
