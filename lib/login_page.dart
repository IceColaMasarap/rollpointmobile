import 'package:flutter/material.dart';
import 'widgets/camouflage_background.dart';
import 'register_page.dart'; // 👈 add this at the top

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String demoUsername = 'demo@attendeee.com';
  static const String demoPassword = 'demo123';

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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
    });

    if (_usernameController.text == demoUsername &&
        _passwordController.text == demoPassword) {
      setState(() {
        _successMessage = 'Login successful! Redirecting to dashboard...';
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        _showDashboardDialog();
      });
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password.';
      });
    }
  }

  void _showDashboardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to Attendeee Dashboard!'),
        content: const Text(
          'Demo credentials:\nUsername: demo@attendeee.com\nPassword: demo123',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 768;

            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: isWideScreen ? const EdgeInsets.all(20) : EdgeInsets.zero,
                  constraints: isWideScreen
                      ? const BoxConstraints(maxWidth: 1000)
                      : const BoxConstraints.expand(), // full screen on mobile
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 10),
                  Text(
                    'Attendeee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 32 : 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Streamline attendance tracking with smart QR technology',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: compact ? 16 : 18,
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(
                color: const Color(0xFF1f2937),
                fontSize: compact ? 24 : 29,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your instructor account',
              style: TextStyle(
                color: const Color(0xFF6b7280),
                fontSize: compact ? 14 : 15,
              ),
            ),
            const SizedBox(height: 30),
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
              controller: _usernameController,
              label: 'Username or Email',
              hint: 'Enter your username',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              isPassword: true,
            ),
            const SizedBox(height: 25),
            _buildLoginButton(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Color(0xFF6b7280), fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  },
                  child: const Text(
                    'Sign up here',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
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
          obscureText: isPassword,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : const Text('Sign In'),
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
