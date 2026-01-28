import 'package:flutter/material.dart';
import 'package:frontend/screens/story_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/story_teller_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Teller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const StoryListScreen(),
      routes: {'/create-story': (context) => const StoryTellerScreen()},
    );
  }
}
