import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceLogPage extends StatefulWidget {
  final int? companyId;
  final String? companyName;
  final int? platoonId;
  final String? platoonName;

  const AttendanceLogPage({
    super.key,
    this.companyId,
    this.companyName,
    this.platoonId,
    this.platoonName,
  });

  @override
  State<AttendanceLogPage> createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends State<AttendanceLogPage> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  List<Map<String, dynamic>> availableCompanies = [];
  List<Map<String, dynamic>> availablePlatoons = [];
  
  Map<String, dynamic> summaryStats = {
    'totalRecords': 0,
    'present': 0,
    'absent': 0,
    'late': 0,
  };
  
  int? selectedCompanyId;
  String selectedCompanyName = 'All Companies';
  int? selectedPlatoonId;
  String selectedPlatoonName = 'All Platoons';
  
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use passed values as defaults if available
    selectedCompanyId = widget.companyId;
    selectedCompanyName = widget.companyName ?? 'All Companies';
    selectedPlatoonId = widget.platoonId;
    selectedPlatoonName = widget.platoonName ?? 'All Platoons';
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadAvailableCompaniesAndPlatoons();
    await _loadAttendanceData();
  }

  Future<void> _loadAvailableCompaniesAndPlatoons() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get instructor's assigned companies and platoons
      final assignmentsResponse = await _supabase
          .from('instructor_assignments')
          .select('''
            company_id, platoon_id,
            companies(id, name),
            platoons(id, name)
          ''')
          .eq('instructor_id', userId);

      // Extract unique companies
      final Map<int, Map<String, dynamic>> companiesMap = {};
      final Map<int, Map<String, dynamic>> platoonsMap = {};

      for (final assignment in assignmentsResponse) {
        final company = assignment['companies'];
        final platoon = assignment['platoons'];
        
        companiesMap[company['id']] = {
          'id': company['id'],
          'name': company['name'],
        };
        
        platoonsMap[platoon['id']] = {
          'id': platoon['id'],
          'name': platoon['name'],
          'company_id': assignment['company_id'],
        };
      }

      setState(() {
        availableCompanies = companiesMap.values.toList();
        availablePlatoons = platoonsMap.values.toList();
      });

    } catch (e) {
      print('Error loading companies and platoons: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get date range for selected date
      final startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endDate = startDate.add(const Duration(days: 1));

      // First, get all students based on selection
      List<Map<String, dynamic>> allStudents = [];
      
      if (selectedCompanyId != null && selectedPlatoonId != null) {
        // Specific company and platoon
        final studentsResponse = await _supabase
            .from('users')
            .select('id, firstname, lastname, student_id, company_id, platoon_id')
            .eq('role', 'Student')
            .eq('company_id', selectedCompanyId!)
            .eq('platoon_id', selectedPlatoonId!)
            .neq('status', 'archived')
            .order('lastname', ascending: true);
        allStudents = List<Map<String, dynamic>>.from(studentsResponse);
        
      } else if (selectedCompanyId != null) {
        // Specific company, all platoons
        final companyPlatoons = availablePlatoons
            .where((p) => p['company_id'] == selectedCompanyId)
            .map((p) => p['id'])
            .toList();
            
        final studentsResponse = await _supabase
            .from('users')
            .select('id, firstname, lastname, student_id, company_id, platoon_id')
            .eq('role', 'Student')
            .eq('company_id', selectedCompanyId!)
            .inFilter('platoon_id', companyPlatoons)
            .neq('status', 'archived')
            .order('lastname', ascending: true);
        allStudents = List<Map<String, dynamic>>.from(studentsResponse);
        
      } else {
        // All companies and platoons (instructor's assignments)
        final allPlatoonIds = availablePlatoons.map((p) => p['id']).toList();
        final allCompanyIds = availableCompanies.map((c) => c['id']).toList();
        
        final studentsResponse = await _supabase
            .from('users')
            .select('id, firstname, lastname, student_id, company_id, platoon_id')
            .eq('role', 'Student')
            .inFilter('company_id', allCompanyIds)
            .inFilter('platoon_id', allPlatoonIds)
            .neq('status', 'archived')
            .order('lastname', ascending: true);
        allStudents = List<Map<String, dynamic>>.from(studentsResponse);
      }

      if (allStudents.isEmpty) {
        setState(() {
          attendanceRecords = [];
          filteredRecords = [];
          summaryStats = {'totalRecords': 0, 'present': 0, 'absent': 0, 'late': 0};
          isLoading = false;
        });
        return;
      }

      // Get attendance records for the selected date
      final studentIds = allStudents.map((s) => s['id'].toString()).toList();
      final attendanceResponse = await _supabase
          .from('attendance')
          .select('id, status, created_at, user_id')
          .inFilter('user_id', studentIds)
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String());

      // Create a map of user_id to attendance status for quick lookup
      final Map<String, Map<String, dynamic>> attendanceMap = {};
      for (final attendance in attendanceResponse) {
        final userId = attendance['user_id'].toString();
        // If multiple records exist for the same user, keep the latest one
        if (!attendanceMap.containsKey(userId) || 
            DateTime.parse(attendance['created_at']).isAfter(
              DateTime.parse(attendanceMap[userId]!['created_at'])
            )) {
          attendanceMap[userId] = attendance;
        }
      }

      // Build complete attendance records for all students
      final List<Map<String, dynamic>> completeAttendanceRecords = [];
      int presentCount = 0;
      int absentCount = 0;
      int lateCount = 0;

      for (final student in allStudents) {
        final userId = student['id'].toString();
        final attendanceRecord = attendanceMap[userId];
        
        String status = 'absent'; // Default to absent if no record found
        String? recordId;
        DateTime? recordDateTime;
        
        if (attendanceRecord != null) {
          status = attendanceRecord['status'] ?? 'absent';
          recordId = attendanceRecord['id'];
          recordDateTime = DateTime.parse(attendanceRecord['created_at']);
        }

        // Count the statuses
        switch (status.toLowerCase()) {
          case 'present':
            presentCount++;
            break;
          case 'late':
            lateCount++;
            break;
          case 'absent':
          default:
            absentCount++;
            break;
        }

        completeAttendanceRecords.add({
          'id': recordId,
          'status': status,
          'created_at': recordDateTime?.toIso8601String() ?? startDate.toIso8601String(),
          'user_id': student['id'],
          'users': {
            'firstname': student['firstname'],
            'lastname': student['lastname'],
            'student_id': student['student_id'],
            'company_id': student['company_id'],
            'platoon_id': student['platoon_id'],
          },
          'has_record': attendanceRecord != null, // Flag to identify if student actually checked in
        });
      }

      setState(() {
        attendanceRecords = completeAttendanceRecords;
        filteredRecords = List<Map<String, dynamic>>.from(completeAttendanceRecords);
        summaryStats = {
          'totalRecords': allStudents.length,
          'present': presentCount,
          'absent': absentCount,
          'late': lateCount,
        };
        isLoading = false;
      });

      _applySearchFilter();

    } catch (e) {
      print('Error loading attendance data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applySearchFilter() {
    if (searchQuery.isEmpty) {
      filteredRecords = List<Map<String, dynamic>>.from(attendanceRecords);
    } else {
      filteredRecords = attendanceRecords.where((record) {
        final user = record['users'];
        final fullName = '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.toLowerCase();
        final studentId = (user['student_id'] ?? '').toLowerCase();
        final search = searchQuery.toLowerCase();
        return fullName.contains(search) || studentId.contains(search);
      }).toList();
    }
    setState(() {});
  }

  void _onCompanyChanged(String? value) {
    if (value == null) return;
    
    setState(() {
      if (value == 'All Companies') {
        selectedCompanyId = null;
        selectedCompanyName = 'All Companies';
        selectedPlatoonId = null;
        selectedPlatoonName = 'All Platoons';
      } else {
        final company = availableCompanies.firstWhere(
          (c) => c['name'] == value,
          orElse: () => {'id': null, 'name': 'All Companies'},
        );
        selectedCompanyId = company['id'];
        selectedCompanyName = company['name'];
        selectedPlatoonId = null;
        selectedPlatoonName = 'All Platoons';
      }
    });
    _loadAttendanceData();
  }

  void _onPlatoonChanged(String? value) {
    if (value == null) return;
    
    setState(() {
      if (value == 'All Platoons') {
        selectedPlatoonId = null;
        selectedPlatoonName = 'All Platoons';
      } else {
        final platoon = getAvailablePlatoonsForCompany().firstWhere(
          (p) => p['name'] == value,
          orElse: () => {'id': null, 'name': 'All Platoons'},
        );
        selectedPlatoonId = platoon['id'];
        selectedPlatoonName = platoon['name'];
      }
    });
    _loadAttendanceData();
  }

  List<Map<String, dynamic>> getAvailablePlatoonsForCompany() {
    if (selectedCompanyId == null) {
      return availablePlatoons;
    }
    return availablePlatoons.where((p) => p['company_id'] == selectedCompanyId).toList();
  }

  List<String> getCompanyDropdownItems() {
    List<String> items = ['All Companies'];
    items.addAll(availableCompanies.map((c) => c['name'].toString()));
    return items;
  }

  List<String> getPlatoonDropdownItems() {
    List<String> items = ['All Platoons'];
    items.addAll(getAvailablePlatoonsForCompany().map((p) => p['name'].toString()));
    return items;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadAttendanceData();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(String dateTimeString, bool hasRecord) {
    if (!hasRecord) {
      return 'No check-in';
    }
    
    final dateTime = DateTime.parse(dateTimeString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Same day, show time
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : hour;
      return '${displayHour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
          'Attendance Log',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showGenerateReportDialog,
            icon: const Icon(Icons.file_download),
            tooltip: 'Generate Report',
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection Info Card
                    Container(
                      width: double.infinity,
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
                          Text(
                            selectedCompanyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedPlatoonName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Controls
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: selectedCompanyName,
                                items: getCompanyDropdownItems(),
                                onChanged: _onCompanyChanged,
                                hint: 'Select Company',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                value: selectedPlatoonName,
                                items: getPlatoonDropdownItems(),
                                onChanged: _onPlatoonChanged,
                                hint: 'Select Platoon',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Date Picker
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
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
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, 
                                    color: Color(0xFF6B7280), size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_drop_down, 
                                    color: Color(0xFF6B7280)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Total\nStudents',
                            value: '${summaryStats['totalRecords']}',
                            icon: Icons.group,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Present',
                            value: '${summaryStats['present']}',
                            icon: Icons.check_circle,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Late',
                            value: '${summaryStats['late']}',
                            icon: Icons.schedule,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Absent',
                            value: '${summaryStats['absent']}',
                            icon: Icons.cancel,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search Bar
                    Container(
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
                      child: TextField(
                        onChanged: (value) {
                          searchQuery = value;
                          _applySearchFilter();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by student name or ID...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Attendance Records
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Attendance Records',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  _formatDate(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (filteredRecords.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      searchQuery.isEmpty 
                                          ? 'No students found'
                                          : 'No matching students found',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      searchQuery.isEmpty 
                                          ? 'No students in selected company/platoon'
                                          : 'Try adjusting your search terms',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredRecords.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final record = filteredRecords[index];
                                final user = record['users'];
                                final hasRecord = record['has_record'] ?? false;
                                
                                return _buildAttendanceRecord(
                                  studentName: '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim(),
                                  studentId: user['student_id'] ?? 'N/A',
                                  platoon: _getPlatoonName(user['platoon_id']),
                                  checkInTime: _formatDateTime(record['created_at'], hasRecord),
                                  status: record['status'] ?? 'absent',
                                  hasRecord: hasRecord,
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  String _getPlatoonName(int? platoonId) {
    if (platoonId == null) return 'Unknown Platoon';
    final platoon = availablePlatoons.firstWhere(
      (p) => p['id'] == platoonId,
      orElse: () => {'name': 'Unknown Platoon'},
    );
    return platoon['name'];
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
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
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: hint,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord({
    required String studentName,
    required String studentId,
    required String platoon,
    required String checkInTime,
    required String status,
    required bool hasRecord,
  }) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.check_circle;
        break;
      case 'late':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.schedule;
        break;
      case 'absent':
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusBg = const Color(0xFFF3F4F6);
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: hasRecord ? Colors.white : Colors.grey.withOpacity(0.02),
        border: hasRecord ? null : Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName.isEmpty ? 'Unknown Student' : studentName,
                  style: TextStyle(
                    color: hasRecord ? const Color(0xFF374151) : const Color(0xFF6B7280),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$studentId • $platoon',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                checkInTime,
                style: TextStyle(
                  color: hasRecord ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontStyle: hasRecord ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate report for ${selectedCompanyName} - ${selectedPlatoonName}:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('PDF Report'),
              subtitle: const Text('Detailed attendance report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement PDF generation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF generation coming soon!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Spreadsheet'),
              subtitle: const Text('Raw data for analysis'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement Excel generation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Excel generation coming soon!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}