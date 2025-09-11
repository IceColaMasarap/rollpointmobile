import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SupabaseClient get _supabase => Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final response = await _supabase
          .from('users')
          .select('''
            *,
            ranks(name),
            schools(name),
            companies(name),
            platoons(name),
            addresses(region, province, city, barangay, street)
          ''')
          .eq('id', user.id)
          .single();

      setState(() {
        _userProfile = response;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Change Password'),
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _supabase.auth.updateUser(
                    UserAttributes(password: newPasswordController.text),
                  );
                  
                  // Store password history
                  final user = _supabase.auth.currentUser;
                  if (user != null) {
                    await _supabase.from('password_history').insert({
                      'user_id': user.id,
                      'password_hash': newPasswordController.text, // In production, hash this
                    });
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error changing password: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPersonalInfo() async {
    final TextEditingController firstNameController = 
        TextEditingController(text: _userProfile?['firstname'] ?? '');
    final TextEditingController lastNameController = 
        TextEditingController(text: _userProfile?['lastname'] ?? '');
    final TextEditingController middleNameController = 
        TextEditingController(text: _userProfile?['middlename'] ?? '');
    final TextEditingController emailController = 
        TextEditingController(text: _userProfile?['email'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Personal Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: middleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Middle Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                    enabled: false, // 🔒 makes it read-only/disabled
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Save Changes'),
              onPressed: () async {
                try {
                  final user = _supabase.auth.currentUser;
                  if (user == null) return;

                  await _supabase.from('users').update({
                    'firstname': firstNameController.text,
                    'lastname': lastNameController.text,
                    'middlename': middleNameController.text,
                    'email': emailController.text,
                  }).eq('id', user.id);

                  await _loadUserProfile(); // Refresh profile data

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Personal information updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editMilitaryInfo() async {
  // Controllers for military information
  final TextEditingController idNumberController = 
      TextEditingController(text: _userProfile?['student_id'] ?? '');
  
  // Fetch lists from database
  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> platoons = [];
  List<Map<String, dynamic>> schools = [];
  
  try {
    final companiesResponse = await _supabase
        .from('companies')
        .select('id, name')
        .order('name');
    companies = List<Map<String, dynamic>>.from(companiesResponse);
    
    final platoonsResponse = await _supabase
        .from('platoons')
        .select('id, name')
        .order('name');
    platoons = List<Map<String, dynamic>>.from(platoonsResponse);
    
    final schoolsResponse = await _supabase
        .from('schools')
        .select('id, name')
        .order('name');
    schools = List<Map<String, dynamic>>.from(schoolsResponse);
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }
  
  // Get current values - use IDs instead of names for comparison
  int? selectedCompanyId = _userProfile?['company_id'];
  int? selectedPlatoonId = _userProfile?['platoon_id'];
  int? selectedSchoolId = _userProfile?['school_id'];

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) { // Changed from setState to setDialogState
          return AlertDialog(
            title: const Text('Edit Military Information'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedSchoolId,
                    decoration: const InputDecoration(
                      labelText: 'School/Institution',
                      border: OutlineInputBorder(),
                    ),
                    items: schools.map<DropdownMenuItem<int>>((school) {
                      return DropdownMenuItem<int>(
                        value: school['id'],
                        child: Text(school['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() { // Use setDialogState instead of setState
                        selectedSchoolId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: idNumberController,
                      enabled: false, // 🔒 makes it read-only/disabled
                    decoration: const InputDecoration(
                      labelText: 'ID Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      border: OutlineInputBorder(),
                    ),
                    items: companies.map<DropdownMenuItem<int>>((company) {
                      return DropdownMenuItem<int>(
                        value: company['id'],
                        child: Text(company['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() { // Use setDialogState instead of setState
                        selectedCompanyId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedPlatoonId,
                    decoration: const InputDecoration(
                      labelText: 'Platoon',
                      border: OutlineInputBorder(),
                    ),
                    items: platoons.map<DropdownMenuItem<int>>((platoon) {
                      return DropdownMenuItem<int>(
                        value: platoon['id'],
                        child: Text(platoon['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() { // Use setDialogState instead of setState
                        selectedPlatoonId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
                child: const Text('Save Changes'),
                onPressed: () async {
                  try {
                    final user = _supabase.auth.currentUser;
                    if (user == null) return;

                    await _supabase.from('users').update({
                      'student_id': idNumberController.text,
                      'school_id': selectedSchoolId,
                      'company_id': selectedCompanyId,
                      'platoon_id': selectedPlatoonId,
                    }).eq('id', user.id);

                    await _loadUserProfile(); // Refresh profile data

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Military information updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating military information: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

  Future<void> _editAddressInfo() async {
    final address = _userProfile?['addresses'] ?? {};
    
    final TextEditingController regionController = 
        TextEditingController(text: address['region'] ?? '');
    final TextEditingController provinceController = 
        TextEditingController(text: address['province'] ?? '');
    final TextEditingController cityController = 
        TextEditingController(text: address['city'] ?? '');
    final TextEditingController barangayController = 
        TextEditingController(text: address['barangay'] ?? '');
    final TextEditingController streetController = 
        TextEditingController(text: address['street'] ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Address Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: regionController,
                  decoration: const InputDecoration(
                    labelText: 'Region',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: provinceController,
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: barangayController,
                  decoration: const InputDecoration(
                    labelText: 'Barangay',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(
                    labelText: 'Street',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
              child: const Text('Save Changes'),
              onPressed: () async {
                try {
                  final user = _supabase.auth.currentUser;
                  if (user == null) return;

                  await _supabase.from('addresses').update({
                    'region': regionController.text,
                    'province': provinceController.text,
                    'city': cityController.text,
                    'barangay': barangayController.text,
                    'street': streetController.text,
                  }).eq('id', user.id);

                  await _loadUserProfile(); // Refresh profile data

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address information updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating address: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Personal Information Section
                    _buildSection(
                      title: 'Personal Information',
                      onEdit: _editPersonalInfo,
                      content: _buildPersonalInfoContent(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Military Information Section
                    _buildSection(
                      title: 'Military Information',
                      onEdit: _editMilitaryInfo,
                      content: _buildMilitaryInfoContent(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Address Information Section
                    _buildSection(
                      title: 'Address Information',
                      onEdit: _editAddressInfo,
                      content: _buildAddressInfoContent(),
                    ),
                    
                    const SizedBox(height: 24),

                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildSettingCard(
                      icon: Icons.lock_outlined,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: _changePassword,
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            
            // Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_userProfile?['firstname'] ?? ''} ${_userProfile?['lastname'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile?['email'] ?? 'No email set',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'ID: ${_userProfile?['student_id'] ?? _userProfile?['id'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required VoidCallback onEdit,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('First Name', _userProfile?['firstname'] ?? 'Not set'),
        _buildInfoRow('Last Name', _userProfile?['lastname'] ?? 'Not set'),
        _buildInfoRow('Middle Name', _userProfile?['middlename'] ?? 'Not set'),
        _buildInfoRow('Email', _userProfile?['email'] ?? 'Not set'),
      ],
    );
  }

  Widget _buildMilitaryInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('School/Institution', _userProfile?['schools'] != null ? _userProfile!['schools']['name'] : 'Not set'),
        _buildInfoRow('ID Number', _userProfile?['student_id'] ?? 'Not set'),
        _buildInfoRow('Company', _userProfile?['companies'] != null ? _userProfile!['companies']['name'] : 'Not set'),
        _buildInfoRow('Platoon', _userProfile?['platoons'] != null ? _userProfile!['platoons']['name'] : 'Not set'),
      ],
    );
  }

  Widget _buildAddressInfoContent() {
    final address = _userProfile?['addresses'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Region', address['region'] ?? 'Not set'),
        _buildInfoRow('Province', address['province'] ?? 'Not set'),
        _buildInfoRow('City', address['city'] ?? 'Not set'),
        _buildInfoRow('Barangay', address['barangay'] ?? 'Not set'),
        _buildInfoRow('Street', address['street'] ?? 'Not set'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF059669),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6B7280),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabase.auth.signOut();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (error) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}