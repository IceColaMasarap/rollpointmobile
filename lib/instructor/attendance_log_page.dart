import 'package:flutter/material.dart';

class AttendanceLogPage extends StatefulWidget {
  const AttendanceLogPage({super.key});

  @override
  State<AttendanceLogPage> createState() => _AttendanceLogPageState();
}

class _AttendanceLogPageState extends State<AttendanceLogPage> {
  String selectedFilter = 'Today';
  String selectedPlatoon = 'All Platoons';

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
            onPressed: () {
              _showGenerateReportDialog();
            },
            icon: const Icon(Icons.file_download),
            tooltip: 'Generate Report',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Controls
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: selectedFilter,
                      items: ['Today', 'Yesterday', 'This Week', 'This Month'],
                      onChanged: (value) {
                        setState(() {
                          selectedFilter = value!;
                        });
                      },
                      hint: 'Filter by Date',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      value: selectedPlatoon,
                      items: ['All Platoons', 'Alpha Platoon 1', 'Alpha Platoon 2', 'Bravo Platoon 1', 'Bravo Platoon 2'],
                      onChanged: (value) {
                        setState(() {
                          selectedPlatoon = value!;
                        });
                      },
                      hint: 'Select Platoon',
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
                      title: 'Total Records',
                      value: '142',
                      icon: Icons.assignment,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Present',
                      value: '128',
                      icon: Icons.check_circle,
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Absent',
                      value: '14',
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
                child: const TextField(
                  decoration: InputDecoration(
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
                            selectedFilter,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 10,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _buildAttendanceRecord(
                          studentName: _getStudentName(index),
                          studentId: _getStudentId(index),
                          platoon: _getPlatoon(index),
                          checkInTime: _getCheckInTime(index),
                          status: _getStatus(index),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  Widget _buildAttendanceRecord({
    required String studentName,
    required String studentId,
    required String platoon,
    required String checkInTime,
    required String status,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  status,
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
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
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
            const Text('Select report format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('PDF Report'),
              subtitle: const Text('Detailed attendance report'),
              onTap: () {
                Navigator.pop(context);
                // Handle PDF generation
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Spreadsheet'),
              subtitle: const Text('Raw data for analysis'),
              onTap: () {
                Navigator.pop(context);
                // Handle Excel generation
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

  String _getStudentName(int index) {
    final names = [
      'Sean Derick', 'Maria Santos', 'John Cruz', 'Ana Garcia',
      'Pedro Reyes', 'Sofia Torres', 'Luis Ramos', 'Rosa Mendoza',
      'Carlos Villanueva', 'Elena Rodriguez'
    ];
    return names[index];
  }

  String _getStudentId(int index) {
    return '2023-${77144 + index}-ABCD';
  }

  String _getPlatoon(int index) {
    final platoons = [
      'Alpha Platoon 1', 'Alpha Platoon 2', 'Bravo Platoon 1',
      'Bravo Platoon 2', 'Charlie Platoon 1'
    ];
    return platoons[index % platoons.length];
  }

  String _getCheckInTime(int index) {
    final times = [
      '08:00 AM', '08:05 AM', '08:15 AM', '08:20 AM',
      '08:30 AM', '08:35 AM', '08:45 AM', '09:00 AM',
      '09:15 AM', '09:30 AM'
    ];
    return times[index];
  }

  String _getStatus(int index) {
    final statuses = [
      'Present', 'Present', 'Absent', 'Present',
      'Present', 'Absent', 'Present', 'Absent',
      'Present', 'Present'
    ];
    return statuses[index];
  }
}