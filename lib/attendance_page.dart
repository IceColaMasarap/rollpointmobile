import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> attendanceSessions = [];
  Map<String, dynamic> stats = {
    'present': 0,
    'late': 0,
    'absent': 0,
    'total': 0,
  };
  bool isLoading = true;
  String selectedFilter = 'All';
  String? selectedSessionId;
  String selectedSessionDisplay = 'All Sessions';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadAttendanceSessions(),
      _loadAttendanceData(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadAttendanceSessions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No user found');
        return;
      }

      // Get all sessions where the user has attendance
      final response = await _supabase
          .from('attendance')
          .select('session_id, attendance_sessions(id, session_name, start_time, end_time)')
          .eq('user_id', user.id)
          .not('session_id', 'is', null);

      print('Sessions response: $response');

      // Extract unique sessions
      final sessionsMap = <String, Map<String, dynamic>>{};
      for (var record in response) {
        if (record['session_id'] != null && record['attendance_sessions'] != null) {
          final sessionData = record['attendance_sessions'];
          final sessionId = sessionData['id'];
          if (!sessionsMap.containsKey(sessionId)) {
            sessionsMap[sessionId] = sessionData;
          }
        }
      }

      setState(() {
        attendanceSessions = sessionsMap.values.toList()
          ..sort((a, b) => DateTime.parse(b['start_time'])
              .compareTo(DateTime.parse(a['start_time'])));
      });
    } catch (e, stackTrace) {
      print('Error loading attendance sessions: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No user found in _loadAttendanceData');
        return;
      }

      var query = _supabase
          .from('attendance')
          .select('status, created_at, session_id, attendance_sessions(session_name, start_time)')
          .eq('user_id', user.id);

      // Apply session filter if selected
      if (selectedSessionId != null) {
        query = query.eq('session_id', selectedSessionId!);
      }

      // Apply ordering after all filters
      final response = await query.order('created_at', ascending: false);

      print('Attendance data response: ${response.length} records');

      int presentCount = 0;
      int lateCount = 0;
      int absentCount = 0;

      // If a specific session is selected, calculate stats for that session
      if (selectedSessionId != null) {
        for (var record in response) {
          final status = record['status'] as String;
          if (status == 'present') presentCount++;
          if (status == 'late') lateCount++;
          if (status == 'absent') absentCount++;
        }
        
        final totalDays = presentCount + lateCount + absentCount;
        
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(response);
          stats = {
            'present': presentCount,
            'late': lateCount,
            'absent': absentCount,
            'total': totalDays,
          };
        });
      } else {
        // Original monthly calculation for "All Sessions"
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final attendanceDates = <String>{};

        for (var record in response) {
          final createdAt = DateTime.parse(record['created_at']);
          final status = record['status'] as String;

          if (createdAt.isAfter(startOfMonth)) {
            final dateString =
                '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
            attendanceDates.add(dateString);

            if (status == 'present') presentCount++;
            if (status == 'late') lateCount++;
          }
        }

        // Calculate absent days (weekdays in current month without attendance)
        int weekdaysWithoutAttendance = 0;
        for (int day = 1; day <= now.day; day++) {
          final date = DateTime(now.year, now.month, day);
          // Only count weekdays (Monday = 1, Sunday = 7)
          if (date.weekday <= 5) {
            final dateString =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            if (!attendanceDates.contains(dateString)) {
              weekdaysWithoutAttendance++;
            }
          }
        }

        absentCount = weekdaysWithoutAttendance;
        final totalDays = presentCount + lateCount + absentCount;

        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(response);
          stats = {
            'present': presentCount,
            'late': lateCount,
            'absent': absentCount,
            'total': totalDays,
          };
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
    }
  }

  List<Map<String, dynamic>> get filteredRecords {
    if (selectedFilter == 'All') return attendanceRecords;
    return attendanceRecords
        .where((record) =>
            record['status'].toString().toLowerCase() ==
            selectedFilter.toLowerCase())
        .toList();
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
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF059669),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF059669),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session Filter Dropdown
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
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
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: const Color(0xFF059669),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Select Session',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSessionDropdown(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Enhanced Stats Cards
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF059669).withOpacity(0.1),
                              const Color(0xFF047857).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF059669).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              selectedSessionId != null
                                  ? 'Session Summary'
                                  : 'This Month\'s Summary',
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Present',
                                    stats['present'].toString(),
                                    stats['total'] > 0
                                        ? '${((stats['present'] / stats['total']) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    const Color(0xFF059669),
                                    const Color(0xFFDCFCE7),
                                    Icons.check_circle_outline,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Late',
                                    stats['late'].toString(),
                                    stats['total'] > 0
                                        ? '${((stats['late'] / stats['total']) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    const Color(0xFFF59E0B),
                                    const Color(0xFFFEF3C7),
                                    Icons.schedule,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Absent',
                                    stats['absent'].toString(),
                                    stats['total'] > 0
                                        ? '${((stats['absent'] / stats['total']) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    const Color(0xFFEF4444),
                                    const Color(0xFFFEE2E2),
                                    Icons.cancel_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Filter Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Records',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildFilterDropdown(),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Attendance List
                      if (filteredRecords.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                selectedFilter == 'All'
                                    ? 'No attendance records yet'
                                    : 'No ${selectedFilter.toLowerCase()} records found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your attendance history will appear here',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: filteredRecords.map((record) {
                            final date = DateTime.parse(record['created_at']);
                            final status = record['status'] as String;
                            final sessionInfo = record['attendance_sessions'];
                            String? sessionName;
                            if (sessionInfo != null) {
                              sessionName = sessionInfo['session_name'];
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: _buildAttendanceItem(
                                date: _formatDate(date),
                                time: _formatTime(date),
                                status: status.toUpperCase(),
                                statusType: status,
                                sessionName: sessionName,
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSessionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedSessionId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            setState(() {
              selectedSessionId = newValue;
              if (newValue == null) {
                selectedSessionDisplay = 'All Sessions';
              } else {
                final session = attendanceSessions.firstWhere(
                  (s) => s['id'] == newValue,
                  orElse: () => {'session_name': 'Unknown'},
                );
                selectedSessionDisplay = session['session_name'];
              }
            });
            _loadAttendanceData();
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Sessions'),
            ),
            ...attendanceSessions.map((session) {
              final startTime = DateTime.parse(session['start_time']);
              final displayText =
                  '${_formatTime(startTime)}, ${_formatDate(startTime)}';
              return DropdownMenuItem<String?>(
                value: session['id'],
                child: Text(
                  displayText,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedFilter,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            setState(() {
              selectedFilter = newValue!;
            });
          },
          items: <String>['All', 'Present', 'Late', 'Absent']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, String percentage,
      Color color, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            percentage,
            style: const TextStyle(
              color: Color(0x6b7280),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem({
    required String date,
    required String time,
    required String status,
    required String statusType,
    String? sessionName,
  }) {
    Color statusColor;
    Color bgColor;
    IconData statusIcon;

    switch (statusType) {
      case 'present':
        statusColor = const Color(0xFF059669);
        bgColor = const Color(0xFFDCFCE7);
        statusIcon = Icons.check_circle;
        break;
      case 'late':
        statusColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        statusIcon = Icons.cancel;
        time = 'No record';
    }

    return Container(
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (sessionName != null && selectedSessionId == null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sessionName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}