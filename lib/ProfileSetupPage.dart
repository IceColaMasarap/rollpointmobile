import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mainScreen.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

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


  SupabaseClient get _supabase => Supabase.instance.client;


  List<Map<String, dynamic>> _schools = [];
  List<Map<String, dynamic>> _ranks = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _platoons = [];

  // Static data
  final List<String> _extensions = ['Jr.', 'Sr.', 'II', 'III', 'IV'];
  final List<String> _sexOptions = ['Male', 'Female'];
  
  // Philippine Address data (you might want to load these from DB too)
  final List<String> _regions = ['NCR', 'CAR', 'Region I', 'Region II', 'Region III', 'Region IV-A (CALABARZON)'];
  final List<String> _provinces = ['Metro Manila', 'Cavite', 'Laguna', 'Batangas', 'Rizal', 'Quezon'];
  final List<String> _cities = ['Bacoor City', 'Imus City', 'Dasmariñas City', 'General Trias City', 'Trece Martires City'];
  final List<String> _barangays = ['Molino I', 'Molino II', 'Molino III', 'Panapaan I', 'Panapaan II'];

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      // Load schools
      final schoolsResponse = await _supabase
          .from('schools')
          .select('id, name')
          .order('name');

      // Load ranks
      final ranksResponse = await _supabase
          .from('ranks')
          .select('id, name')
          .order('name');

      // Load companies
      final companiesResponse = await _supabase
          .from('companies')
          .select('id, name, school_id')
          .order('name');

      // Load platoons
      final platoonsResponse = await _supabase
          .from('platoons')
          .select('id, name, company_id')
          .order('name');

      setState(() {
        _schools = List<Map<String, dynamic>>.from(schoolsResponse);
        _ranks = List<Map<String, dynamic>>.from(ranksResponse);
        _companies = List<Map<String, dynamic>>.from(companiesResponse);
        _platoons = List<Map<String, dynamic>>.from(platoonsResponse);
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load data: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Name step
        if (_firstNameController.text.trim().isEmpty) {
          _showErrorSnackBar('First name is required');
          return false;
        }
        if (_lastNameController.text.trim().isEmpty) {
          _showErrorSnackBar('Last name is required');
          return false;
        }
        break;

      case 1: // Personal step
        if (_selectedBirthday == null) {
          _showErrorSnackBar('Birthday is required');
          return false;
        }
        if (_selectedSex == null) {
          _showErrorSnackBar('Sex is required');
          return false;
        }
        if (_selectedRegion == null) {
          _showErrorSnackBar('Region is required');
          return false;
        }
        if (_selectedProvince == null) {
          _showErrorSnackBar('Province is required');
          return false;
        }
        if (_selectedCity == null) {
          _showErrorSnackBar('City/Municipality is required');
          return false;
        }
        if (_selectedBarangay == null) {
          _showErrorSnackBar('Barangay is required');
          return false;
        }
        break;

      case 2: // Details step
        if (_selectedSchool == null) {
          _showErrorSnackBar('School/Institution is required');
          return false;
        }
        if (_idNumberController.text.trim().isEmpty) {
          _showErrorSnackBar('ID Number is required');
          return false;
        }
        if (_selectedRank == null) {
          _showErrorSnackBar('Rank is required');
          return false;
        }
        if (_selectedCompany == null) {
          _showErrorSnackBar('Company is required');
          return false;
        }
        if (_selectedPlatoon == null) {
          _showErrorSnackBar('Platoon is required');
          return false;
        }
        break;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get filtered companies based on selected school
  List<Map<String, dynamic>> _getFilteredCompanies() {
    if (_selectedSchool == null) return [];
    
    final selectedSchoolData = _schools.firstWhere(
      (school) => school['name'] == _selectedSchool,
      orElse: () => <String, dynamic>{},
    );
    
    if (selectedSchoolData.isEmpty) return _companies;
    
    return _companies.where((company) => 
      company['school_id'] == selectedSchoolData['id']
    ).toList();
  }

  // Get filtered platoons based on selected company
  List<Map<String, dynamic>> _getFilteredPlatoons() {
    if (_selectedCompany == null) return [];
    
    final selectedCompanyData = _getFilteredCompanies().firstWhere(
      (company) => company['name'] == _selectedCompany,
      orElse: () => <String, dynamic>{},
    );
    
    if (selectedCompanyData.isEmpty) return _platoons;
    
    return _platoons.where((platoon) => 
      platoon['company_id'] == selectedCompanyData['id']
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _schools.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

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

          // Error message display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
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
                      onPressed: _isLoading ? null : () => setState(() => _currentStep--),
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
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
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
            _buildTextField(_firstNameController, "First Name *", Icons.person, required: true),
            const SizedBox(height: 15),
            _buildTextField(_middleNameController, "Middle Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField(_lastNameController, "Last Name *", Icons.person, required: true),
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
                            : "Select Birthday *",
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
              hint: "Sex *",
              icon: Icons.wc,
              onChanged: (value) => setState(() => _selectedSex = value),
              required: true,
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
              hint: "Region *",
              icon: Icons.map,
              onChanged: (value) => setState(() => _selectedRegion = value),
              required: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedProvince,
              items: _provinces,
              hint: "Province *",
              icon: Icons.location_city,
              onChanged: (value) => setState(() => _selectedProvince = value),
              required: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedCity,
              items: _cities,
              hint: "City/Municipality *",
              icon: Icons.location_on,
              onChanged: (value) => setState(() => _selectedCity = value),
              required: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedBarangay,
              items: _barangays,
              hint: "Barangay *",
              icon: Icons.home,
              onChanged: (value) => setState(() => _selectedBarangay = value),
              required: true,
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
              items: _schools.map((school) => school['name'] as String).toList(),
              hint: "School/Institution *",
              icon: Icons.school,
              onChanged: (value) {
                setState(() {
                  _selectedSchool = value;
                  // Reset dependent dropdowns
                  _selectedCompany = null;
                  _selectedPlatoon = null;
                });
              },
              required: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(_idNumberController, "ID Number *", Icons.badge, required: true),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedRank,
              items: _ranks.map((rank) => rank['name'] as String).toList(),
              hint: "Rank *",
              icon: Icons.military_tech,
              onChanged: (value) => setState(() => _selectedRank = value),
              required: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedCompany,
              items: _getFilteredCompanies().map((company) => company['name'] as String).toList(),
              hint: "Company *",
              icon: Icons.group,
              onChanged: (value) {
                setState(() {
                  _selectedCompany = value;
                  // Reset dependent dropdown
                  _selectedPlatoon = null;
                });
              },
              required: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedPlatoon,
              items: _getFilteredPlatoons().map((platoon) => platoon['name'] as String).toList(),
              hint: "Platoon *",
              icon: Icons.groups,
              onChanged: (value) => setState(() => _selectedPlatoon = value),
              required: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
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
          borderSide: BorderSide(
            color: required && controller.text.trim().isEmpty 
                ? Colors.red 
                : const Color(0xFF059669), 
            width: 2
          ),
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
    bool required = false,
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
          borderSide: BorderSide(
            color: required && value == null 
                ? Colors.red 
                : const Color(0xFF059669), 
            width: 2
          ),
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
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get IDs for foreign keys
      final selectedSchoolData = _schools.firstWhere(
        (school) => school['name'] == _selectedSchool
      );
      final selectedRankData = _ranks.firstWhere(
        (rank) => rank['name'] == _selectedRank
      );
      final selectedCompanyData = _getFilteredCompanies().firstWhere(
        (company) => company['name'] == _selectedCompany
      );
      final selectedPlatoonData = _getFilteredPlatoons().firstWhere(
        (platoon) => platoon['name'] == _selectedPlatoon
      );

      // Update users table with profile data
      await _supabase.from('users').update({
        'firstname': _firstNameController.text.trim(),
        'middlename': _middleNameController.text.trim().isEmpty 
            ? null 
            : _middleNameController.text.trim(),
        'lastname': _lastNameController.text.trim(),
        'extensionname': _selectedExtension,
        'birthdate': _selectedBirthday!.toIso8601String().split('T')[0],
        'sex': _selectedSex,
        'region': _selectedRegion,
        'province': _selectedProvince,
        'city': _selectedCity,
        'barangay': _selectedBarangay,
        'school_id': selectedSchoolData['id'],
        'student_id': _idNumberController.text.trim(),
        'rank_id': selectedRankData['id'],
        'company_id': selectedCompanyData['id'],
        'platoon_id': selectedPlatoonData['id'],
        'is_configured': true, // Mark as configured
      }).eq('id', user.id);

      // Navigate to main screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }

    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to save profile: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}