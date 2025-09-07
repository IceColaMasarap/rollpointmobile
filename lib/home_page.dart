import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'widgets/camouflage_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  String? currentQRData;
  bool isGeneratingQR = false;
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadOrGenerateQR();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('users')
          .select('''
            firstname, middlename, lastname, extensionname,
            student_id, role,
            companies!inner(name),
            platoons!inner(name)
          ''')
          .eq('id', user.id)
          .single();

      setState(() {
        userInfo = response;
      });
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadOrGenerateQR() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if user has an active QR code
      final response = await _supabase
          .from('qr_images')
          .select('qr_data')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          currentQRData = response.first['qr_data'];
        });
      } else {
        // Generate new QR code
        await _generateNewQR();
      }
    } catch (e) {
      print('Error loading QR: $e');
      // Generate new QR if loading fails
      await _generateNewQR();
    }
  }

  Future<void> _generateNewQR() async {
    if (isGeneratingQR) return;
    
    setState(() {
      isGeneratingQR = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24)); // QR expires in 24 hours

      // Create QR data
      final qrData = jsonEncode({
        'user_id': user.id,
        'generated_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'type': 'attendance',
        'version': '1.0'
      });

      // Create hash for the QR data
      final bytes = utf8.encode(qrData);
      final hash = sha256.convert(bytes).toString();

      // Deactivate old QR codes for this user
      await _supabase
          .from('qr_images')
          .update({'is_active': false})
          .eq('user_id', user.id);

      // Insert new QR code
      await _supabase.from('qr_images').insert({
        'user_id': user.id,
        'qr_data': qrData,
        'qr_hash': hash,
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
      });

      setState(() {
        currentQRData = qrData;
        isGeneratingQR = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New QR code generated successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isGeneratingQR = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildQRCodeSection() {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // QR Code
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF059669),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: currentQRData != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QrImageView(
                        data: currentQRData!,
                        version: QrVersions.auto,
                        size: 192,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // QR Info
            if (currentQRData != null)
              Text(
                'Valid for 24 hours',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 16),

            // Generate New Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isGeneratingQR ? null : _generateNewQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isGeneratingQR
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        currentQRData != null ? 'Generate New' : 'Generate QR Code',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: CamouflageBackground(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Greetings,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            userInfo != null 
                                ? '${userInfo!['firstname'] ?? ''} ${userInfo!['lastname'] ?? ''}'.trim()
                                : 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userInfo?['student_id'] ?? 'Loading...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            userInfo != null
                                ? '${userInfo!['role']} - ${userInfo!['platoons']?['name'] ?? 'No Platoon'}'
                                : 'Loading...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // QR Code Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildQRCodeSection(),

                    const SizedBox(height: 30),

                    // Today's Status Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Status",
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Present - 08:34 AM',
                                    style: TextStyle(
                                      color: Color(0xFF374151),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'On time',
                                    style: TextStyle(
                                      color: Color(0xFF6b7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Recent Attendance Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Attendance',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle see all
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Recent Attendance Items
                    _buildAttendanceItem(
                      date: 'Aug 20, 2025',
                      time: '08:34 AM',
                      status: 'Present',
                      isPresent: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceItem(
                      date: 'Aug 19, 2025',
                      time: '08:45 AM',
                      status: 'Present',
                      isPresent: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceItem(
                      date: 'Aug 18, 2025',
                      time: 'No record',
                      status: 'Absent',
                      isPresent: false,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceItem({
    required String date,
    required String time,
    required String status,
    required bool isPresent,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isPresent
                    ? const Color(0xFF059669)
                    : const Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF6b7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPresent
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isPresent
                      ? const Color(0xFF059669)
                      : const Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}