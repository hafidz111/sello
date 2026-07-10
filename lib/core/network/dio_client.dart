import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sello/core/config/env.dart';
import 'package:sello/core/network/network_exception.dart';

abstract final class DioClient {
  static Dio? _geminiDio;

  static Dio get gemini {
    if (!Env.hasGeminiApiKey) {
      throw const NetworkException('GEMINI_API_KEY belum tersedia.');
    }
    return _geminiDio ??= _createGeminiDio();
  }

  static Dio _createGeminiDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 60),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['x-goog-api-key'] = Env.geminiApiKey;
          options.headers['Api-Revision'] = '2026-05-20';
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: _mapDioError(error),
              message: error.message,
            ),
          );
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          logPrint: (message) => debugPrint('[Dio] $message'),
        ),
      );
    }

    return dio;
  }

  static NetworkException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    if (status == 429) {
      return const NetworkException(
        'Kuota layanan habis untuk sementara. Tunggu 1 menit lalu coba lagi.',
      );
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final apiMessage = data['error']?['message'];
      if (apiMessage is String && apiMessage.isNotEmpty) {
        final lower = apiMessage.toLowerCase();
        if (lower.contains('quota') ||
            lower.contains('rate') ||
            lower.contains('resource_exhausted')) {
          return const NetworkException(
            'Kuota AI habis untuk sementara. Tunggu 1 menit lalu coba lagi, '
            'atau ganti GEMINI_MODEL di file .env.',
          );
        }
        return NetworkException('Gagal memanggil layanan: $apiMessage');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'Tidak dapat terhubung ke server. Cek koneksi internet kamu.',
      );
    }

    return const NetworkException('Terjadi kesalahan jaringan. Coba lagi.');
  }
}
