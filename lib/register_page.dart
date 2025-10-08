import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/camouflage_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  SupabaseClient get _supabase => Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeTerms) {
      setState(() {
        _errorMessage = "You must agree to the Terms and Conditions";
      });
      return;
    }
    
    if (!_agreePrivacy) {
      setState(() {
        _errorMessage = "You must agree to the Data Privacy Consent";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        setState(() {
          _successMessage =
              "Account created successfully! Please check your email for verification.";
        });
        _showVerificationModal();
      }
    } on AuthException catch (authError) {
      setState(() {
        if (authError.message.toLowerCase().contains('email')) {
          _errorMessage =
              "Registration failed: This email is already registered or invalid";
        } else if (authError.message.toLowerCase().contains('password')) {
          _errorMessage =
              "Registration failed: Password does not meet requirements";
        } else {
          _errorMessage = "Registration failed: ${authError.message}";
        }
      });
    } catch (error) {
      setState(() {
        _errorMessage =
            "Registration failed: An unexpected error occurred. Please try again.";
      });
      print("Registration error: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTermsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTermsSection(
                  '1. Acceptance of Terms',
                  'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
                ),
                _buildTermsSection(
                  '2. Use License',
                  'Permission is granted to temporarily use this application for personal, non-commercial transitory viewing only.',
                ),
                _buildTermsSection(
                  '3. User Account',
                  'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
                ),
                _buildTermsSection(
                  '4. Prohibited Activities',
                  'You may not access or use the application for any purpose other than that for which we make the application available. The application may not be used in connection with any commercial endeavors.',
                ),
                _buildTermsSection(
                  '5. Termination',
                  'We may terminate or suspend your account and bar access to the application immediately, without prior notice or liability, under our sole discretion.',
                ),
                _buildTermsSection(
                  '6. Modifications',
                  'We reserve the right to modify or replace these Terms at any time. It is your responsibility to check these Terms periodically for changes.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Data Privacy Consent',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTermsSection(
                  'Information We Collect',
                  'We collect information that you provide directly to us, including your name, email address, and other contact information.',
                ),
                _buildTermsSection(
                  'How We Use Your Information',
                  'We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to comply with legal obligations.',
                ),
                _buildTermsSection(
                  'Data Security',
                  'We implement appropriate technical and organizational measures to protect your personal information against unauthorized or unlawful processing and accidental loss, destruction, or damage.',
                ),
                _buildTermsSection(
                  'Your Rights',
                  'You have the right to access, correct, or delete your personal information. You may also object to or restrict certain processing of your data.',
                ),
                _buildTermsSection(
                  'Data Retention',
                  'We retain your personal information only for as long as necessary to fulfill the purposes for which it was collected and to comply with legal obligations.',
                ),
                _buildTermsSection(
                  'Contact Us',
                  'If you have any questions about this Privacy Policy, please contact us through the appropriate channels provided in the application.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6b7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 60,
                color: Color(0xFF059669),
              ),
              const SizedBox(height: 20),
              const Text(
                'Almost there!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification link to\n${_emailController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please confirm your email address before logging in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Got it!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf0fdf4), Color(0xFFecfdf5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 768;
                return Container(
                  margin: isWideScreen
                      ? const EdgeInsets.all(20)
                      : EdgeInsets.zero,
                  constraints: isWideScreen
                      ? const BoxConstraints(maxWidth: 1000)
                      : const BoxConstraints.expand(),
                  child: isWideScreen
                      ? _buildWideLayout(isWideScreen)
                      : _buildNarrowLayout(isWideScreen),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(bool isWideScreen) {
    return _cardWrapper(
      Row(
        children: [
          Expanded(child: _buildLeftSide()),
          Expanded(child: _buildRightSide()),
        ],
      ),
      isWideScreen,
    );
  }

  Widget _buildNarrowLayout(bool isWideScreen) {
    return _cardWrapper(
      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 180, child: _buildLeftSide(compact: true)),
            _buildRightSide(compact: true),
          ],
        ),
      ),
      isWideScreen,
    );
  }

  Widget _cardWrapper(Widget child, bool isWideScreen) {
    final borderRadius = isWideScreen
        ? BorderRadius.circular(16)
        : BorderRadius.zero;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: isWideScreen
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 20),
                ),
              ]
            : [],
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }

  Widget _buildLeftSide({bool compact = false}) {
    return CamouflageBackground(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 20 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/logoName1.png',
                height: compact ? 70 : 110,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightSide({bool compact = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Join Us",
                style: TextStyle(
                  color: const Color(0xFF1f2937),
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            Text(
              'Create an account',
              style: TextStyle(
                color: const Color(0xFF6b7280),
                fontSize: compact ? 14 : 15,
              ),
            ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                _buildMessage(
                  _errorMessage!,
                  Colors.red,
                  const Color(0xFFfef2f2),
                ),
              if (_successMessage != null)
                _buildMessage(
                  _successMessage!,
                  Colors.green,
                  const Color(0xFFf0fdf4),
                ),

              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "Enter your email address",
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Email is required";
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(value!)) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _passwordController,
                label: "Password",
                hint: "Enter your password",
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Password is required";
                  if (value!.length < 8) {
                    return "Password must be at least 8 characters";
                  }
                  final passwordRegex = RegExp(
                    r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=[\]{};:"\\|,.<>/?]).{8,}$',
                  );
                  if (!passwordRegex.hasMatch(value)) {
                    return "Password must contain at least one uppercase letter, one number, and one special character";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                hint: "Re-enter your password",
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return "Confirm password is required";
                  if (value != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Terms and Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF059669),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: _showTermsModal,
                        child: const Text.rich(
                          TextSpan(
                            text: "I agree to the ",
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Terms and Conditions",
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Data Privacy Consent Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreePrivacy,
                    onChanged: (value) {
                      setState(() {
                        _agreePrivacy = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF059669),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: _showPrivacyModal,
                        child: const Text.rich(
                          TextSpan(
                            text: "I agree to the ",
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Data Privacy Consent",
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text("Sign Up"),
              ),
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Color(0xFF6b7280), fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Login here",
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText ?? isPassword,
          validator: validator ?? (value) => value?.isEmpty ?? true ? "Required" : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            errorMaxLines: 3,
            helperMaxLines: 3,
            suffixIcon: isPassword && onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscureText ?? true
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF6b7280),
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(String msg, Color color, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(msg, style: TextStyle(color: color)),
    );
  }
}