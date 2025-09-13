import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'login_page.dart';
import 'mainScreen.dart';
import 'instructor/instructor_main_screen.dart';
import 'ProfileSetupPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase directly (like your working project)
  await Supabase.initialize(
    url: 'https://ndkzicvwclpxwzypvdcq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ka3ppY3Z3Y2xweHd6eXB2ZGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NTAyOTYsImV4cCI6MjA3MTIyNjI5Nn0.tWontQlnV_7uxwWH-Mf4bj7w5Pv8m6lc9Kuedfm5ONQ',
  );

  print('Supabase initialized successfully');

  runApp(const AttendeeApp());
}

class AttendeeApp extends StatelessWidget {
  const AttendeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendeee',
      theme: ThemeData(fontFamily: 'Inter', primarySwatch: Colors.green),
      home: const AuthChecker(), // Use AuthChecker instead of LandingPage
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldRemember = prefs.getBool('remember_me') ?? false;
      
      if (shouldRemember) {
        final email = prefs.getString('saved_email');
        final password = prefs.getString('saved_password');
        
        if (email != null && password != null) {
          // Attempt auto-login
          final supabase = Supabase.instance.client;
          
          final response = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (response.session != null) {
            // Fetch user info including status
            final userResponse = await supabase
                .from('users')
                .select('is_configured, role, status')
                .eq('id', response.user!.id)
                .single();

            final String status = userResponse['status'] ?? 'active';

            if (status == 'archived') {
              // Clear saved credentials and go to landing page
              await _clearSavedCredentials();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                );
              }
              return;
            }

            final bool isConfigured = userResponse['is_configured'] ?? false;
            final String userRole = userResponse['role'] ?? 'Student';

            // Navigate to appropriate screen
            if (mounted) {
              if (!isConfigured) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                );
              } else if (userRole == 'Instructor') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const InstructorMainScreen()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              }
            }
            return;
          } else {
            // Auto-login failed, clear credentials
            await _clearSavedCredentials();
          }
        }
      }
      
      // No saved credentials or auto-login failed, go to landing page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    } catch (error) {
      print('Auto-login error: $error');
      // Clear potentially invalid credentials
      await _clearSavedCredentials();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    }
  }

  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checking authentication
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF059669),
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6b7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}