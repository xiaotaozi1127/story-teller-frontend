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
  bool _isPlaying = true;
  bool _isFinished = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _playChunk(0);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextChunk();
      }
      // Update UI based on actual player state
      setState(() {
        _isPlaying = state.playing;
      });
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      setState(() {
        _totalDuration = duration ?? Duration.zero;
      });
    });
  }

  Future<void> _playChunk(int index) async {
    if (index >= widget.totalChunks) {
      setState(() {
        _isPlaying = false;
        _isFinished = true;
      });
      return;
    }
    setState(() => _isFinished = false);

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

  Future<void> _pausePlayback() async {
    await _player.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _resumePlayback() async {
    await _player.play();
    setState(() => _isPlaying = true);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
              value: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds /
                        _totalDuration.inMilliseconds
                  : 0,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isFinished
                      ? () => _playChunk(0)
                      : (_isPlaying ? _pausePlayback : _resumePlayback),
                  child: Text(
                    _isFinished
                        ? 'Play from beginning'
                        : (_isPlaying ? 'Pause' : 'Resume'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
