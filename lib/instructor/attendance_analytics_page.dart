import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  final int? companyId;
  final String? companyName;
  final int? platoonId;
  final String? platoonName;

  const AttendanceAnalyticsPage({
    super.key,
    this.companyId,
    this.companyName,
    this.platoonId,
    this.platoonName,
  });

  @override
  State<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  final _supabase = Supabase.instance.client;
  
  bool isLoading = true;
  String selectedTimeframe = 'week'; // week, month, semester
  
  // Analytics data
  Map<String, dynamic> overallStats = {};
  List<Map<String, dynamic>> weeklyTrends = [];
  List<Map<String, dynamic>> studentPerformance = [];
  Map<String, dynamic> timeAnalysis = {};
  List<Map<String, dynamic>> comparisonData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      _loadOverallStats(),
      _loadWeeklyTrends(),
      _loadStudentPerformance(),
      _loadTimeAnalysis(),
      _loadComparisonData(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadOverallStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get date range based on timeframe
      final endDate = DateTime.now();
      DateTime startDate;
      
      switch (selectedTimeframe) {
        case 'week':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case 'semester':
          startDate = endDate.subtract(const Duration(days: 90));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      // Get students in the selected company/platoon
      List<String> studentIds = await _getStudentIds();

      if (studentIds.isEmpty) {
        setState(() {
          overallStats = {
            'totalClasses': 0,
            'averageAttendance': 0.0,
            'totalStudents': 0,
            'perfectAttendance': 0,
          };
        });
        return;
      }

      // Get attendance records for the period
      final attendanceResponse = await _supabase
          .from('attendance')
          .select('status, created_at, user_id')
          .inFilter('user_id', studentIds)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Calculate stats
      final totalRecords = attendanceResponse.length;
      final presentRecords = attendanceResponse.where((r) => r['status'] == 'present').length;
      final lateRecords = attendanceResponse.where((r) => r['status'] == 'late').length;
      
      // Get unique dates (class days)
      final uniqueDates = attendanceResponse
          .map((r) => DateTime.parse(r['created_at']).toString().substring(0, 10))
          .toSet()
          .length;

      // Calculate perfect attendance students
      final studentAttendance = <String, int>{};
      final studentDays = <String, Set<String>>{};
      
      for (final record in attendanceResponse) {
        final userId = record['user_id'];
        final date = DateTime.parse(record['created_at']).toString().substring(0, 10);
        
        studentDays[userId] ??= <String>{};
        studentDays[userId]!.add(date);
        
        if (record['status'] == 'present' || record['status'] == 'late') {
          studentAttendance[userId] = (studentAttendance[userId] ?? 0) + 1;
        }
      }

      final perfectAttendanceCount = studentAttendance.values
          .where((days) => days >= uniqueDates)
          .length;

      setState(() {
        overallStats = {
          'totalClasses': uniqueDates,
          'averageAttendance': totalRecords > 0 ? ((presentRecords + lateRecords) / totalRecords * 100) : 0.0,
          'totalStudents': studentIds.length,
          'perfectAttendance': perfectAttendanceCount,
          'presentCount': presentRecords,
          'lateCount': lateRecords,
          'absentCount': totalRecords - presentRecords - lateRecords,
        };
      });

    } catch (e) {
      print('Error loading overall stats: $e');
    }
  }

  Future<void> _loadWeeklyTrends() async {
    try {
      List<String> studentIds = await _getStudentIds();
      if (studentIds.isEmpty) return;

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 28)); // Last 4 weeks

      final attendanceResponse = await _supabase
          .from('attendance')
          .select('status, created_at')
          .inFilter('user_id', studentIds)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Group by week
      final weeklyData = <String, Map<String, int>>{};
      
      for (final record in attendanceResponse) {
        final date = DateTime.parse(record['created_at']);
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final weekKey = '${weekStart.day}/${weekStart.month}';
        
        weeklyData[weekKey] ??= {'present': 0, 'late': 0, 'absent': 0};
        
        final status = record['status'];
        if (status == 'present') {
          weeklyData[weekKey]!['present'] = weeklyData[weekKey]!['present']! + 1;
        } else if (status == 'late') {
          weeklyData[weekKey]!['late'] = weeklyData[weekKey]!['late']! + 1;
        } else {
          weeklyData[weekKey]!['absent'] = weeklyData[weekKey]!['absent']! + 1;
        }
      }

      final trends = weeklyData.entries.map((entry) {
        final total = entry.value['present']! + entry.value['late']! + entry.value['absent']!;
        return {
          'week': entry.key,
          'attendance_rate': total > 0 ? ((entry.value['present']! + entry.value['late']!) / total * 100) : 0.0,
          'present': entry.value['present']!,
          'late': entry.value['late']!,
          'absent': entry.value['absent']!,
        };
      }).toList();

      setState(() {
        weeklyTrends = trends;
      });

    } catch (e) {
      print('Error loading weekly trends: $e');
    }
  }

  Future<void> _loadStudentPerformance() async {
    try {
      List<String> studentIds = await _getStudentIds();
      if (studentIds.isEmpty) return;

      // Get student details
      final studentsResponse = await _supabase
          .from('users')
          .select('id, firstname, lastname, student_id')
          .inFilter('id', studentIds);

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30)); // Last month

      final attendanceResponse = await _supabase
          .from('attendance')
          .select('status, user_id, created_at')
          .inFilter('user_id', studentIds)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Calculate performance for each student
      final studentStats = <String, Map<String, dynamic>>{};
      
      for (final student in studentsResponse) {
        final studentId = student['id'];
        final records = attendanceResponse.where((r) => r['user_id'] == studentId).toList();
        
        final present = records.where((r) => r['status'] == 'present').length;
        final late = records.where((r) => r['status'] == 'late').length;
        final total = records.length;
        
        studentStats[studentId] = {
          'name': '${student['firstname']} ${student['lastname']}',
          'student_id': student['student_id'],
          'attendance_rate': total > 0 ? ((present + late) / total * 100) : 0.0,
          'present': present,
          'late': late,
          'absent': total - present - late,
          'total': total,
        };
      }

      // Sort by attendance rate
      final sortedPerformance = studentStats.entries
          .map((e) => {
                'user_id': e.key,
                ...e.value,
              })
          .toList()
        ..sort((a, b) => (b['attendance_rate'] as double).compareTo(a['attendance_rate'] as double));

      setState(() {
        studentPerformance = sortedPerformance.take(10).toList(); // Top 10
      });

    } catch (e) {
      print('Error loading student performance: $e');
    }
  }

  Future<void> _loadTimeAnalysis() async {
    try {
      List<String> studentIds = await _getStudentIds();
      if (studentIds.isEmpty) return;

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final attendanceResponse = await _supabase
          .from('attendance')
          .select('status, created_at')
          .inFilter('user_id', studentIds)
          .eq('status', 'present')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Analyze check-in times
      final hourlyData = <int, int>{};
      final dailyData = <int, int>{}; // 1=Monday, 7=Sunday

      for (final record in attendanceResponse) {
        final dateTime = DateTime.parse(record['created_at']);
        final hour = dateTime.hour;
        final weekday = dateTime.weekday;

        hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;
        dailyData[weekday] = (dailyData[weekday] ?? 0) + 1;
      }

      setState(() {
        timeAnalysis = {
          'hourly': hourlyData,
          'daily': dailyData,
          'peak_hour': hourlyData.entries.isEmpty 
              ? 8 
              : hourlyData.entries.reduce((a, b) => a.value > b.value ? a : b).key,
          'peak_day': dailyData.entries.isEmpty 
              ? 1 
              : dailyData.entries.reduce((a, b) => a.value > b.value ? a : b).key,
        };
      });

    } catch (e) {
      print('Error loading time analysis: $e');
    }
  }

  Future<void> _loadComparisonData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get all instructor's assignments for comparison
      final assignmentsResponse = await _supabase
          .from('instructor_assignments')
          .select('''
            company_id, platoon_id,
            companies(name),
            platoons(name)
          ''')
          .eq('instructor_id', userId);

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      List<Map<String, dynamic>> comparisonList = [];

      for (final assignment in assignmentsResponse) {
        // Get students for this assignment
        final studentsResponse = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Student')
            .eq('company_id', assignment['company_id'])
            .eq('platoon_id', assignment['platoon_id'])
            .neq('status', 'archived');

        final studentIds = studentsResponse.map((s) => s['id']).toList();

        if (studentIds.isNotEmpty) {
          // Get attendance for this group
          final attendanceResponse = await _supabase
              .from('attendance')
              .select('status')
              .inFilter('user_id', studentIds)
              .gte('created_at', startDate.toIso8601String())
              .lte('created_at', endDate.toIso8601String());

          final total = attendanceResponse.length;
          final present = attendanceResponse.where((r) => r['status'] == 'present').length;
          final late = attendanceResponse.where((r) => r['status'] == 'late').length;

          comparisonList.add({
            'name': '${assignment['companies']['name']} - ${assignment['platoons']['name']}',
            'attendance_rate': total > 0 ? ((present + late) / total * 100) : 0.0,
            'total_students': studentIds.length,
          });
        }
      }

      comparisonList.sort((a, b) => (b['attendance_rate'] as double).compareTo(a['attendance_rate'] as double));

      setState(() {
        comparisonData = comparisonList;
      });

    } catch (e) {
      print('Error loading comparison data: $e');
    }
  }

  Future<List<String>> _getStudentIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      if (widget.companyId != null && widget.platoonId != null) {
        // Specific company and platoon
        final studentsResponse = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Student')
            .eq('company_id', widget.companyId!)
            .eq('platoon_id', widget.platoonId!)
            .neq('status', 'archived');
        
        return studentsResponse.map((s) => s['id'].toString()).toList();
      } else {
        // Get all students from instructor's assignments
        final assignmentsResponse = await _supabase
            .from('instructor_assignments')
            .select('company_id, platoon_id')
            .eq('instructor_id', userId);

        List<String> allStudentIds = [];
        for (final assignment in assignmentsResponse) {
          final studentsResponse = await _supabase
              .from('users')
              .select('id')
              .eq('role', 'Student')
              .eq('company_id', assignment['company_id'])
              .eq('platoon_id', assignment['platoon_id'])
              .neq('status', 'archived');
          
          allStudentIds.addAll(studentsResponse.map((s) => s['id'].toString()));
        }
        
        return allStudentIds.toSet().toList(); // Remove duplicates
      }
    } catch (e) {
      print('Error getting student IDs: $e');
      return [];
    }
  }

  Future<void> _exportData() async {
    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to export data'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Analytics Report'],
        ['Generated on: ${DateTime.now().toString().substring(0, 16)}'],
        ['Company: ${widget.companyName ?? 'All Companies'}'],
        ['Platoon: ${widget.platoonName ?? 'All Platoons'}'],
        ['Timeframe: ${selectedTimeframe.toUpperCase()}'],
        [],
        ['OVERALL STATISTICS'],
        ['Total Classes', overallStats['totalClasses'] ?? 0],
        ['Average Attendance', '${(overallStats['averageAttendance'] ?? 0.0).toStringAsFixed(1)}%'],
        ['Total Students', overallStats['totalStudents'] ?? 0],
        ['Perfect Attendance Students', overallStats['perfectAttendance'] ?? 0],
        ['Present Records', overallStats['presentCount'] ?? 0],
        ['Late Records', overallStats['lateCount'] ?? 0],
        ['Absent Records', overallStats['absentCount'] ?? 0],
        [],
        ['WEEKLY TRENDS'],
        ['Week', 'Attendance Rate', 'Present', 'Late', 'Absent'],
      ];

      for (final week in weeklyTrends) {
        csvData.add([
          week['week'],
          '${week['attendance_rate'].toStringAsFixed(1)}%',
          week['present'],
          week['late'],
          week['absent'],
        ]);
      }

      csvData.addAll([
        [],
        ['TOP STUDENT PERFORMANCE'],
        ['Name', 'Student ID', 'Attendance Rate', 'Present', 'Late', 'Absent'],
      ]);

      for (final student in studentPerformance) {
        csvData.add([
          student['name'],
          student['student_id'],
          '${student['attendance_rate'].toStringAsFixed(1)}%',
          student['present'],
          student['late'],
          student['absent'],
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get directory and save file
      final directory = await getExternalStorageDirectory();
      final fileName = 'attendance_analytics_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory?.path}/$fileName');
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Attendance Analytics Report',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported successfully: $fileName'),
          backgroundColor: const Color(0xFF059669),
        ),
      );

    } catch (e) {
      print('Error exporting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export data'),
          backgroundColor: Colors.red,
        ),
      );
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text(
          'Attendance Analytics',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          // IconButton(
          //   onPressed: _exportData,
          //   icon: const Icon(Icons.download),
          //   tooltip: 'Export Data',
          // ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeframe: ${widget.companyName ?? 'All Companies'} - ${widget.platoonName ?? 'All Platoons'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTimeframeChip('Week', 'week'),
                        const SizedBox(width: 8),
                        _buildTimeframeChip('Month', 'month'),
                        const SizedBox(width: 8),
                        _buildTimeframeChip('Semester', 'semester'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overall Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Classes',
                      '${overallStats['totalClasses'] ?? 0}',
                      Icons.calendar_today,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Avg Attendance',
                      '${(overallStats['averageAttendance'] ?? 0.0).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      const Color(0xFF059669),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      '${overallStats['totalStudents'] ?? 0}',
                      Icons.people,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Perfect Attendance',
                      '${overallStats['perfectAttendance'] ?? 0}',
                      Icons.star,
                      const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Attendance Distribution Pie Chart
              Container(
                width: double.infinity,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem('Present', const Color(0xFF059669), overallStats['presentCount'] ?? 0),
                                const SizedBox(height: 8),
                                _buildLegendItem('Late', const Color(0xFFF59E0B), overallStats['lateCount'] ?? 0),
                                const SizedBox(height: 8),
                                _buildLegendItem('Absent', const Color(0xFFEF4444), overallStats['absentCount'] ?? 0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Trends Line Chart
              if (weeklyTrends.isNotEmpty) ...[
                Container(
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Attendance Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}%', style: const TextStyle(fontSize: 12));
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < weeklyTrends.length) {
                                      return Text(
                                        weeklyTrends[value.toInt()]['week'],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: weeklyTrends.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value['attendance_rate'].toDouble());
                                }).toList(),
                                isCurved: true,
                                color: const Color(0xFF059669),
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                            minY: 0,
                            maxY: 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Top Student Performance
              if (studentPerformance.isNotEmpty) ...[
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Top Student Performance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: studentPerformance.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final student = studentPerformance[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: index < 3 
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF6B7280),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      Text(
                                        student['student_id'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${student['attendance_rate'].toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                    Text(
                                      '${student['present']}P ${student['late']}L ${student['absent']}A',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],

              // Comparison with other platoons
              if (comparisonData.isNotEmpty) ...[
                Container(
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platoon Comparison',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value.toInt() < comparisonData.length) {
                                      final name = comparisonData[value.toInt()]['name'];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          name.length > 10 ? '${name.substring(0, 10)}...' : name,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    return Text(
                                      '${value.toInt()}%',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: comparisonData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data['attendance_rate'].toDouble(),
                                    color: const Color(0xFF059669),
                                    width: 20,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
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
      ),
    );
  }

  Widget _buildTimeframeChip(String label, String value) {
    final isSelected = selectedTimeframe == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeframe = value;
        });
        _loadAnalyticsData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  List<PieChartSectionData> _buildPieChartSections() {
    final total = (overallStats['presentCount'] ?? 0) + 
                  (overallStats['lateCount'] ?? 0) + 
                  (overallStats['absentCount'] ?? 0);
    
    if (total == 0) {
      return [
        PieChartSectionData(
          color: const Color(0xFFE5E7EB),
          value: 100,
          title: 'No Data',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        )
      ];
    }

    return [
      PieChartSectionData(
        color: const Color(0xFF059669),
        value: ((overallStats['presentCount'] ?? 0) / total * 100).toDouble(),
        title: '${((overallStats['presentCount'] ?? 0) / total * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFFF59E0B),
        value: ((overallStats['lateCount'] ?? 0) / total * 100).toDouble(),
        title: '${((overallStats['lateCount'] ?? 0) / total * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: const Color(0xFFEF4444),
        value: ((overallStats['absentCount'] ?? 0) / total * 100).toDouble(),
        title: '${((overallStats['absentCount'] ?? 0) / total * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($value)',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}