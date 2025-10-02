import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class InstructorScannerPage extends StatefulWidget {
  const InstructorScannerPage({super.key});

  @override
  State<InstructorScannerPage> createState() => _InstructorScannerPageState();
}

class _InstructorScannerPageState extends State<InstructorScannerPage> {
  final _supabase = Supabase.instance.client;
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool isProcessingQR = false;
  DateTime? lastScanTime;
  static const String encryptionKey = '12345678901234567890123456789012';
  late final encrypt.Encrypter encrypter;
  
  // Session variables
  String? currentSessionId;
  DateTime? sessionStartTime;
  DateTime? sessionEndTime;
  TimeOfDay cutoffTime = const TimeOfDay(hour: 8, minute: 0);
  bool isSessionActive = false;
  bool isTimeSettingsVisible = false;

  @override
  void initState() {
    super.initState();
    final key = encrypt.Key.fromBase64(base64.encode(encryptionKey.codeUnits.take(32).toList()));
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    try {
      final response = await _supabase
          .from('attendance_sessions')
          .select()
          .eq('is_active', true)
          .eq('created_by', _supabase.auth.currentUser!.id)
          .gte('end_time', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final session = response.first;
        setState(() {
          currentSessionId = session['id'];
          sessionStartTime = DateTime.parse(session['start_time']);
          sessionEndTime = DateTime.parse(session['end_time']);
          final cutoffTimeStr = session['cutoff_time'] as String;
          final parts = cutoffTimeStr.split(':');
          cutoffTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          isSessionActive = true;
        });
      }
    } catch (e) {
      print('Error checking active session: $e');
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
          'QR Scanner',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isTimeSettingsVisible = !isTimeSettingsVisible;
              });
            },
            icon: const Icon(Icons.schedule),
            tooltip: 'Session Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Session Settings Panel
              if (isTimeSettingsVisible) _buildSessionSettingsPanel(),

              // Session Status Banner
              _buildSessionStatusBanner(),

              // Camera Preview Area
              SizedBox(
                height: 350,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Show scanner only if session is active
                        if (isSessionActive)
                          MobileScanner(
                            controller: cameraController,
                            onDetect: (BarcodeCapture capture) {
                              if (!isProcessingQR && capture.barcodes.isNotEmpty) {
                                // Check cooldown
                                if (lastScanTime != null &&
                                    DateTime.now().difference(lastScanTime!).inSeconds < 2) {
                                  return;
                                }
                                final String? code = capture.barcodes.first.rawValue;
                                _processQRCode(code);
                              }
                            },
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_clock,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Scanner Disabled',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a session to begin scanning',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      
                        // Scanner overlay
                        if (isSessionActive)
                          Center(
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF059669),
                                  width: 6,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                      
                        // Processing indicator
                        if (isProcessingQR)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF059669),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Processing QR Code...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Instructions
              _buildInstructions(),

              // Bottom Actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatusBanner() {
    if (!isSessionActive) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No active session. Create one to start scanning.',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final isExpired = now.isAfter(sessionEndTime!);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? const Color(0xFFEF4444) : const Color(0xFF059669),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.check_circle_outline,
                color: isExpired ? const Color(0xFFEF4444) : const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              Text(
                isExpired ? 'Session Expired' : 'Active Session',
                style: TextStyle(
                  color: isExpired ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDateTime(sessionStartTime!)} - ${_formatDateTime(sessionEndTime!)}',
            style: TextStyle(
              color: isExpired ? const Color(0xFF991B1B) : const Color(0xFF065F46),
              fontSize: 14,
            ),
          ),
          if (isExpired) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isSessionActive = false;
                  currentSessionId = null;
                  isTimeSettingsVisible = true;
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionSettingsPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Session Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    isTimeSettingsVisible = false;
                  });
                },
                icon: const Icon(Icons.close, size: 20),
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Session Time Range
          const Text(
            'Session Time Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector(
                  'Start',
                  sessionStartTime,
                  () => _selectSessionTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelector(
                  'End',
                  sessionEndTime,
                  () => _selectSessionTime(false),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Cutoff Time
          const Text(
            'Late Cutoff Time',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF059669), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(cutoffTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectCutoffTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Create/Update Session Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canCreateSession() ? _createOrUpdateSession : null,
              icon: Icon(isSessionActive ? Icons.update : Icons.add),
              label: Text(isSessionActive ? 'Update Session' : 'Start New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String label, DateTime? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? _formatDateTime(time) : 'Not set',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateSession() {
    return sessionStartTime != null && 
           sessionEndTime != null && 
           sessionStartTime!.isBefore(sessionEndTime!);
  }

  Future<void> _selectSessionTime(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (timePicked != null) {
        final dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );

        setState(() {
          if (isStart) {
            sessionStartTime = dateTime;
          } else {
            sessionEndTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _selectCutoffTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: cutoffTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != cutoffTime) {
      setState(() {
        cutoffTime = picked;
      });
    }
  }

  Future<void> _createOrUpdateSession() async {
    try {
      // Deactivate old sessions
      if (currentSessionId != null) {
        await _supabase
            .from('attendance_sessions')
            .update({'is_active': false})
            .eq('id', currentSessionId!);
      }

      // Create new session
      final response = await _supabase
          .from('attendance_sessions')
          .insert({
            'session_name': 'Session ${DateTime.now().toString().substring(0, 16)}',
            'start_time': sessionStartTime!.toIso8601String(),
            'end_time': sessionEndTime!.toIso8601String(),
            'cutoff_time': '${cutoffTime.hour.toString().padLeft(2, '0')}:${cutoffTime.minute.toString().padLeft(2, '0')}:00',
            'created_by': _supabase.auth.currentUser!.id,
            'is_active': true,
          })
          .select()
          .single();

      setState(() {
        currentSessionId = response['id'];
        isSessionActive = true;
        isTimeSettingsVisible = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session created successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      print('Error creating session: $e');
      _showErrorSnackBar('Failed to create session');
    }
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner,
            color: Color(0xFF059669),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            isSessionActive 
                ? 'Position the QR code within the frame'
                : 'Start a session to begin scanning',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
          if (isSessionActive) ...[
            const SizedBox(height: 8),
            Text(
              'Cutoff: ${_formatTime(cutoffTime)}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isProcessingQR 
                  ? const Color(0xFFFEF3C7)
                  : (isSessionActive ? const Color(0xFFDCFCE7) : const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isProcessingQR 
                        ? const Color(0xFFF59E0B)
                        : (isSessionActive ? const Color(0xFF059669) : const Color(0xFF9CA3AF)),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isProcessingQR 
                      ? 'Processing...' 
                      : (isSessionActive ? 'Scanner Ready' : 'Scanner Disabled'),
                  style: TextStyle(
                    color: isProcessingQR 
                        ? const Color(0xFFF59E0B)
                        : (isSessionActive ? const Color(0xFF059669) : const Color(0xFF6B7280)),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSessionActive ? _toggleFlash : null,
              icon: Icon(isFlashOn ? Icons.flashlight_off : Icons.flashlight_on),
              label: Text(isFlashOn ? 'Flash Off' : 'Flash On'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: const Color(0xFFF3F4F6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isSessionActive ? () => _showManualEntryDialog(context) : null,
              icon: const Icon(Icons.keyboard),
              label: const Text('Manual Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    final time = _formatTime(TimeOfDay.fromDateTime(dateTime));
    return '$date $time';
  }

  String _determineAttendanceStatus(DateTime checkInTime) {
    final cutoffDateTime = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      cutoffTime.hour,
      cutoffTime.minute,
    );
    
    return checkInTime.isAfter(cutoffDateTime) ? 'late' : 'present';
  }

  Future<void> _processQRCode(String? qrData) async {
    if (qrData == null || isProcessingQR || !isSessionActive || currentSessionId == null) return;

    // Check if session has expired
    if (DateTime.now().isAfter(sessionEndTime!)) {
      _showErrorSnackBar('Session has expired. Please create a new session.');
      setState(() {
        isSessionActive = false;
      });
      return;
    }

    setState(() {
      isProcessingQR = true;
    });

    try {
      // Decrypt QR data
      String decryptedData;
      try {
        // First decode the base64 string to get the JSON
        final decodedBytes = base64.decode(qrData);
        final decodedString = utf8.decode(decodedBytes);
        final encryptedJson = jsonDecode(decodedString);
        
        // Extract IV and encrypted data
        final iv = encrypt.IV.fromBase64(encryptedJson['iv']);
        final encrypted = encrypt.Encrypted.fromBase64(encryptedJson['data']);
        
        // Decrypt the actual payload
        decryptedData = encrypter.decrypt(encrypted, iv: iv);
      } catch (e) {
        print('Decryption error: $e');
        _showErrorSnackBar('Invalid QR code format - decryption failed');
        return;
      }
      
      final Map<String, dynamic> qrInfo = jsonDecode(decryptedData);
      
      if (!_isValidQRStructure(qrInfo)) {
        _showErrorSnackBar('Invalid QR code format');
        return;
      }

      final expiresAt = DateTime.parse(qrInfo['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        _showErrorSnackBar('QR code has expired');
        return;
      }

      final qrResponse = await _supabase
          .from('qr_images')
          .select('user_id, is_active')
          .eq('user_id', qrInfo['user_id'])
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (qrResponse.isEmpty) {
        _showErrorSnackBar('QR code not found or inactive');
        return;
      }

      final userId = qrResponse.first['user_id'];

      final userResponse = await _supabase
          .rpc('get_user_with_company_platoon_by_id', params: {'user_uuid': userId});

      if (userResponse.isEmpty) {
        _showErrorSnackBar('User not found');
        return;
      }

      final transformedUser = {
        'id': userResponse.first['id'],
        'firstname': userResponse.first['firstname'],
        'middlename': userResponse.first['middlename'],
        'lastname': userResponse.first['lastname'],
        'extensionname': userResponse.first['extensionname'],
        'student_id': userResponse.first['student_id'],
        'role': userResponse.first['role'],
        'companies': [{'name': userResponse.first['company_name']}],
        'platoons': [{'name': userResponse.first['platoon_name']}],
      };

      // Check if already attended THIS SESSION
      final existingAttendance = await _supabase
          .from('attendance')
          .select('id, status')
          .eq('user_id', userId)
          .eq('session_id', currentSessionId!);

      if (existingAttendance.isNotEmpty) {
        _showWarningDialog(transformedUser, 'Already scanned in this session', existingAttendance.first['status']);
        return;
      }

      final checkInTime = DateTime.now();
      final status = _determineAttendanceStatus(checkInTime);

      await _supabase.from('attendance').insert({
        'user_id': userId,
        'status': status,
        'scanned_by': _supabase.auth.currentUser?.id,
        'created_at': checkInTime.toIso8601String(),
        'session_id': currentSessionId,
        'entry_method': 'qr',
      });

      // Update last scan time for cooldown
      lastScanTime = DateTime.now();

      _showSuccessDialog(transformedUser, status, checkInTime);

    } catch (e) {
      print('Error processing QR code: $e');
      _showErrorSnackBar('Error processing QR code: ${e.toString()}');
    } finally {
      setState(() {
        isProcessingQR = false;
      });
    }
  }

  bool _isValidQRStructure(Map<String, dynamic> qrInfo) {
    return qrInfo.containsKey('user_id') &&
           qrInfo.containsKey('generated_at') &&
           qrInfo.containsKey('expires_at') &&
           qrInfo.containsKey('type') &&
           qrInfo['type'] == 'attendance';
  }

  Future<void> _processManualEntry(String studentId) async {
    if (studentId.trim().isEmpty || !isSessionActive || currentSessionId == null) return;

    // Check if session has expired
    if (DateTime.now().isAfter(sessionEndTime!)) {
      _showErrorSnackBar('Session has expired. Please create a new session.');
      setState(() {
        isSessionActive = false;
      });
      return;
    }

    setState(() {
      isProcessingQR = true;
    });

    try {
      final userResponse = await _supabase
          .rpc('get_user_with_company_platoon_by_student_id', 
               params: {'student_id_param': studentId.trim()});

      if (userResponse.isEmpty) {
        _showErrorSnackBar('Student ID not found');
        return;
      }

      final transformedUser = {
        'id': userResponse.first['id'],
        'firstname': userResponse.first['firstname'],
        'middlename': userResponse.first['middlename'],
        'lastname': userResponse.first['lastname'],
        'extensionname': userResponse.first['extensionname'],
        'student_id': userResponse.first['student_id'],
        'role': userResponse.first['role'],
        'companies': [{'name': userResponse.first['company_name']}],
        'platoons': [{'name': userResponse.first['platoon_name']}],
      };

      final userId = userResponse.first['id'];

      // Check if already attended THIS SESSION
      final existingAttendance = await _supabase
          .from('attendance')
          .select('id, status')
          .eq('user_id', userId)
          .eq('session_id', currentSessionId!);

      if (existingAttendance.isNotEmpty) {
        _showWarningDialog(transformedUser, 'Already scanned in this session', existingAttendance.first['status']);
        return;
      }

      final checkInTime = DateTime.now();
      final status = _determineAttendanceStatus(checkInTime);

      await _supabase.from('attendance').insert({
        'user_id': userId,
        'status': status,
        'scanned_by': _supabase.auth.currentUser?.id,
        'created_at': checkInTime.toIso8601String(),
        'session_id': currentSessionId,
        'entry_method': 'manual',
      });

      _showSuccessDialog(transformedUser, status, checkInTime);

    } catch (e) {
      print('Error processing manual entry: $e');
      _showErrorSnackBar('Student ID not found or error occurred');
    } finally {
      setState(() {
        isProcessingQR = false;
      });
    }
  }

  void _toggleFlash() {
    cameraController.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  void _showSuccessDialog(Map<String, dynamic> userInfo, String status, DateTime checkInTime) {
    final isLate = status == 'late';
    
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLate 
                  ? const Color(0xFFFEF3C7) 
                  : const Color(0xFFDCFCE7),
              ),
              child: Icon(
                isLate ? Icons.schedule_outlined : Icons.check_circle_outline,
                color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                size: 40,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              isLate ? 'Marked as Late' : 'Attendance Recorded',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${userInfo['firstname']} ${userInfo['lastname']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      userInfo['student_id'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    '${userInfo['companies'][0]['name']} - ${userInfo['platoons'][0]['name']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLate ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recorded at ${checkInTime.toString().substring(11, 16)}',
                        style: TextStyle(
                          color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isLate) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cutoff time: ${_formatTime(cutoffTime)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue Scanning',
                  style: TextStyle(
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

  void _showWarningDialog(Map<String, dynamic> userInfo, String message, String existingStatus) {
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF3C7),
              ),
              child: const Icon(
                Icons.warning_amber_outlined,
                color: Color(0xFFF59E0B),
                size: 40,
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Already Recorded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${userInfo['firstname']} ${userInfo['lastname']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      userInfo['student_id'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: existingStatus == 'late' 
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Status: ${existingStatus.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got It',
                  style: TextStyle(
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showManualEntryDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter student ID manually:'),
            const SizedBox(height: 8),
            Text(
              'Current cutoff: ${_formatTime(cutoffTime)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. 2023-77144-ABCD',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processManualEntry(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}