import 'package:flutter/material.dart';
import 'widgets/camouflage_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: CamouflageBackground(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors
                          .transparent, // keep transparent so background shows
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Greetings,',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Sean Derick',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '2023-77144-ABCD',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Student - Platoon',
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

              // QR Code Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                          children: [
                            // QR Code placeholder
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF059669),
                                  width: 4,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  // QR Code pattern (simplified representation)
                                  Container(
                                    color: const Color.fromARGB(
                                      255,
                                      210,
                                      210,
                                      210,
                                    ),
                                  ),
                                  // Center logo
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Generate New Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle generate new QR code
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Generate new',
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
                    ),

                    const SizedBox(height: 30),

                    // Today's Status Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Status",
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Present - 08:34 AM',
                                    style: TextStyle(
                                      color: Color(0xFF374151),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'On time',
                                    style: TextStyle(
                                      color: Color(0xFF6b7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Recent Attendance Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Attendance',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Handle see all
                          },
                          child: const Text(
                            'See All',
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

                    // Recent Attendance Items
                    _buildAttendanceItem(
                      date: 'Aug 20, 2025',
                      time: '08:34 AM',
                      status: 'Present',
                      isPresent: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceItem(
                      date: 'Aug 19, 2025',
                      time: '08:45 AM',
                      status: 'Present',
                      isPresent: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceItem(
                      date: 'Aug 18, 2025',
                      time: 'No record',
                      status: 'Absent',
                      isPresent: false,
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

  Widget _buildAttendanceItem({
    required String date,
    required String time,
    required String status,
    required bool isPresent,
  }) {
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isPresent
                    ? const Color(0xFF059669)
                    : const Color(0xFFEF4444),
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

class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Create a simplified QR code pattern
    final cellSize = size.width / 21; // 21x21 grid for QR code

    // Draw positioning squares (corners)
    _drawPositioningSquare(canvas, paint, 0, 0, cellSize);
    _drawPositioningSquare(canvas, paint, 14 * cellSize, 0, cellSize);
    _drawPositioningSquare(canvas, paint, 0, 14 * cellSize, cellSize);

    // Draw some random pattern cells to simulate QR code data
    final random = [
      [2, 2],
      [2, 4],
      [2, 6],
      [3, 2],
      [3, 5],
      [3, 7],
      [4, 3],
      [4, 6],
      [5, 2],
      [5, 4],
      [5, 7],
      [6, 3],
      [6, 5],
      [7, 2],
      [7, 6],
      [8, 4],
      [8, 7],
      [9, 2],
      [9, 5],
      [10, 3],
      [10, 6],
      [11, 2],
      [11, 4],
      [11, 7],
      [12, 3],
      [12, 5],
      [13, 2],
      [13, 6],
      [15, 2],
      [15, 4],
      [15, 6],
      [16, 3],
      [16, 5],
      [17, 2],
      [17, 4],
      [17, 7],
      [18, 3],
      [18, 6],
      [2, 9],
      [3, 10],
      [4, 11],
      [5, 9],
      [6, 10],
      [7, 11],
      [8, 9],
      [9, 10],
      [10, 11],
      [11, 9],
    ];

    for (final cell in random) {
      final x = cell[0] * cellSize;
      final y = cell[1] * cellSize;
      canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paint);
    }
  }

  void _drawPositioningSquare(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double cellSize,
  ) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, cellSize * 7, cellSize * 7), paint);

    // Inner white square
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 5, cellSize * 5),
      paint,
    );

    // Center black square
    paint.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(
        x + cellSize * 2,
        y + cellSize * 2,
        cellSize * 3,
        cellSize * 3,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
