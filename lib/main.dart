import 'package:flutter/material.dart';
import 'landing_page.dart';

void main() {
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
