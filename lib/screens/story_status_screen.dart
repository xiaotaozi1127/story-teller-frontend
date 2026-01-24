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
    return Text(
      'Status: $_status',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildProgressBar() {
    if (_totalChunks == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: _completedChunks / _totalChunks),
        const SizedBox(height: 8),
        Text('$_completedChunks / $_totalChunks chunks generated'),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_status == 'processing') {
      return const Text('Generating voice...');
    }

    if (_status == 'failed') {
      return const Text(
        'Story generation failed',
        style: TextStyle(color: Colors.red),
      );
    }

    return ElevatedButton(
      onPressed: () {
        // NEXT STEP: navigate to audio playback
        debugPrint('Go to story player screen');
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
      child: const Text('Play story'),
    );
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
