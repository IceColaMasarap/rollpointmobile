import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/camouflage_background.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _currentStep = 0; // 0: email, 1: verification code, 2: new password
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _fullCode => _codeControllers.map((c) => c.text).join();

  Future<void> _sendResetEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'your-app://reset-password',
      );

      setState(() {
        _currentStep = 1;
        _successMessage = 'Verification code sent to ${_emailController.text}';
      });
    } on AuthException catch (authError) {
      setState(() {
        _errorMessage = authError.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to send reset email. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_fullCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Verify the OTP code and get the session
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: _fullCode,
        email: _emailController.text.trim(),
      );

      // Check if we have a valid session
      if (response.session != null) {
        setState(() {
          _currentStep = 2;
          _successMessage = null; // Clear success message
        });
      } else {
        setState(() {
          _errorMessage = 'Verification failed. Please try again.';
        });
      }
    } on AuthException {
      setState(() {
        _errorMessage = 'Invalid or expired code. Please try again.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePassword() async {
  if (!_resetFormKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
  });

  try {
    // Update password through Supabase Auth
    await _supabase.auth.updateUser(
      UserAttributes(
        password: _newPasswordController.text.trim(),
      ),
    );

    // Get current user
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Hash the password before saving to password_history
      final plainPassword = _newPasswordController.text.trim();
      final passwordBytes = utf8.encode(plainPassword);
      final passwordHash = sha256.convert(passwordBytes).toString();

      await _supabase.from('password_history').insert({
        'user_id': user.id,
        'password_hash': passwordHash,
      });
    }

    setState(() {
      _successMessage = 'Password reset successfully!';
    });

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  } on AuthException catch (authError) {
    setState(() {
      _errorMessage = authError.message;
    });
  } catch (error) {
    setState(() {
      _errorMessage = 'Failed to reset password. Please try again.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 768;

              return Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: isWideScreen
                        ? const EdgeInsets.all(20)
                        : EdgeInsets.zero,
                    constraints: isWideScreen
                        ? const BoxConstraints(maxWidth: 1000)
                        : const BoxConstraints.expand(),
                    child: isWideScreen
                        ? _buildWideLayout()
                        : _buildNarrowLayout(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return _cardWrapper(
      Row(
        children: [
          Expanded(child: _buildLeftSide()),
          Expanded(child: _buildRightSide()),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 200, child: _buildLeftSide(compact: true)),
          _buildRightSide(compact: true),
        ],
      ),
    );
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  Widget _buildLeftSide({bool compact = false}) {
    return CamouflageBackground(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 30 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentStep == 0
                    ? Icons.lock_outline
                    : _currentStep == 1
                    ? Icons.email_outlined
                    : Icons.password_outlined,
                size: compact ? 60 : 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _getStepTitle(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getStepSubtitle(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: compact ? 14 : 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightSide({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 30 : 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
              ),
              Text(
                _getPageTitle(),
                style: TextStyle(
                  color: const Color(0xFF1f2937),
                  fontSize: compact ? 24 : 29,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPageSubtitle(),
            style: TextStyle(
              color: const Color(0xFF6b7280),
              fontSize: compact ? 14 : 15,
            ),
          ),
          const SizedBox(height: 30),
          if (_errorMessage != null)
            _buildMessage(_errorMessage!, Colors.red, const Color(0xFFfef2f2)),
          if (_successMessage != null)
            _buildMessage(
              _successMessage!,
              Colors.green,
              const Color(0xFFf0fdf4),
            ),
          _buildCurrentStepForm(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepForm() {
    switch (_currentStep) {
      case 0:
        return _buildEmailForm();
      case 1:
        return _buildVerificationForm();
      case 2:
        return _buildNewPasswordForm();
      default:
        return _buildEmailForm();
    }
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 25),
          _buildButton(
            text: 'Send Verification Code',
            onPressed: _isLoading ? null : _sendResetEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          _buildCodeInput(),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 0;
              });
            },
            child: const Text(
              'Resend Code',
              style: TextStyle(
                color: Color(0xFF059669),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 25),
          _buildButton(
            text: 'Verify Code',
            onPressed: _isLoading ? null : _verifyCode,
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          _buildTextField(
  controller: _newPasswordController,
  label: 'New Password',
  hint: 'Enter new password',
  isPassword: true,
  obscureText: !_showNewPassword,
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
  suffixIcon: IconButton(
    icon: Icon(
      _showNewPassword ? Icons.visibility_off : Icons.visibility,
      color: const Color(0xFF6b7280),
    ),
    onPressed: () {
      setState(() {
        _showNewPassword = !_showNewPassword;
      });
    },
  ),
),

          const SizedBox(height: 20),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm new password',
            isPassword: true,
            obscureText: !_showConfirmPassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6b7280),
              ),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
          ),

          const SizedBox(height: 25),
          _buildButton(
            text: 'Save New Password',
            onPressed: _isLoading ? null : _updatePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFd1d5db)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Center(
            child: TextField(
              controller: _codeControllers[index],
              focusNode: _codeFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1f2937),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
              onChanged: (value) {
                if (value.length == 1 && index < 5) {
                  _codeFocusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _codeFocusNodes[index - 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator:
              validator ??
              (value) => value?.isEmpty ?? true ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            errorMaxLines: 3,

          ),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text(text),
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

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password';
      case 1:
        return 'Verify Your Email';
      case 2:
        return 'Create New Password';
      default:
        return 'Forgot Password';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your email address to receive an OTP';
      case 1:
        return 'Check your email for the verification code';
      case 2:
        return 'Set your new secure password';
      default:
        return 'Enter your email address to receive a verification code';
    }
  }

  String _getPageTitle() {
    switch (_currentStep) {
      case 0:
        return 'Forgot Password';
      case 1:
        return 'Verify Your Email';
      case 2:
        return 'Create New Password';
      default:
        return 'Forgot Password';
    }
  }

  String _getPageSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Please Enter Your Email Address To Receive a Verification Code';
      case 1:
        return 'Please Enter The 6 Digit Code Sent To Your Email';
      case 2:
        return 'Your New Password Must Be Different From Previously Used Password';
      default:
        return 'Please Enter Your Email Address To Receive a Verification Code';
    }
  }
}
