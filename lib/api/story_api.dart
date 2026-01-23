import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/story_list_item.dart' as models;
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
    String title = '',
    String language = 'en',
  }) async {
    log('Starting API call to create story');
    log('Story text: $text');
    log('Story title: $title');
    log('Voice file path: ${voiceFile.path}');

    final uri = Uri.parse('${ApiConfig.baseUrl}/stories');

    final request = http.MultipartRequest('POST', uri)
      ..fields['text'] = text
      ..fields['title'] = title
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

  static Future<List<models.StoryListItem>> getStoryList() async {
    try {
      log('=== getStoryList() called ===');
      final baseUrl = ApiConfig.baseUrl;
      log('API Base URL: $baseUrl');

      final uri = Uri.parse('${baseUrl}/stories');
      log('Fetching story list from: $uri');

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
      log('Story list response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get story list (Status ${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      log('Decoded JSON data: $data');

      if (data is! List<dynamic>) {
        throw Exception(
          'Expected response to be an array, got ${data.runtimeType}: $data',
        );
      }

      final List<dynamic> stories = data;

      log('Successfully parsed ${stories.length} stories');

      return stories.map((story) {
        log('Parsing story: $story (type: ${story.runtimeType})');
        return models.StoryListItem.fromJson(story as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      log('!!! Error fetching story list: $e');
      log('Error type: ${e.runtimeType}');
      log('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}
