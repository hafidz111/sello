import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sello/core/config/env.dart';
import 'package:sello/core/network/dio_client.dart';
import 'package:sello/core/network/network_exception.dart';

class GeminiApiService {
  GeminiApiService._();

  static final GeminiApiService instance = GeminiApiService._();

  static const _defaultModelName = 'gemini-3.5-flash';
  static const _generationConfig = {'temperature': 0.2};

  String get _modelName => Env.geminiModel ?? _defaultModelName;

  Future<String> createTextInteraction({
    required String input,
    required String systemInstruction,
    required Map<String, dynamic> schema,
  }) {
    return _createInteraction(
      input: input,
      systemInstruction: systemInstruction,
      schema: schema,
    );
  }

  Future<String> createVisionInteraction({
    required Uint8List imageBytes,
    required String prompt,
    required String systemInstruction,
    required Map<String, dynamic> schema,
  }) {
    return _createInteraction(
      input: [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image',
          'data': base64Encode(imageBytes),
          'mime_type': 'image/jpeg',
        },
      ],
      systemInstruction: systemInstruction,
      schema: schema,
    );
  }

  Future<String> _createInteraction({
    required Object input,
    required String systemInstruction,
    required Map<String, dynamic> schema,
  }) async {
    try {
      final response = await DioClient.gemini.post<Map<String, dynamic>>(
        '/interactions',
        data: {
          'model': _modelName,
          'input': input,
          'system_instruction': systemInstruction,
          'generation_config': _generationConfig,
          'response_format': {
            'type': 'text',
            'mime_type': 'application/json',
            'schema': schema,
          },
        },
      );

      return _readOutputText(response.data ?? const {});
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      if (e.error is NetworkException) {
        throw e.error as NetworkException;
      }
      throw const NetworkException(
        'Tidak dapat terhubung ke layanan AI. Cek koneksi internet kamu.',
      );
    } catch (_) {
      throw const NetworkException(
        'Tidak dapat terhubung ke layanan AI. Cek koneksi internet kamu.',
      );
    }
  }

  String _readOutputText(Map<String, dynamic> data) {
    if (data['status'] == 'failed') {
      throw const NetworkException('AI gagal memproses permintaan. Coba lagi.');
    }

    final direct = data['output_text'];
    if (direct is String && direct.isNotEmpty) {
      return direct;
    }

    final steps = data['steps'];
    if (steps is List) {
      String? lastText;
      for (final step in steps) {
        if (step is! Map<String, dynamic> || step['type'] != 'model_output') {
          continue;
        }
        final content = step['content'];
        if (content is! List) continue;

        final buffer = StringBuffer();
        for (final item in content) {
          if (item is Map<String, dynamic> &&
              item['type'] == 'text' &&
              item['text'] is String) {
            buffer.write(item['text']);
          }
        }
        if (buffer.isNotEmpty) {
          lastText = buffer.toString();
        }
      }
      if (lastText != null && lastText.isNotEmpty) {
        return lastText;
      }
    }

    throw const NetworkException('AI tidak mengembalikan hasil. Coba lagi.');
  }
}
