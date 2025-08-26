import 'package:flutter/material.dart';

class CamouflageBackground extends StatelessWidget {
  final Widget child;
  const CamouflageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(painter: CamouflagePainter(), child: Container()),
          child,
        ],
      ),
    );
  }
}

class CamouflagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final random = [0.2, 0.7, 0.3, 0.8, 0.15, 0.65, 0.45, 0.9, 0.1, 0.6];
    for (int i = 0; i < 8; i++) {
      paint.color = Colors.white.withOpacity(0.03 + (i % 3) * 0.02);
      final path = Path();
      final startX = size.width * random[i % random.length];
      final startY = size.height * random[(i + 1) % random.length];
      path.moveTo(startX, startY);
      path.quadraticBezierTo(startX + 80, startY - 40, startX + 120, startY + 60);
      path.quadraticBezierTo(startX + 60, startY + 120, startX - 40, startY + 80);
      path.quadraticBezierTo(startX - 80, startY + 20, startX, startY);
      canvas.drawPath(path, paint);
    }
    for (int i = 0; i < 15; i++) {
      paint.color = Colors.white.withOpacity(0.02 + (i % 4) * 0.015);
      final centerX = size.width * random[i % random.length];
      final centerY = size.height * random[(i + 5) % random.length];
      final radius = 15 + (i % 3) * 10.0;
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
