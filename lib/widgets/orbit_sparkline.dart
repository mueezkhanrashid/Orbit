import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gradient sparkline with soft fill — matches UX v2.
class OrbitSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  const OrbitSparkline({super.key, required this.values, required this.color, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _SparkPainter(values, color)));
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> v; final Color c;
  _SparkPainter(this.v, this.c);
  @override
  void paint(Canvas canvas, Size s) {
    if (v.length < 2) return;
    final minV = v.reduce((a,b)=> a<b?a:b), maxV = v.reduce((a,b)=> a>b?a:b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final points = <Offset>[];
    for (int i=0;i<v.length;i++) {
      final x = s.width * i / (v.length-1);
      final y = s.height - ((v[i]-minV)/range) * s.height * 0.85 - s.height*0.08;
      points.add(Offset(x,y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i=1;i<points.length;i++) {
      final p0 = points[i-1], p1 = points[i];
      final cp = Offset((p0.dx+p1.dx)/2, p0.dy);
      path.quadraticBezierTo(cp.dx, cp.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(path)..lineTo(s.width, s.height)..lineTo(0, s.height)..close();
    final fillPaint = Paint()
      ..color = c.withOpacity(0.14)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fill, fillPaint);
    final line = Paint()..color = c..strokeWidth = 1.6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);
    // dot on last
    canvas.drawCircle(points.last, 2.2, Paint()..color = c);
    canvas.drawCircle(points.last, 4.5, Paint()..color = c.withOpacity(0.18));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}

/// 36px Zikar ring — tappable, haptics, 33-step.
class ZikarRing extends StatelessWidget {
  final int count, goal; final VoidCallback onTap;
  const ZikarRing({super.key, required this.count, required this.goal, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final pct = (count % goal) / goal;
    return GestureDetector(onTap: onTap, child: SizedBox(width: 36, height: 36, child: Stack(alignment: Alignment.center, children: [
      SizedBox(width: 36, height: 36, child: CircularProgressIndicator(value: pct, strokeWidth: 3, backgroundColor: OrbitTheme.outline, valueColor: const AlwaysStoppedAnimation(OrbitTheme.primary))),
      Text('${count % goal}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: OrbitTheme.primary)),
    ])));
  }
}
