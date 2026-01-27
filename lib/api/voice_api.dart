import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/voice_item.dart' as models;
import 'dart:developer';

class VoiceApi {
  static Future<String> createVoice({
    required File voiceFile,
    String name = '',
    String language = 'en',
  }) async {
    log('Starting API call to create voice');
    log('Voice name: $name');

    final uri = Uri.parse('${ApiConfig.baseUrl}/voices');

    final request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['language'] = language
      ..files.add(await http.MultipartFile.fromPath('voice', voiceFile.path));

    try {
      log('Send create voice API request');
      final response = await request.send().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('HTTP request timed out after 10 seconds');
              throw const SocketException('Failed to connect to server');
            },
          );

      final body = await response.stream.bytesToString();
      log('API response: $body');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to create voice: $body');
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response shape: $data');
      }

      final voiceId = data['voice_id'];
      if (voiceId is! String || voiceId.isEmpty) {
        throw Exception('Missing voice_id in response: $data');
      }

      return voiceId;
    } catch (e) {
      log('Error during voice post API call: $e');
      rethrow;
    }
  }

  static Future<List<models.VoiceItem>> getVoiceList() async {
    try {
      log('=== getVoiceList() called ===');
      final baseUrl = ApiConfig.baseUrl;
      log('API Base URL: $baseUrl');

      final uri = Uri.parse('${baseUrl}/voices');
      log('Fetching voice list from: $uri');

      log('Initiating HTTP GET request...');
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              log('HTTP request timed out after 10 seconds');
              throw SocketException('Failed to connect to server');
            },
          );

      log('Received response with status code: ${response.statusCode}');
      log('Voice list response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get voice list (Status ${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      log('Decoded JSON data: $data');

      if (data is! List<dynamic>) {
        throw Exception(
          'Expected response to be an array, got ${data.runtimeType}: $data',
        );
      }

      final List<dynamic> voices = data;

      log('Successfully parsed ${voices.length} voices');

      return voices.map((voice) {
        log('Parsing voice: $voice (type: ${voice.runtimeType})');
        return models.VoiceItem.fromJson(voice as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      log('!!! Error fetching voice list: $e');
      log('Error type: ${e.runtimeType}');
      log('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}
