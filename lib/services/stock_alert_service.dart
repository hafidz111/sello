import 'package:shared_preferences/shared_preferences.dart';
import 'package:sello/core/constants/stock_constants.dart';
import 'package:sello/core/utils/app_navigator.dart';
import 'package:sello/models/product.dart';
import 'package:sello/services/push_notification_service.dart';

/// Peringatan stok menipis lewat notifikasi lokal (+ siap FCM).
class StockAlertService {
  StockAlertService._();

  static final StockAlertService instance = StockAlertService._();

  final _notifications = PushNotificationService.instance;

  /// Setelah penjualan: beri tahu jika stok baru ≤ ambang.
  Future<void> notifyIfLowAfterSale({
    required String userId,
    required String productId,
    required String productName,
    required int previousStock,
    required int newStock,
  }) async {
    final threshold = StockConstants.lowStockThreshold;
    if (newStock > threshold) return;
    if (previousStock <= newStock) return;

    final already = await _wasNotifiedToday(
      userId: userId,
      productId: productId,
    );
    if (already) return;

    final safeStock = newStock < 0 ? 0 : newStock;
    await _notifications.showLocalNotification(
      title: 'Stok menipis',
      body: safeStock == 0
          ? '$productName habis. Segera isi ulang stok.'
          : '$productName sisa $safeStock. Segera isi ulang sebelum kehabisan.',
      payload: AppNavigator.productPayload(productId),
    );
    await _markNotifiedToday(userId: userId, productId: productId);
  }

  /// Saat masuk app: ringkas produk yang stoknya menipis (maks 1x/hari).
  Future<void> notifyDailySummaryIfNeeded({
    required String userId,
    required List<Product> products,
  }) async {
    if (userId.isEmpty || userId == 'anonymous') return;

    final prefs = await SharedPreferences.getInstance();
    final summaryKey = 'stock_alert_summary_${userId}_${_todayStamp()}';
    if (prefs.getBool(summaryKey) == true) return;

    final low = products
        .where((p) => p.stock <= StockConstants.lowStockThreshold)
        .toList();
    if (low.isEmpty) {
      await prefs.setBool(summaryKey, true);
      return;
    }

    final names = low.take(3).map((p) => p.name).join(', ');
    final extra = low.length > 3 ? ' dan ${low.length - 3} lainnya' : '';
    final targetId = low.first.id;

    await _notifications.showLocalNotification(
      title: 'Ada ${low.length} produk stok menipis',
      body: '$names$extra. Ketuk untuk membuka produk.',
      payload: AppNavigator.productPayload(targetId),
    );
    await prefs.setBool(summaryKey, true);
  }

  Future<bool> _wasNotifiedToday({
    required String userId,
    required String productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_productKey(userId, productId)) == true;
  }

  Future<void> _markNotifiedToday({
    required String userId,
    required String productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_productKey(userId, productId), true);
  }

  String _productKey(String userId, String productId) =>
      'stock_alert_${userId}_${productId}_${_todayStamp()}';

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
