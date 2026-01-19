import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'dart:developer';

class StoryApi {
  static Future<http.Response> getStoryStatus(String storyId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/stories/$storyId');
      log('Fetching story status from: $uri');

      final response = await http.get(uri);

      log('Story status response: ${response.body}');

      return response;
    } catch (e) {
      log('Error fetching story status: $e');
      rethrow;
    }
  }

  static Future<String> createStory({
    required String text,
    required File voiceFile,
    String language = 'en',
  }) async {
    log('Starting API call to create story');
    log('Story text: $text');
    log('Voice file path: ${voiceFile.path}');

    final uri = Uri.parse('${ApiConfig.baseUrl}/stories/long-story');

    final request = http.MultipartRequest('POST', uri)
      ..fields['text'] = text
      ..fields['language'] = language
      ..fields['chunk_size'] =
          '300' // Default chunk size as per backend contract
      ..files.add(await http.MultipartFile.fromPath('voice', voiceFile.path));

    try {
      log('Send API request: $text');
      final response = await request.send();

      final body = await response.stream.bytesToString();
      log('API response: $body');

      if (response.statusCode != 202) {
        throw Exception('Failed to create story: $body');
      }

      final data = jsonDecode(body);

      return data['story_id'];
    } catch (e) {
      log('Error during API call: $e');
      rethrow;
    }
  }

  static String getChunkUrl(String storyId, int index) {
    log('Get chunk URL for storyId: $storyId, index: $index');
    return '${ApiConfig.baseUrl}/stories/$storyId/chunks/$index';
  }
}
