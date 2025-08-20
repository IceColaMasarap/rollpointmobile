import 'package:flutter/material.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  int _currentStep = 0;

  // Controllers for text inputs
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _extensionController = TextEditingController();

  final _birthdayController = TextEditingController();
  String? _selectedSex;
  final _addressController = TextEditingController();

  final _schoolController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _rankController = TextEditingController();
  final _companyController = TextEditingController();
  final _platoonController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _extensionController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _schoolController.dispose();
    _idNumberController.dispose();
    _rankController.dispose();
    _companyController.dispose();
    _platoonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        backgroundColor: const Color(0xFF059669),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            // ✅ Final Step Complete - Handle Save
            _finishSetup();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          // STEP 1 - Name
          Step(
            title: const Text("Name"),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                _buildTextField(_firstNameController, "First Name"),
                const SizedBox(height: 10),
                _buildTextField(_middleNameController, "Middle Name"),
                const SizedBox(height: 10),
                _buildTextField(_lastNameController, "Last Name"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Extension",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Jr.", child: Text("Jr.")),
                    DropdownMenuItem(value: "Sr.", child: Text("Sr.")),
                    DropdownMenuItem(value: "II", child: Text("II")),
                    DropdownMenuItem(value: "III", child: Text("III")),
                  ],
                  onChanged: (value) {
                    _extensionController.text = value ?? "";
                  },
                ),
              ],
            ),
          ),

          // STEP 2 - Personal
          Step(
            title: const Text("Personal"),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                _buildTextField(_birthdayController, "Birthday (MM/DD/YYYY)"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Sex",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                  ],
                  onChanged: (value) {
                    _selectedSex = value;
                  },
                ),
                const SizedBox(height: 10),
                _buildTextField(_addressController, "Address"),
              ],
            ),
          ),

          // STEP 3 - School/Work
          Step(
            title: const Text("Details"),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                _buildTextField(_schoolController, "School"),
                const SizedBox(height: 10),
                _buildTextField(_idNumberController, "ID Number"),
                const SizedBox(height: 10),
                _buildTextField(_rankController, "Rank"),
                const SizedBox(height: 10),
                _buildTextField(_companyController, "Company"),
                const SizedBox(height: 10),
                _buildTextField(_platoonController, "Platoon"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _finishSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profile Completed"),
        content: const Text("Your details have been saved successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 🚀 TODO: Navigate to Dashboard page here
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
