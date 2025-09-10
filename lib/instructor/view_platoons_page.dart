import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'attendance_log_page.dart';
class ViewPlatoonsPage extends StatefulWidget {
  const ViewPlatoonsPage({super.key});

  @override
  State<ViewPlatoonsPage> createState() => _ViewPlatoonsPageState();
}

class _ViewPlatoonsPageState extends State<ViewPlatoonsPage> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> platoons = [];
  Map<String, dynamic> stats = {
    'totalPlatoons': 0,
    'activeStudents': 0,
  };
  bool isLoading = true;
  String searchQuery = '';
String _sortBy = 'name'; // 'name', 'attendance', 'student_count'
  String _attendanceFilter = 'all'; // 'all', 'high', 'medium', 'low'
  String _studentCountFilter = 'all'; // 'all', 'large', 'medium', 'small'

  @override
  void initState() {
    super.initState();
    _loadPlatoonsData();
  }

  Future<void> _loadPlatoonsData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get current user info to filter by their assignments
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch user's assignments with company and platoon info
      final assignmentsResponse = await _supabase
          .from('instructor_assignments')
          .select('''
            company_id, platoon_id,
            companies(id, name),
            platoons(id, name)
          ''')
          .eq('instructor_id', userId);

      // Extract unique platoons from assignments
      final List<Map<String, dynamic>> uniquePlatoons = [];
      final Set<String> seenPlatoons = {};

      for (final assignment in assignmentsResponse) {
        final platoon = assignment['platoons'];
        final company = assignment['companies'];
        final platoonId = platoon['id'].toString();
        
        if (!seenPlatoons.contains(platoonId)) {
          seenPlatoons.add(platoonId);
          uniquePlatoons.add({
            'platoon_id': platoon['id'],
            'platoon_name': platoon['name'],
            'company_id': company['id'],
            'company_name': company['name'],
          });
        }
      }

      // Get student counts for each platoon
      for (final platoon in uniquePlatoons) {
        final studentsResponse = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Student')
            .eq('company_id', platoon['company_id'])
            .eq('platoon_id', platoon['platoon_id'])
            .neq('status', 'archived');

        platoon['student_count'] = studentsResponse.length;
        
        // Get today's attendance count
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final attendanceResponse = await _supabase
            .from('attendance')
            .select('user_id')
            .inFilter('user_id', studentsResponse.map((s) => s['id']).toList())
            .eq('status', 'present')
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String());

        platoon['present_count'] = attendanceResponse.length;
      }

      // Calculate total active students
final totalActiveStudents = uniquePlatoons.fold<int>(
  0,
  (sum, platoon) => sum + ((platoon['student_count'] ?? 0) as int),
);
      setState(() {
        platoons = uniquePlatoons;
        stats = {
          'totalPlatoons': uniquePlatoons.length,
          'activeStudents': totalActiveStudents,
        };
      });

    } catch (e) {
      print('Error loading platoons data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredPlatoons {
    List<Map<String, dynamic>> filtered = platoons.where((platoon) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final platoonName = platoon['platoon_name']?.toString().toLowerCase() ?? '';
        final companyName = platoon['company_name']?.toString().toLowerCase() ?? '';
        if (!platoonName.contains(searchQuery.toLowerCase()) && 
            !companyName.contains(searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Attendance rate filter
      if (_attendanceFilter != 'all') {
        final studentCount = platoon['student_count'] ?? 0;
        final presentCount = platoon['present_count'] ?? 0;
        final attendanceRate = studentCount > 0 ? (presentCount / studentCount) : 0;
        
        switch (_attendanceFilter) {
          case 'high':
            if (attendanceRate < 0.8) return false;
            break;
          case 'medium':
            if (attendanceRate < 0.5 || attendanceRate >= 0.8) return false;
            break;
          case 'low':
            if (attendanceRate >= 0.5) return false;
            break;
        }
      }
      
      // Student count filter
      if (_studentCountFilter != 'all') {
        final studentCount = platoon['student_count'] ?? 0;
        
        switch (_studentCountFilter) {
          case 'large':
            if (studentCount < 30) return false;
            break;
          case 'medium':
            if (studentCount < 15 || studentCount >= 30) return false;
            break;
          case 'small':
            if (studentCount >= 15) return false;
            break;
        }
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'attendance':
          final aRate = (a['student_count'] ?? 0) > 0 
              ? ((a['present_count'] ?? 0) / (a['student_count'] ?? 0)) 
              : 0;
          final bRate = (b['student_count'] ?? 0) > 0 
              ? ((b['present_count'] ?? 0) / (b['student_count'] ?? 0)) 
              : 0;
          return bRate.compareTo(aRate); // High to low
        case 'student_count':
          return (b['student_count'] ?? 0).compareTo(a['student_count'] ?? 0); // High to low
        case 'name':
        default:
          return (a['platoon_name'] ?? '').toString().compareTo((b['platoon_name'] ?? '').toString());
      }
    });
    
    return filtered;
  }
void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Filter & Sort Options',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort by section
                    const Text(
                      'Sort by:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Platoon Name')),
                        DropdownMenuItem(value: 'attendance', child: Text('Attendance Rate')),
                        DropdownMenuItem(value: 'student_count', child: Text('Student Count')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Attendance filter section
                    const Text(
                      'Attendance Rate:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _attendanceFilter,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'high', child: Text('High (80%+)')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium (50-79%)')),
                        DropdownMenuItem(value: 'low', child: Text('Low (<50%)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            _attendanceFilter = value;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Student count filter section
                    const Text(
                      'Student Count:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _studentCountFilter,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'large', child: Text('Large (30+)')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium (15-29)')),
                        DropdownMenuItem(value: 'small', child: Text('Small (<15)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            _studentCountFilter = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _sortBy = 'name';
                      _attendanceFilter = 'all';
                      _studentCountFilter = 'all';
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Filters are already updated in setDialogState
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _navigateToAttendanceLog(Map<String, dynamic> platoonData) {
    // Navigate to attendance log with the selected platoon data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceLogPage(
          companyId: platoonData['company_id'],
          companyName: platoonData['company_name'],
          platoonId: platoonData['platoon_id'],
          platoonName: platoonData['platoon_name'],
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          'View Platoons',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Filter Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                        decoration: const InputDecoration(
                          hintText: 'Search platoons...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                    child: IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.tune, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats Overview
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Platoons',
                      value: filteredPlatoons.length.toString(), // MODIFIED: Show filtered count
                      icon: Icons.group,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Active Students',
                      value: filteredPlatoons.fold<int>(0, (sum, platoon) => sum + ((platoon['student_count'] ?? 0) as int)).toString(), // MODIFIED: Show filtered student count
                      icon: Icons.people,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 24),

              // Platoons List
              if (filteredPlatoons.isEmpty)
                const Center(
                  child: Text(
                    'No platoons found',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPlatoons.length,
                  itemBuilder: (context, index) {
                    final platoon = filteredPlatoons[index];
                    final studentCount = platoon['student_count'] ?? 0;
                    final presentCount = platoon['present_count'] ?? 0;
                    final attendanceRate = studentCount > 0 
                        ? (presentCount / studentCount * 100).round() 
                        : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPlatoonCard(
                        platoonName: platoon['platoon_name'] ?? 'Unknown Platoon',
                        companyName: platoon['company_name'] ?? 'Unknown Company',
                        studentCount: studentCount,
                        presentCount: presentCount,
                        attendanceRate: '$attendanceRate%',
                        onTap: () => _navigateToAttendanceLog(platoon),
                      ),
                    );
                  },
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
              Icon(icon, color: color, size: 20),
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

  Widget _buildPlatoonCard({
    required String platoonName,
    required String companyName,
    required int studentCount,
    required int presentCount,
    required String attendanceRate,
    required VoidCallback onTap,
  }) {
    final int absentCount = studentCount - presentCount;
    final double attendancePercentage = studentCount > 0 ? (presentCount / studentCount) : 0;
    
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          platoonName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: attendancePercentage >= 0.9 
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        attendanceRate,
                        style: TextStyle(
                          color: attendancePercentage >= 0.9 
                              ? const Color(0xFF059669)
                              : const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniStat('Total', studentCount.toString(), Icons.people, const Color(0xFF6B7280)),
                    const SizedBox(width: 20),
                    _buildMiniStat('Present', presentCount.toString(), Icons.check_circle, const Color(0xFF059669)),
                    const SizedBox(width: 20),
                    _buildMiniStat('Absent', absentCount.toString(), Icons.cancel, const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
