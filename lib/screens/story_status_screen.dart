import 'dart:async';
import 'dart:convert';
import 'package:frontend/screens/story_player_screen.dart';

import '../api/story_api.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StoryStatusScreen extends StatefulWidget {
  final String storyId;

  const StoryStatusScreen({super.key, required this.storyId});

  @override
  State<StoryStatusScreen> createState() => _StoryStatusScreenState();
}

class _StoryStatusScreenState extends State<StoryStatusScreen> {
  Timer? _pollingTimer;

  String _status = 'processing';
  int _totalChunks = 0;
  int _completedChunks = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchStatus(),
    );
  }

  Future<void> _fetchStatus() async {
    try {
      final response = await StoryApi.getStoryStatus(widget.storyId);

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final chunks = data['chunks'] as List;
      final completed = chunks.where((c) => c['status'] == 'ready').length;

      setState(() {
        _status = data['status'];
        _totalChunks = data['total_chunks'];
        _completedChunks = completed;
        _loading = false;
      });

      if (_status == 'ready' || _status == 'failed') {
        _pollingTimer?.cancel();
      }
    } catch (e) {
      debugPrint('Failed to fetch story status: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatusText() {
    String text;

    switch (_status) {
      case 'processing':
        text = '🎙️ Creating your story…';
        break;
      case 'ready':
        text = '✅ Your story is ready!';
        break;
      case 'failed':
        text = '❌ Story generation failed';
        break;
      default:
        text = 'Preparing your story…';
    }

    return Text(text, style: Theme.of(context).textTheme.headlineSmall);
  }

  double get _progress {
    if (_totalChunks == 0) return 0;
    return _completedChunks / _totalChunks;
  }

  Widget _buildProgressBar() {
    if (_status != 'processing') return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 12),
        Text(
          '${(_progress * 100).toInt()}% completed',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'You can leave this screen, generation will continue.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    switch (_status) {
      case 'processing':
        return const SizedBox();

      case 'failed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Something went wrong while generating your story.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        );

      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryPlayerScreen(
                    storyId: widget.storyId,
                    totalChunks: _totalChunks,
                  ),
                ),
              );
            },
            child: const Text('▶ Play story'),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Story List'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusText(),
                  const SizedBox(height: 16),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                ],
              ),
      ),
    );
  }
}
