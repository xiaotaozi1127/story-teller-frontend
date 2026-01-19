import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../api/story_api.dart';

class StoryPlayerScreen extends StatefulWidget {
  final String storyId;
  final int totalChunks;

  const StoryPlayerScreen({
    super.key,
    required this.storyId,
    required this.totalChunks,
  });

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();

  int _currentChunk = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playChunk(0);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextChunk();
      }
    });
  }

  Future<void> _playChunk(int index) async {
    if (index >= widget.totalChunks) {
      setState(() => _isPlaying = false);
      return;
    }

    final url = StoryApi.getChunkUrl(widget.storyId, index);

    await _player.setUrl(url);
    await _player.play();

    setState(() {
      _currentChunk = index;
      _isPlaying = true;
    });
  }

  void _playNextChunk() {
    _playChunk(_currentChunk + 1);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playing story')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playing chunk ${_currentChunk + 1} / ${widget.totalChunks}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: (_currentChunk + 1) / widget.totalChunks,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isPlaying ? null : () => _playChunk(_currentChunk),
              child: const Text('Play'),
            ),
          ],
        ),
      ),
    );
  }
}
