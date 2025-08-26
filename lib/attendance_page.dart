import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Present',
                      '18',
                      '85%',
                      const Color(0xFF059669),
                      const Color(0xFFDCFCE7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Absent',
                      '3',
                      '15%',
                      const Color(0xFFEF4444),
                      const Color(0xFFFEE2E2),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              const Text(
                'All Records',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Attendance List
              Expanded(
                child: ListView(
                  children: [
                    _buildAttendanceItem(
                      date: 'Aug 20, 2025',
                      time: '08:34 AM',
                      status: 'Present',
                      isPresent: true,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 19, 2025',
                      time: '08:45 AM',
                      status: 'Present',
                      isPresent: true,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 18, 2025',
                      time: 'No record',
                      status: 'Absent',
                      isPresent: false,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 17, 2025',
                      time: '08:30 AM',
                      status: 'Present',
                      isPresent: true,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 16, 2025',
                      time: '08:55 AM',
                      status: 'Present',
                      isPresent: true,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 15, 2025',
                      time: 'No record',
                      status: 'Absent',
                      isPresent: false,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 14, 2025',
                      time: '08:42 AM',
                      status: 'Present',
                      isPresent: true,
                    ),
                    _buildAttendanceItem(
                      date: 'Aug 13, 2025',
                      time: '08:38 AM',
                      status: 'Present',
                      isPresent: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, String percentage, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percentage,
            style: const TextStyle(
              color: Color(0xFF6b7280),
              fontSize: 14,
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
    required bool isPresent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                color: isPresent ? const Color(0xFF059669) : const Color(0xFFEF4444),
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