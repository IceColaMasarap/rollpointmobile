import 'package:flutter/material.dart';
import 'widgets/camouflage_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _extensionController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ✅ NEW Controllers
  final _schoolController = TextEditingController();

  DateTime? _birthday;
  String? _selectedSex;
  String? _selectedCompany;
  String? _selectedPlatoon;
  String? _selectedRank; // ✅ NEW

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _agreeTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _extensionController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolController.dispose(); // ✅ NEW
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _successMessage = "Account created successfully!";
    });
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
            child: FadeTransition(
              opacity: _fadeAnimation,
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
                        ? _buildWideLayout()
                        : _buildNarrowLayout(),
                  );
                },
              ),
            ),
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
          padding: EdgeInsets.all(compact ? 20 : 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📝', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 28 : 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Join Attendeee and manage attendance effortlessly!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: compact ? 14 : 16,
                ),
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
                "Sign Up",
                style: TextStyle(
                  color: const Color(0xFF1f2937),
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w700,
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

              // ✅ Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: "First Name",
                      hint: "Enter first name",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _middleNameController,
                      label: "Middle Name",
                      hint: "Enter middle name",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: "Last Name",
                      hint: "Enter last name",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      controller: _extensionController,
                      label: "Extension",
                      hint: "e.g., Jr., Sr.",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ✅ ID Number
              _buildTextField(
                controller: _idNumberController,
                label: "ID Number",
                hint: "Enter your ID number",
              ),
              const SizedBox(height: 15),

              // ✅ NEW: Rank Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Rank",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                value: _selectedRank,
                items:
                    [
                          "Private",
                          "Corporal",
                          "Sergeant",
                          "Lieutenant",
                          "Captain",
                          "Major",
                          "Colonel",
                        ]
                        .map(
                          (rank) =>
                              DropdownMenuItem(value: rank, child: Text(rank)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _selectedRank = value),
                validator: (value) => value == null ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // ✅ NEW: School Field
              _buildTextField(
                controller: _schoolController,
                label: "School",
                hint: "Enter your school name",
              ),
              const SizedBox(height: 15),

              // ✅ Birthday Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _birthday = picked;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Birthday",
                      hintText: "Select your birthday",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _birthday != null
                          ? "${_birthday!.year}-${_birthday!.month}-${_birthday!.day}"
                          : "",
                    ),
                    validator: (value) => _birthday == null ? "Required" : null,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ✅ Sex Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Sex",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                value: _selectedSex,
                items: ["Male", "Female", "Prefer not to say"]
                    .map(
                      (sex) => DropdownMenuItem(value: sex, child: Text(sex)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedSex = value),
                validator: (value) => value == null ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // ✅ Company Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Company",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                value: _selectedCompany,
                items: ["Alpha", "Bravo", "Charlie", "Delta"]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCompany = value),
                validator: (value) => value == null ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // ✅ Platoon Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Platoon",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                value: _selectedPlatoon,
                items: ["1st Platoon", "2nd Platoon", "3rd Platoon"]
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPlatoon = value),
                validator: (value) => value == null ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // ✅ Email
              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "Enter your email address",
              ),
              const SizedBox(height: 15),

              // ✅ Password
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                hint: "Enter your password",
                isPassword: true,
              ),
              const SizedBox(height: 15),

              // ✅ Confirm Password
              _buildTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                hint: "Re-enter your password",
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (value != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ✅ Terms and Conditions
              Row(
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Terms page
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: "I agree to the ",
                          style: TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: "Terms and Conditions",
                              style: TextStyle(
                                color: Color(0xFF059669),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ Sign Up Button
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

              // ✅ Login link
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
          obscureText: isPassword,
          validator:
              validator ??
              (value) => value?.isEmpty ?? true ? "Required" : null,
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
