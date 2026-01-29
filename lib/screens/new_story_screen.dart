import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/story_api.dart';
import '../api/voice_api.dart';
import '../models/voice_item.dart';
import 'new_voice_screen.dart';
import 'story_status_screen.dart';

class NewStoryScreen extends StatefulWidget {
  const NewStoryScreen({super.key});

  @override
  State<NewStoryScreen> createState() => _NewStoryScreenState();
}

class _NewStoryScreenState extends State<NewStoryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  bool _isLoading = false;

  late Future<List<VoiceItem>> _voiceListFuture;
  VoiceItem? _selectedVoice;
  String? _pendingSelectVoiceId;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  void _loadVoices({String? selectVoiceId}) {
    _pendingSelectVoiceId = selectVoiceId;
    _voiceListFuture = VoiceApi.getVoiceList();

    // Preselect after load (either a newly created voice or the first voice)
    _voiceListFuture.then((voices) {
      if (!mounted) return;
      final desiredId = _pendingSelectVoiceId;
      VoiceItem? nextSelected;
      if (desiredId != null) {
        for (final v in voices) {
          if (v.id == desiredId) {
            nextSelected = v;
            break;
          }
        }
      }
      nextSelected ??= voices.isNotEmpty ? voices.first : null;
      setState(() {
        _selectedVoice = nextSelected;
        _pendingSelectVoiceId = null;
      });
    }).catchError((_) {
      // FutureBuilder will render the error state
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.book, color: Colors.white),
            SizedBox(width: 8),
            Text('Tell Your Story', style: TextStyle(color: Colors.white)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Your Story',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Enter story title',
                  labelText: 'Story Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _storyController,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Once upon a time...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              _buildVoicePicker(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ||
                        _storyController.text.trim().isEmpty ||
                        _selectedVoice == null
                    ? null
                    : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Tell the Story', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoicePicker() {
    return FutureBuilder<List<VoiceItem>>(
      future: _voiceListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Failed to load voices: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => setState(() => _loadVoices()),
                icon: const Icon(Icons.refresh),
                label: Text('Retry', style: GoogleFonts.poppins()),
              ),
            ],
          );
        }

        final voices = snapshot.data ?? const <VoiceItem>[];

        if (voices.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'No voices yet. Upload one to get started.',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openNewVoiceScreen,
                icon: const Icon(Icons.upload_file),
                label: Text('Upload new voice', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<VoiceItem>(
              value: _selectedVoice != null &&
                      voices.any((v) => v.id == _selectedVoice!.id)
                  ? voices.firstWhere((v) => v.id == _selectedVoice!.id)
                  : (voices.isNotEmpty ? voices.first : null),
              items: voices
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '${v.name} (${v.language.toUpperCase()})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedVoice = v),
              decoration: InputDecoration(
                labelText: 'Voice',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openNewVoiceScreen,
              icon: const Icon(Icons.add),
              label: Text('Add new voice', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNewVoiceScreen() async {
    final createdVoiceId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const NewVoiceScreen()),
    );
    if (!mounted) return;
    if (createdVoiceId != null && createdVoiceId.isNotEmpty) {
      setState(() => _loadVoices(selectVoiceId: createdVoiceId));
    } else {
      // If user backed out, still refresh in case voices changed
      setState(() => _loadVoices());
    }
  }

  Future<void> _onSubmit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storyId = await StoryApi.createStory(
        text: _storyController.text.trim(),
        title: _titleController.text.trim(),
        voiceId: _selectedVoice!.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Story created: $storyId')));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoryStatusScreen(storyId: storyId)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

