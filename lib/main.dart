import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase directly (like your working project)
  await Supabase.initialize(
    url: 'https://ndkzicvwclpxwzypvdcq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ka3ppY3Z3Y2xweHd6eXB2ZGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1MDEzNjcsImV4cCI6MjA1MDA3NzM2N30.aQGgBJ0HVkkWwcCrGiMHdq0E1WjNBLNLvQWY2xz2SLM',
  );

  print('Supabase initialized successfully');

  runApp(const AttendeeApp());
}

class AttendeeApp extends StatelessWidget {
  const AttendeeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendeee',
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.green,
      ),
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}