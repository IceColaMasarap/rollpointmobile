import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

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
  
  // Time selector variables
  TimeOfDay cutoffTime = const TimeOfDay(hour: 8, minute: 0); // Default 8:00 AM
  bool isTimeSettingsVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          'QR Scanner',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
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
            tooltip: 'Time Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Time Settings Panel (collapsible)
            if (isTimeSettingsVisible) _buildTimeSettingsPanel(),

            // Camera Preview Area
            Expanded(
              flex: 3,
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
                      // Mobile Scanner View
                      MobileScanner(
                        controller: cameraController,
                        onDetect: (BarcodeCapture capture) {
                          if (!isProcessingQR && capture.barcodes.isNotEmpty) {
                            final String? code = capture.barcodes.first.rawValue;
                            _processQRCode(code);
                          }
                        },
                      ),
                      
                      // Scanner overlay
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

            // Instructions and Status
            Container(
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
                  const Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cutoff time: ${_formatTime(cutoffTime)} - Late after this time',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isProcessingQR 
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDCFCE7),
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
                                : const Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isProcessingQR ? 'Processing...' : 'Scanner Ready',
                          style: TextStyle(
                            color: isProcessingQR 
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF059669),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Flashlight toggle
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _toggleFlash();
                      },
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Manual entry
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showManualEntryDialog(context);
                      },
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Manual Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildTimeSettingsPanel() {
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
                'Attendance Cutoff Time',
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
          const SizedBox(height: 12),
          const Text(
            'Students arriving after this time will be marked as late',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
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
                          fontSize: 18,
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
          Row(
            children: [
              _buildPresetTimeButton('7:00 AM', const TimeOfDay(hour: 7, minute: 0)),
              const SizedBox(width: 8),
              _buildPresetTimeButton('8:00 AM', const TimeOfDay(hour: 8, minute: 0)),
              const SizedBox(width: 8),
              _buildPresetTimeButton('9:00 AM', const TimeOfDay(hour: 9, minute: 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTimeButton(String label, TimeOfDay time) {
    final isSelected = cutoffTime.hour == time.hour && cutoffTime.minute == time.minute;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            cutoffTime = time;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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

  String _determineAttendanceStatus(DateTime checkInTime) {
    final now = DateTime.now();
    final cutoffDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      cutoffTime.hour,
      cutoffTime.minute,
    );
    
    return checkInTime.isAfter(cutoffDateTime) ? 'late' : 'present';
  }

  Future<void> _processQRCode(String? qrData) async {
    if (qrData == null || isProcessingQR) return;

    setState(() {
      isProcessingQR = true;
    });

    try {
      // Parse the QR data
      final Map<String, dynamic> qrInfo = jsonDecode(qrData);
      
      // Validate QR structure
      if (!_isValidQRStructure(qrInfo)) {
        _showErrorSnackBar('Invalid QR code format');
        return;
      }

      // Check if QR code is expired
      final expiresAt = DateTime.parse(qrInfo['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        _showErrorSnackBar('QR code has expired');
        return;
      }

      // Verify QR code exists in database and is active
      final qrResponse = await _supabase
          .from('qr_images')
          .select('user_id, is_active')
          .eq('qr_data', qrData)
          .eq('is_active', true)
          .single();

      if (qrResponse.isEmpty) {
        _showErrorSnackBar('QR code not found or inactive');
        return;
      }

      final userId = qrResponse['user_id'];

      // Get user information
      final userResponse = await _supabase
          .from('users')
          .select('''
            firstname, middlename, lastname, extensionname,
            student_id, role,
            companies!inner(name),
            platoons!inner(name)
          ''')
          .eq('id', userId)
          .single();

      // Check if user already has attendance today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingAttendance = await _supabase
          .from('attendance')
          .select('id, status')
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      if (existingAttendance.isNotEmpty) {
        _showWarningDialog(userResponse, 'Attendance already recorded today', existingAttendance.first['status']);
        return;
      }

      // Determine attendance status based on cutoff time
      final checkInTime = DateTime.now();
      final status = _determineAttendanceStatus(checkInTime);

      // Record attendance
      await _supabase.from('attendance').insert({
        'user_id': userId,
        'status': status,
        'scanned_by': _supabase.auth.currentUser?.id,
        'created_at': checkInTime.toIso8601String(),
      });

      // Show success dialog
      _showSuccessDialog(userResponse, status, checkInTime);

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
    if (studentId.trim().isEmpty) return;

    setState(() {
      isProcessingQR = true;
    });

    try {
      // Find user by student ID
      final userResponse = await _supabase
          .from('users')
          .select('''
            id, firstname, middlename, lastname, extensionname,
            student_id, role,
            companies!inner(name),
            platoons!inner(name)
          ''')
          .eq('student_id', studentId.trim())
          .single();

      if (userResponse.isEmpty) {
        _showErrorSnackBar('Student ID not found');
        return;
      }

      final userId = userResponse['id'];

      // Check if user already has attendance today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingAttendance = await _supabase
          .from('attendance')
          .select('id, status')
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      if (existingAttendance.isNotEmpty) {
        _showWarningDialog(userResponse, 'Attendance already recorded today', existingAttendance.first['status']);
        return;
      }

      // Determine attendance status based on cutoff time
      final checkInTime = DateTime.now();
      final status = _determineAttendanceStatus(checkInTime);

      // Record attendance
      await _supabase.from('attendance').insert({
        'user_id': userId,
        'status': status,
        'scanned_by': _supabase.auth.currentUser?.id,
        'created_at': checkInTime.toIso8601String(),
        'entry_method': 'manual',
      });

      // Show success dialog
      _showSuccessDialog(userResponse, status, checkInTime);

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
      builder: (context) => AlertDialog(
        icon: Icon(
          isLate ? Icons.schedule : Icons.check_circle,
          color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
          size: 48,
        ),
        title: Text(
          isLate ? 'Marked as Late' : 'Attendance Recorded',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${userInfo['firstname']} ${userInfo['lastname']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              userInfo['student_id'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${userInfo['role']} - ${userInfo['platoons']?['name'] ?? 'No Platoon'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLate ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recorded at ${checkInTime.toString().substring(11, 16)}',
                        style: TextStyle(
                          color: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isLate) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cutoff time: ${_formatTime(cutoffTime)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLate ? const Color(0xFFF59E0B) : const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Scanning'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(Map<String, dynamic> userInfo, String message, String existingStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning,
          color: Color(0xFFF59E0B),
          size: 48,
        ),
        title: const Text(
          'Already Recorded',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${userInfo['firstname']} ${userInfo['lastname']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              userInfo['student_id'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: existingStatus == 'late' 
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current Status: ${existingStatus.toUpperCase()}',
                style: TextStyle(
                  color: existingStatus == 'late' 
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
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