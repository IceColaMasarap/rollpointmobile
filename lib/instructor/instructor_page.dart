import 'package:flutter/material.dart';
import '../widgets/camouflage_background.dart';

class InstructorPage extends StatelessWidget {
  const InstructorPage({super.key});

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
                        children: const [
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Instructor Panel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Staff ID: INS-2024-001',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Military Academy - Command',
                            style: TextStyle(
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

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            const Text(
                              "Today's Overview",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    title: 'Total Students',
                                    value: '156',
                                    icon: Icons.people,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    title: 'Present Today',
                                    value: '142',
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
                                    value: '14',
                                    icon: Icons.cancel,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    title: 'Attendance Rate',
                                    value: '91%',
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
                    
                    // Action Buttons Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'View Platoons',
                            subtitle: 'Manage student groups',
                            icon: Icons.group,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Attendance Log',
                            subtitle: 'View detailed records',
                            icon: Icons.assignment,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Single action card centered
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'Generate Report',
                            subtitle: 'Export attendance data',
                            icon: Icons.analytics,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(), // Empty space for symmetry
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Recent Activity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle view all
                          },
                          child: const Text(
                            'View All',
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

                    // Recent Activity Items
                    _buildActivityItem(
                      studentName: 'Sean Derick',
                      studentId: '2023-77144-ABCD',
                      action: 'Checked in',
                      time: '2 minutes ago',
                      status: 'present',
                    ),

                    const SizedBox(height: 12),

                    _buildActivityItem(
                      studentName: 'Maria Santos',
                      studentId: '2023-77145-EFGH',
                      action: 'Checked in',
                      time: '5 minutes ago',
                      status: 'present',
                    ),

                    const SizedBox(height: 12),

                    _buildActivityItem(
                      studentName: 'John Cruz',
                      studentId: '2023-77146-IJKL',
                      action: 'Late arrival',
                      time: '15 minutes ago',
                      status: 'late',
                    ),

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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle action tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
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
      case 'late':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.schedule;
        break;
      default:
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