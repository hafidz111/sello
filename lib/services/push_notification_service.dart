import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/core/utils/app_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inisialisasi FCM + notifikasi lokal, dan simpan token ke Supabase.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _channelId = 'sello_stock_alerts';
  static const _channelName = 'Peringatan stok';
  static const _channelDesc = 'Notifikasi saat stok produk menipis';

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _canNavigate = false;
  String? _pendingPayload;
  int _notificationId = 1000;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _pendingPayload = launch!.notificationResponse?.payload;
    }

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];
      final productId = message.data['product_id'];
      if (title is String && body is String) {
        showLocalNotification(
          title: title,
          body: body,
          payload: productId is String && productId.isNotEmpty
              ? AppNavigator.productPayload(productId)
              : null,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final productId = message.data['product_id'];
      if (productId is String && productId.isNotEmpty) {
        _routeOrQueue(AppNavigator.productPayload(productId));
      }
    });

    _initialized = true;
  }

  /// Panggil setelah user login & navigator siap.
  void enableNavigationAndFlush() {
    _canNavigate = true;
    final pending = _pendingPayload;
    _pendingPayload = null;
    if (pending != null) {
      AppNavigator.handleNotificationPayload(pending);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    _routeOrQueue(response.payload);
  }

  void _routeOrQueue(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (_canNavigate && AppNavigator.key.currentState != null) {
      AppNavigator.handleNotificationPayload(payload);
    } else {
      _pendingPayload = payload;
    }
  }

  Future<bool> requestPermission() async {
    await initialize();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final status = settings.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  Future<void> registerTokenForUser(String userId) async {
    if (userId.isEmpty || userId == 'anonymous') return;

    try {
      await initialize();
      await requestPermission();

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final platform = kIsWeb
          ? 'web'
          : (Platform.isAndroid
                ? 'android'
                : (Platform.isIOS ? 'ios' : 'other'));

      await SupabaseConfig.client.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,token');

      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await SupabaseConfig.client.from('device_tokens').upsert({
            'user_id': userId,
            'token': newToken,
            'platform': platform,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,token');
        } catch (e) {
          debugPrint('Gagal refresh FCM token: $e');
        }
      });
    } on PostgrestException catch (e) {
      debugPrint('Gagal simpan FCM token: ${e.message}');
    } catch (e) {
      debugPrint('Gagal daftar notifikasi: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    _notificationId += 1;

    await _local.show(
      id: _notificationId,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
