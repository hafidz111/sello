import 'package:flutter/foundation.dart';
import 'package:sello/models/cashier_mode.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  CashierMode? _pendingCashierMode;

  int get currentIndex => _currentIndex;
  CashierMode? get pendingCashierMode => _pendingCashierMode;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void openCashier({CashierMode mode = CashierMode.voice}) {
    _pendingCashierMode = mode;
    _currentIndex = 1;
    notifyListeners();
  }

  CashierMode? consumePendingCashierMode() {
    final mode = _pendingCashierMode;
    _pendingCashierMode = null;
    return mode;
  }
}
