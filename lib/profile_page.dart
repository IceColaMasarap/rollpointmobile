import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Fetch user profile with related data
      final response = await _supabase
          .from('users')
          .select('''
            *,
            addresses(region, province, city, barangay, street),
            schools(name),
            ranks(name),
            companies(name),
            platoons(name)
          ''')
          .eq('id', user.id)
          .single();

      setState(() {
        _userProfile = response;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load profile: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Handle edit profile
            },
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF059669)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Error message display
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
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

              // Profile Header
              Container(
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        _getFullName(),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _userProfile?['student_id'] ?? 'No ID provided',
                        style: const TextStyle(
                          color: Color(0xFF6b7280),
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '${_userProfile?['ranks']?['name'] ?? 'No rank'} - ${_userProfile?['platoons']?['name'] ?? 'No platoon'}',
                        style: const TextStyle(
                          color: Color(0xFF6b7280),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Personal Information
              _buildInfoSection('Personal Information', [
                _buildInfoItem('Full Name', _getFullName()),
                _buildInfoItem('Student ID', _userProfile?['student_id'] ?? 'Not provided'),
                _buildInfoItem('Email', _userProfile?['email'] ?? 'Not provided'),
                _buildInfoItem('Birthday', _formatBirthdate()),
                _buildInfoItem('Sex', _userProfile?['sex'] ?? 'Not specified'),
              ]),

              const SizedBox(height: 16),

              // Address Information
              _buildInfoSection('Address Information', [
                _buildInfoItem('Region', _userProfile?['addresses']?['region'] ?? 'Not specified'),
                _buildInfoItem('Province', _userProfile?['addresses']?['province'] ?? 'Not specified'),
                _buildInfoItem('City/Municipality', _userProfile?['addresses']?['city'] ?? 'Not specified'),
                _buildInfoItem('Barangay', _userProfile?['addresses']?['barangay'] ?? 'Not specified'),
              ]),

              const SizedBox(height: 16),

              // Military/Academic Information
              _buildInfoSection('Military/Academic Information', [
                _buildInfoItem('School/Institution', _userProfile?['schools']?['name'] ?? 'Not specified'),
                _buildInfoItem('ID Number', _userProfile?['student_id'] ?? 'Not specified'),
                _buildInfoItem('Rank', _userProfile?['ranks']?['name'] ?? 'Not specified'),
                _buildInfoItem('Company', _userProfile?['companies']?['name'] ?? 'Not specified'),
                _buildInfoItem('Platoon', _userProfile?['platoons']?['name'] ?? 'Not specified'),
              ]),

              const SizedBox(height: 24),

              // Action Buttons
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {
                      // Handle change password
                    },
                  ),

                  const SizedBox(height: 12),



                  _buildActionButton(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      // Handle help
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildActionButton(
                    icon: Icons.info_outline,
                    title: 'About App',
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6b7280), fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6b7280), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF6b7280),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFullName() {
    if (_userProfile == null) return 'Loading...';
    
    final firstName = _userProfile!['firstname'] ?? '';
    final middleName = _userProfile!['middlename'] ?? '';
    final lastName = _userProfile!['lastname'] ?? '';
    final extension = _userProfile!['extensionname'] ?? '';
    
    String fullName = '$firstName';
    if (middleName.isNotEmpty) fullName += ' $middleName';
    if (lastName.isNotEmpty) fullName += ' $lastName';
    if (extension.isNotEmpty) fullName += ' $extension';
    
    return fullName.isNotEmpty ? fullName : 'No name provided';
  }

  String _formatBirthdate() {
    if (_userProfile == null || _userProfile!['birthdate'] == null) {
      return 'Not specified';
    }
    
    try {
      final birthdate = DateTime.parse(_userProfile!['birthdate']);
      return "${birthdate.month.toString().padLeft(2, '0')}/${birthdate.day.toString().padLeft(2, '0')}/${birthdate.year}";
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'About App',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendeee - QR Attendance System'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Military Academy Attendance Tracker'),
            SizedBox(height: 16),
            Text(
              'This app helps track student attendance using QR code technology for military academy institutions.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF059669),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF6b7280)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6b7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Logout from Supabase
                await _supabase.auth.signOut();

                // Close the dialog
                Navigator.of(context).pop();

                // Navigate to login page (replace current stack)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}