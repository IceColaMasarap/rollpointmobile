import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart'; // make sure path is correct
import 'auth_utils.dart'; // Import the new utility class
import 'edit_address_page.dart'; // Add this import

class InstructorSettingsPage extends StatefulWidget {
  const InstructorSettingsPage({super.key});

  @override
  State<InstructorSettingsPage> createState() => _InstructorSettingsPageState();
}

class _InstructorSettingsPageState extends State<InstructorSettingsPage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? errorMessage = null; // ✅ Add this

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
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    String? dialogErrorMessage; // Add this local variable

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: const Color.fromARGB(
                      255,
                      55,
                      139,
                      58,
                    ), // lock color set to green
                  ),
                  const SizedBox(width: 8),
                  const Text('Change Password'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter your current password to verify your identity, then set a new password.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: currentPasswordController,
                        obscureText: !showCurrentPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'Current Password *',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                showCurrentPassword = !showCurrentPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      if (dialogErrorMessage != null) ...[
                        Text(
                          dialogErrorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 16),
                      TextField(
                        controller: newPasswordController,
                        obscureText: !showNewPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'New Password *',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                showNewPassword = !showNewPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(
                            () {},
                          ); // Trigger rebuild for validation feedback
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password *',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          errorText:
                              confirmPasswordController.text.isNotEmpty &&
                                  newPasswordController.text !=
                                      confirmPasswordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        onChanged: (value) {
                          setState(
                            () {},
                          ); // Trigger rebuild for validation feedback
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password strength indicator
                      if (newPasswordController.text.isNotEmpty) ...[
                        const Text(
                          'Password Strength:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildPasswordStrengthIndicator(
                          newPasswordController.text,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ), // makes the text white
                      decoration:
                          TextDecoration.none, // removes underline (if any)
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      isLoading ||
                          !_isFormValid(
                            currentPasswordController.text,
                            newPasswordController.text,
                            confirmPasswordController.text,
                          )
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            dialogErrorMessage = null; // Clear previous errors
                          });

                          try {
                            // ✅ Add try-catch here
                            await _performPasswordChange(
                              context,
                              currentPasswordController.text,
                              newPasswordController.text,
                              confirmPasswordController.text,
                            );
                          } catch (error) {
                            // ✅ Catch the error here
                            setState(() {
                              dialogErrorMessage = error.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                          setState(() {
                            isLoading = false;
                          });
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                            color: Colors.white, // makes the text white
                            decoration: TextDecoration
                                .none, // removes underline (if any)
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  bool _isFormValid(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) {
    return currentPassword.isNotEmpty &&
        newPassword.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        newPassword.length >= 6 && // Change from 8 to 6
        newPassword == confirmPassword;
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = _calculatePasswordStrength(password);
    Color color;
    String label;

    if (strength < 3) {
      color = Colors.red;
      label = 'Weak';
    } else if (strength < 5) {
      color = Colors.orange;
      label = 'Medium';
    } else {
      color = Colors.green;
      label = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 6) strength++; // Change from 8 to 6
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength;
  }

  Future<void> _performPasswordChange(
    BuildContext context,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      // Step 1: Verify current password by attempting to sign in
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('User not found');
      }

      // Attempt to sign in with current credentials to verify current password
      try {
        final AuthResponse response = await _supabase.auth.signInWithPassword(
          email: user!.email!,
          password: currentPassword,
        );

        if (response.user == null) {
          throw Exception('Current password is incorrect');
        }
      } catch (e) {
        throw Exception('Current password is incorrect');
      }

      // Step 2: Validate new password
      if (newPassword != confirmPassword) {
        throw Exception('New passwords do not match');
      }

      if (newPassword.length < 6) {
        throw Exception(
          'New password must be at least 6 characters long',
        ); // Update message
      }

      if (currentPassword == newPassword) {
        throw Exception('New password must be different from current password');
      }

      // Step 3: Update the password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      // Step 5: Show success message and close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Password changed successfully!',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (error) {
      throw error; // ✅ This will be caught by the try-catch in the button's onPressed
    }
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
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Military Information'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedSchoolId,
                    decoration: const InputDecoration(
                      labelText: 'School',
                      border: OutlineInputBorder(),
                    ),
                    items: schools.map<DropdownMenuItem<int>>((school) {
                      return DropdownMenuItem<int>(
                        value: school['id'],
                        child: Text(school['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
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
                      setState(() {
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
                      setState(() {
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
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => EditAddressPage(
        currentAddress: _userProfile?['addresses'],
      ),
    ),
  );
  
  // If address was updated successfully, refresh the profile
  if (result == true) {
    await _loadUserProfile();
  }
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
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
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
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6B7280),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
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
        _buildInfoRow('School', _userProfile?['schools'] != null ? _userProfile!['schools']['name'] : 'Not set'),
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
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logout Icon with background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFEE2E2),
            ),
            child: const Icon(
              Icons.logout_outlined,
              color: Color(0xFFDC2626),
              size: 40,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Logout Confirmation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Message
          const Text(
            'Are you sure you want to log out?\nYou will need to sign in again.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Logout Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Show loading state
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Logging out...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    
                    try {
                      // Clear saved credentials for "Remember Me"
                      await AuthUtils.clearSavedCredentials();
                      
                      // Sign out from Supabase
                      await Supabase.instance.client.auth.signOut();
                      
                      if (context.mounted) {
                        // Close loading dialog
                        Navigator.pop(context);
                        // Close logout dialog
                        Navigator.pop(context);
                        // Navigate to login
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        // Close loading dialog
                        Navigator.pop(context);
                        // Close logout dialog
                        Navigator.pop(context);
                        
                        // Show error with improved styling
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Error logging out: $error',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

}