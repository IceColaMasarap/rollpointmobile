import 'package:shared_preferences/shared_preferences.dart';

class AuthUtils {
  // Clear saved credentials (for logout and remember me functionality)
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  // Save login credentials
  static Future<void> saveCredentials(String email, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
    } else {
      await clearSavedCredentials();
    }
  }

  // Check if credentials are saved
  static Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'remember_me': prefs.getBool('remember_me') ?? false,
      'email': prefs.getString('saved_email'),
      'password': prefs.getString('saved_password'),
    };
  }

  // Check if user should be automatically logged in
  static Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    
    return rememberMe && email != null && password != null;
  }
}