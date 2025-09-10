import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/camouflage_background.dart';
// Import the new pages
import 'view_platoons_page.dart';
import 'attendance_log_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_analytics_page.dart';

class InstructorPage extends StatefulWidget {
  const InstructorPage({super.key});

  @override
  State<InstructorPage> createState() => _InstructorPageState();
}

class _InstructorPageState extends State<InstructorPage> {
  final _supabase = Supabase.instance.client;
  
  // User data
  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> userAssignments = [];
  
  // Selected assignment data
  Map<String, dynamic>? selectedAssignment;
  Map<String, dynamic> attendanceStats = {
    'totalStudents': 0,
    'presentToday': 0,
    'absentToday': 0,
    'attendanceRate': 0.0,
  };
  
  // Recent activity data
  List<Map<String, dynamic>> recentActivity = [];
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get current user info
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch user details
      final userResponse = await _supabase
          .from('users')
          .select('firstname, lastname, student_id, rank_id, ranks(name)')
          .eq('id', userId)
          .single();

      // Fetch user's assignments with company and platoon info
      final assignmentsResponse = await _supabase
          .from('instructor_assignments')
          .select('''
            id, company_id, platoon_id,
            companies(id, name),
            platoons(id, name)
          ''')
          .eq('instructor_id', userId);

      setState(() {
        currentUser = userResponse;
        userAssignments = List<Map<String, dynamic>>.from(assignmentsResponse);
      });

      // Load the previously selected assignment or set first as default
      await _loadSelectedAssignment();

      // Load attendance data for selected assignment
      if (selectedAssignment != null) {
        await _loadAttendanceData();
      }

    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
Future<void> _loadSelectedAssignment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _supabase.auth.currentUser?.id;
      final savedAssignmentId = prefs.getString('selected_assignment_id_$userId');
      
      if (savedAssignmentId != null && userAssignments.isNotEmpty) {
        // Try to find the saved assignment in current assignments
        final savedAssignment = userAssignments.where(
          (assignment) => assignment['id'] == savedAssignmentId
        ).firstOrNull;
        
        if (savedAssignment != null) {
          setState(() {
            selectedAssignment = savedAssignment;
          });
          return;
        }
      }
      
      // If no saved assignment found or it's not valid, use first assignment
      if (userAssignments.isNotEmpty) {
        setState(() {
          selectedAssignment = userAssignments.first;
        });
        // Save this as the selected assignment
        await _saveSelectedAssignment(userAssignments.first['id']);
      }
    } catch (e) {
      print('Error loading selected assignment: $e');
      // Fallback to first assignment
      if (userAssignments.isNotEmpty) {
        setState(() {
          selectedAssignment = userAssignments.first;
        });
      }
    }
  }

  // New method to save selected assignment
  Future<void> _saveSelectedAssignment(String assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _supabase.auth.currentUser?.id;
      await prefs.setString('selected_assignment_id_$userId', assignmentId);
    } catch (e) {
      print('Error saving selected assignment: $e');
    }
  }


  Future<void> _loadAttendanceData() async {
    if (selectedAssignment == null) return;

    try {
      final companyId = selectedAssignment!['company_id'];
      final platoonId = selectedAssignment!['platoon_id'];

      // Get total students in this company-platoon
      final studentsResponse = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'Student')
          .eq('company_id', companyId)
          .eq('platoon_id', platoonId)
          .neq('status', 'archived');

      final totalStudents = studentsResponse.length;

      // Get today's attendance for these students
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // First, get all student IDs for this company-platoon
      final studentIds = studentsResponse.map((student) => student['id']).toList();

      // Then get today's attendance for these specific students
      final attendanceResponse = await _supabase
          .from('attendance')
          .select('user_id, status')
          .inFilter('user_id', studentIds)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      final presentToday = attendanceResponse.where((record) => 
          record['status'] == 'present').length;
      final absentToday = totalStudents - presentToday;
      final attendanceRate = totalStudents > 0 
          ? (presentToday / totalStudents * 100) 
          : 0.0;

      // Get recent activity for this company-platoon
      final recentActivityResponse = await _supabase
          .from('attendance')
          .select('''
            status, created_at, user_id,
            users!attendance_user_id_fkey(firstname, lastname, student_id)
          ''')
          .inFilter('user_id', studentIds)
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        attendanceStats = {
          'totalStudents': totalStudents,
          'presentToday': presentToday,
          'absentToday': absentToday,
          'attendanceRate': attendanceRate,
        };
        recentActivity = List<Map<String, dynamic>>.from(recentActivityResponse);
      });

    } catch (e) {
      print('Error loading attendance data: $e');
    }
  }

  void _onAssignmentSelected(Map<String, dynamic> assignment) {
    setState(() {
      selectedAssignment = assignment;
    });
    
    // Save the selected assignment
    _saveSelectedAssignment(assignment['id']);
    
    // Load attendance data for the new assignment
    _loadAttendanceData();
  }


  String _getTimeAgo(String createdAt) {
    final created = DateTime.parse(createdAt);
    final now = DateTime.now();
    final difference = now.difference(created);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF059669),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Camouflage Background
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
                            'Welcome,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            currentUser?['firstname'] ?? 'Instructor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${currentUser?['student_id'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            currentUser?['ranks']?['name'] ?? 'Military Academy',
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

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Assignment Selection Card
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select Assignment",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (userAssignments.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Color(0xFFF59E0B),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'No assignments found. Contact administrator.',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: selectedAssignment,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: userAssignments.map((assignment) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: assignment,
                                    child: Text(
                                      '${assignment['companies']['name']} - ${assignment['platoons']['name']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _onAssignmentSelected(value);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (selectedAssignment != null) ...[
                      const SizedBox(height: 24),

                      // Today's Overview Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Today's Overview",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${selectedAssignment!['companies']['name']} - ${selectedAssignment!['platoons']['name']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Total Students',
                                      value: '${attendanceStats['totalStudents']}',
                                      icon: Icons.people,
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Present Today',
                                      value: '${attendanceStats['presentToday']}',
                                      icon: Icons.check_circle,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Absent',
                                      value: '${attendanceStats['absentToday']}',
                                      icon: Icons.cancel,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      title: 'Attendance Rate',
                                      value: '${attendanceStats['attendanceRate'].toStringAsFixed(0)}%',
                                      icon: Icons.trending_up,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions Section
                      const Text(
  'Quick Actions',
  style: TextStyle(
    color: Color(0xFF374151),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 16),

// Action Buttons - Grid Layout for 3 buttons
Column(
  children: [
    // First row - 2 buttons
    Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'View Platoons',
            subtitle: 'Manage student groups',
            icon: Icons.group,
            color: const Color(0xFF059669),
            isExpanded: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Attendance Log',
            subtitle: 'View & export records',
            icon: Icons.assignment,
            color: const Color(0xFF3B82F6),
            isExpanded: true,
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
    // Second row - 1 centered button
    Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Analytics',
            subtitle: 'View attendance insights',
            icon: Icons.analytics,
            color: const Color(0xFF8B5CF6),
            isExpanded: true,
          ),
        ),
      ],
    ),
  ],
),


                      const SizedBox(height: 16),

                      // Recent Activity Items
                      if (recentActivity.isNotEmpty)
                        ...recentActivity.take(3).map((activity) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildActivityItem(
                            studentName: '${activity['users']['firstname']} ${activity['users']['lastname']}',
                            studentId: activity['users']['student_id'] ?? 'N/A',
                            action: activity['status'] == 'present' ? 'Present' : 'Absent',
                            time: _getTimeAgo(activity['created_at']),
                            status: activity['status'],
                          ),
                        ))
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
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
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.grey[400],
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No recent activity',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Attendance records will appear here',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isExpanded = false,
  }) {
    return Container(
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
          onTap: () {
            if (title == 'View Platoons') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewPlatoonsPage(),
                ),
              );
            } else if (title == 'Attendance Log') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceLogPage(
                    companyId: selectedAssignment!['company_id'],
                    companyName: selectedAssignment!['companies']['name'],
                    platoonId: selectedAssignment!['platoon_id'],
                    platoonName: selectedAssignment!['platoons']['name'],
                  ),
                ),
              );
            }
            else if (title == 'Analytics') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AttendanceAnalyticsPage(
        companyId: selectedAssignment!['company_id'],
        companyName: selectedAssignment!['companies']['name'],
        platoonId: selectedAssignment!['platoon_id'],
        platoonName: selectedAssignment!['platoons']['name'],
      ),
    ),
  );
}

          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
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
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String studentName,
    required String studentId,
    required String action,
    required String time,
    required String status,
  }) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'present':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.check_circle;
        break;
      default: // absent
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.cancel;
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
                    studentName,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$studentId • $action',
                    style: const TextStyle(
                      color: Color(0xFF6b7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFF6b7280),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}