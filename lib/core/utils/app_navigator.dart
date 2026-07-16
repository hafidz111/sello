import 'package:flutter/material.dart';
import 'package:sello/screens/features/product_detail_screen.dart';
import 'package:sello/screens/features/product_list_screen.dart';

/// Navigator global untuk buka layar dari notifikasi.
abstract final class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get _state => key.currentState;

  static const productPayloadPrefix = 'product:';
  static const catalogPayload = 'catalog';

  static String productPayload(String productId) =>
      '$productPayloadPrefix$productId';

  static void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    if (payload == catalogPayload) {
      openProductCatalog();
      return;
    }

    if (payload.startsWith(productPayloadPrefix)) {
      final productId = payload.substring(productPayloadPrefix.length).trim();
      if (productId.isNotEmpty) {
        openProductDetail(productId);
      }
    }
  }

  static void openProductDetail(String productId) {
    final nav = _state;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  static void openProductCatalog() {
    final nav = _state;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );
  }
}
