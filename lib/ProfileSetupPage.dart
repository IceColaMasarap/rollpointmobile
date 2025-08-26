import 'package:flutter/material.dart';
import 'mainScreen.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  int _currentStep = 0;

  // Controllers for text inputs
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedExtension;

  DateTime? _selectedBirthday;
  String? _selectedSex;
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

  String? _selectedSchool;
  final _idNumberController = TextEditingController();
  String? _selectedRank;
  String? _selectedCompany;
  String? _selectedPlatoon;

  // Placeholder data (normally from API/database)
  final List<String> _extensions = ['Jr.', 'Sr.', 'II', 'III', 'IV'];
  final List<String> _sexOptions = ['Male', 'Female'];
  
  // Philippine Address placeholders
  final List<String> _regions = ['NCR', 'CAR', 'Region I', 'Region II', 'Region III', 'Region IV-A (CALABARZON)'];
  final List<String> _provinces = ['Metro Manila', 'Cavite', 'Laguna', 'Batangas', 'Rizal', 'Quezon'];
  final List<String> _cities = ['Bacoor City', 'Imus City', 'Dasmariñas City', 'General Trias City', 'Trece Martires City'];
  final List<String> _barangays = ['Molino I', 'Molino II', 'Molino III', 'Panapaan I', 'Panapaan II'];

  // Military/School data placeholders
  final List<String> _schools = ['School 1', 'School 2', 'School 3', 'Philippine Military Academy'];
  final List<String> _ranks = ['2nd Lieutenant', '1st Lieutenant', 'Captain', 'Major', 'Lieutenant Colonel', 'Colonel'];
  final List<String> _companies = ['Alpha Company', 'Bravo Company', 'Charlie Company', 'Delta Company'];
  final List<String> _platoons = ['1st Platoon', '2nd Platoon', '3rd Platoon', '4th Platoon'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Complete Your Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildProgressIndicator(0, "Name", _currentStep >= 0),
                    _buildProgressIndicator(1, "Personal", _currentStep >= 1),
                    _buildProgressIndicator(2, "Details", _currentStep >= 2),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Previous",
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep < 2 ? "Next" : "Complete Profile",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "${step + 1}",
              style: TextStyle(
                color: isActive ? const Color(0xFF059669) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildPersonalStep();
      case 2:
        return _buildDetailsStep();
      default:
        return Container();
    }
  }

  Widget _buildNameStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Name",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_firstNameController, "First Name", Icons.person),
            const SizedBox(height: 15),
            _buildTextField(_middleNameController, "Middle Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField(_lastNameController, "Last Name", Icons.person),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedExtension,
              items: _extensions,
              hint: "Extension (Optional)",
              icon: Icons.family_restroom,
              onChanged: (value) => setState(() => _selectedExtension = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Information",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            
            // Birthday Date Picker
            InkWell(
              onTap: _selectBirthday,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF059669)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _selectedBirthday != null
                            ? "${_selectedBirthday!.month.toString().padLeft(2, '0')}/${_selectedBirthday!.day.toString().padLeft(2, '0')}/${_selectedBirthday!.year}"
                            : "Select Birthday",
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedBirthday != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            _buildDropdown(
              value: _selectedSex,
              items: _sexOptions,
              hint: "Sex",
              icon: Icons.wc,
              onChanged: (value) => setState(() => _selectedSex = value),
            ),
            const SizedBox(height: 20),
            
            // Address Section
            const Text(
              "Address",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              value: _selectedRegion,
              items: _regions,
              hint: "Region",
              icon: Icons.map,
              onChanged: (value) => setState(() => _selectedRegion = value),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedProvince,
              items: _provinces,
              hint: "Province",
              icon: Icons.location_city,
              onChanged: (value) => setState(() => _selectedProvince = value),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedCity,
              items: _cities,
              hint: "City/Municipality",
              icon: Icons.location_on,
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedBarangay,
              items: _barangays,
              hint: "Barangay",
              icon: Icons.home,
              onChanged: (value) => setState(() => _selectedBarangay = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Military/Academic Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              value: _selectedSchool,
              items: _schools,
              hint: "School/Institution",
              icon: Icons.school,
              onChanged: (value) => setState(() => _selectedSchool = value),
            ),
            const SizedBox(height: 15),
            _buildTextField(_idNumberController, "ID Number", Icons.badge),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedRank,
              items: _ranks,
              hint: "Rank",
              icon: Icons.military_tech,
              onChanged: (value) => setState(() => _selectedRank = value),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedCompany,
              items: _companies,
              hint: "Company",
              icon: Icons.group,
              onChanged: (value) => setState(() => _selectedCompany = value),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedPlatoon,
              items: _platoons,
              hint: "Platoon",
              icon: Icons.groups,
              onChanged: (value) => setState(() => _selectedPlatoon = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _finishSetup();
    }
  }

  void _finishSetup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF059669), size: 30),
            SizedBox(width: 10),
            Text("Profile Completed"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Please review your information:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              
              _buildSummarySection("Name", [
                "First Name: ${_firstNameController.text}",
                "Middle Name: ${_middleNameController.text}",
                "Last Name: ${_lastNameController.text}",
                if (_selectedExtension != null) "Extension: $_selectedExtension",
              ]),
              
              _buildSummarySection("Personal Information", [
                if (_selectedBirthday != null) 
                  "Birthday: ${_selectedBirthday!.month.toString().padLeft(2, '0')}/${_selectedBirthday!.day.toString().padLeft(2, '0')}/${_selectedBirthday!.year}",
                if (_selectedSex != null) "Sex: $_selectedSex",
                if (_selectedRegion != null) "Region: $_selectedRegion",
                if (_selectedProvince != null) "Province: $_selectedProvince",
                if (_selectedCity != null) "City: $_selectedCity",
                if (_selectedBarangay != null) "Barangay: $_selectedBarangay",
              ]),
              
              _buildSummarySection("Military/Academic Details", [
                if (_selectedSchool != null) "School: $_selectedSchool",
                "ID Number: ${_idNumberController.text}",
                if (_selectedRank != null) "Rank: $_selectedRank",
                if (_selectedCompany != null) "Company: $_selectedCompany",
                if (_selectedPlatoon != null) "Platoon: $_selectedPlatoon",
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Edit", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog first
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );

            },
            style: ElevatedButton.styleFrom(
              
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(height: 5),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 2),
          child: Text("• $item", style: const TextStyle(fontSize: 14)),
        )),
        const SizedBox(height: 10),
      ],
    );
  }
}