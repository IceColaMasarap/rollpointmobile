import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
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
  Map<String, dynamic>? todayStatus;
  List<Map<String, dynamic>> recentAttendance = [];

  // Encryption key - in production, this should be stored securely
  static const String encryptionKey = '12345678901234567890123456789012';
  late final encrypt.Encrypter encrypter;

  @override
  void initState() {
    super.initState();
    // Initialize encryption
    final key = encrypt.Key.fromBase64(
      base64.encode(encryptionKey.codeUnits.take(32).toList()),
    );
    encrypter = encrypt.Encrypter(encrypt.AES(key));

    _loadUserInfo();
    _loadOrGenerateQR();
    _loadTodayStatus();
    _loadRecentAttendance();
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

  Future<void> _loadTodayStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select('status, created_at')
          .eq('user_id', user.id)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final attendance = response.first;
        final createdAt = DateTime.parse(attendance['created_at']);

        setState(() {
          todayStatus = {'status': attendance['status'], 'time': createdAt};
        });
      } else {
        setState(() {
          todayStatus = null;
        });
      }
    } catch (e) {
      print('Error loading today status: $e');
    }
  }

  Future<void> _loadRecentAttendance() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('attendance')
          .select('status, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        recentAttendance = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading recent attendance: $e');
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

  String _encryptQRData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Combine IV and encrypted data
    final combined = {
      'iv': iv.base64,
      'data': encrypted.base64,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return base64.encode(utf8.encode(jsonEncode(combined)));
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
      final expiresAt = now.add(
        const Duration(hours: 24),
      ); // QR expires in 24 hours

      // Create QR data
      final qrPayload = jsonEncode({
        'user_id': user.id,
        'generated_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'type': 'attendance',
        'version': '1.0',
      });

      // Encrypt the QR data
      final encryptedQRData = _encryptQRData(qrPayload);

      // Create hash for the original QR data
      final bytes = utf8.encode(qrPayload);
      final hash = sha256.convert(bytes).toString();

      // Upsert QR code (deactivate old ones and insert new one)
      await _supabase.rpc(
        'upsert_user_qr',
        params: {
          'p_user_id': user.id,
          'p_qr_data': encryptedQRData,
          'p_qr_hash': hash,
          'p_expires_at': expiresAt.toIso8601String(),
        },
      );

      setState(() {
        currentQRData = encryptedQRData;
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
            // Custom QR Code with branding
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF059669).withOpacity(0.1),
                    const Color(0xFF047857).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: currentQRData != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: _buildCustomQRCode(),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // QR Info with enhanced styling
            if (currentQRData != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF059669),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Valid for 24 hours',
                      style: TextStyle(
                        color: const Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Encrypted & Secure',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Enhanced Generate New Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isGeneratingQR ? null : _generateNewQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isGeneratingQR
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Generating...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            currentQRData != null
                                ? 'Generate New QR'
                                : 'Generate QR Code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomQRCode() {
    return Stack(
      children: [
        // QR Code with custom colors
        Container(
          padding: const EdgeInsets.all(12),
          child: QrImageView(
            data: currentQRData!,
            version: QrVersions.auto,
            size: double.infinity,
            backgroundColor: Colors.white,
            foregroundColor: const Color(
              0xFF1F2937,
            ), // Dark gray instead of pure black
            errorCorrectionLevel:
                QrErrorCorrectLevel.H, // High error correction for logo overlay
            gapless: false,
            embeddedImage:
                null, // We'll add our logo separately for better control
          ),
        ),

        // Center logo/brand overlay
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF059669), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF059669), const Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'lib/assets/logoR.png', // Add your logo to assets
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Corner decoration elements (optional branding)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatusCard() {
    if (todayStatus == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          border: Border.all(color: const Color(0xFFE3DFFE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Status",
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No record yet',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Scan QR to mark attendance',
                      style: TextStyle(color: Color(0xFF6b7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = todayStatus!['status'] as String;
    final time = todayStatus!['time'] as DateTime;
    final isPresent = status == 'present';
    final isLate = status == 'late';

    Color statusColor;
    Color bgColor;
    Color borderColor;
    String statusText;
    String timeText;

    if (isPresent) {
      statusColor = const Color(0xFF059669);
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      statusText = 'Present';
      timeText = 'On time';
    } else if (isLate) {
      statusColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFE3DFFE);
      statusText = 'Late';
      timeText = 'After cutoff time';
    } else {
      statusColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFECACA);
      statusText = 'Absent';
      timeText = 'No record';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Status",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$statusText - ${_formatTime(time)}',
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    timeText,
                    style: const TextStyle(
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
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
                                ? '${userInfo!['firstname'] ?? ''} ${userInfo!['lastname'] ?? ''}'
                                      .trim()
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
                    _buildTodayStatusCard(),

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
                            // Handle see all - you can navigate to attendance history page
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
                    if (recentAttendance.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                        child: const Text(
                          'No attendance records yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...recentAttendance.map((attendance) {
                        final date = DateTime.parse(attendance['created_at']);
                        final status = attendance['status'] as String;
                        final isPresent = status == 'present';
                        final isLate = status == 'late';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildAttendanceItem(
                            date: _formatDate(date),
                            time: _formatTime(date),
                            status: status.toUpperCase(),
                            isPresent: isPresent || isLate,
                            isLate: isLate,
                          ),
                        );
                      }).toList(),

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
    bool isLate = false,
  }) {
    Color statusColor;
    Color bgColor;

    if (isLate) {
      statusColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFEF3C7);
    } else if (isPresent) {
      statusColor = const Color(0xFF059669);
      bgColor = const Color(0xFFDCFCE7);
    } else {
      statusColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEE2E2);
    }

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
                color: statusColor,
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
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
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
