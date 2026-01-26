import 'dart:async';
import 'dart:convert';
import 'package:frontend/screens/story_player_screen.dart';

import '../api/story_api.dart';

import 'package:flutter/material.dart';

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
  double _totalDurationSeconds = 0.0;

  double _targetProgress = 0.0; // real backend progress

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
      final total = data['total_chunks'] as int;
      final newProgress = data['progress_percentage'] as double;

      setState(() {
        _status = data['status'];
        _totalChunks = data['total_chunks'];
        _completedChunks = completed;
        _targetProgress = newProgress;
        _totalDurationSeconds = (data['total_duration_seconds'] as num?)?.toDouble() ?? 0.0;
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
    if (_completedChunks == 0) {
      text = 'Preparing voice model…';
    } else if (_status == 'processing') {
      text = 'Generating story audio…';
    } else if (_status == 'ready') {
      text = 'Story ready 🎉';
    } else {
      text = 'Generation failed';
    }

    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildProgressBar() {
    if (_status != 'processing') return const SizedBox();

    final percent = (_targetProgress).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: _targetProgress / 100),
        const SizedBox(height: 12),
        Text(
          '$percent% completed',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'You can leave this screen. Generation will continue.',
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
                    totalDurationSeconds: _totalDurationSeconds,
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
                  const SizedBox(height: 20),
                  _buildProgressBar(),
                  const SizedBox(height: 28),
                  _buildActionButton(),
                ],
              ),
      ),
    );
  }
}
