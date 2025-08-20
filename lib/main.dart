import 'package:flutter/material.dart';
import 'landing_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ← above initialize
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  ); // ← above runApp

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
