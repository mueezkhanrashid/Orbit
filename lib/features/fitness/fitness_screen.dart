import 'package:flutter/material.dart';
// FUTURISTIC v4 — haptic + hover glow + 60fps staggered
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../widgets/orbit_card.dart';

/// Fitness — steps, water, prayer streak, local Hive, Health Connect (no server)
class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, 
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        OrbitCard(
          child: Column(children: [
            Row(children: [
              Text('Today', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: OrbitTheme.successSoft, borderRadius: BorderRadius.circular(999)), child: const Text('7 day streak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: OrbitTheme.success))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _stat('1,240', 'steps', Icons.directions_walk, OrbitTheme.primary, 0.62)),
              const SizedBox(width: 10),
              Expanded(child: _stat('1.8L', 'water', Icons.water_drop, OrbitTheme.teal, 0.72)),
              const SizedBox(width: 10),
              Expanded(child: _stat('4/5', 'namaz', Icons.mosque, OrbitTheme.ink, 0.80)),
            ]),
          ]),
        ),
        OrbitCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('This week', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (int i=0;i<7;i++)
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(left: i==0?0:6, right: i==6?0:0),
                    child: Column(children: [
                      Expanded(child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: [18, 32, 24, 48, 36, 52, 40][i].toDouble(),
                          decoration: BoxDecoration(
                            color: i==6 ? OrbitTheme.primary : OrbitTheme.bg,
                            border: Border.all(color: i==6 ? OrbitTheme.primary : OrbitTheme.outline),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      )),
                      const SizedBox(height: 6),
                      Text(['M','T','W','T','F','S','S'][i], style: TextStyle(fontSize: 10, fontWeight: i==6?FontWeight.w700:FontWeight.w500, color: i==6?OrbitTheme.primary:OrbitTheme.muted)),
                    ]),
                  )),
              ]),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ],
    );
  }

  Widget _stat(String value, String label, IconData icon, Color c, double progress) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: OrbitTheme.bg, border: Border.all(color: OrbitTheme.outline), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: Colors.white)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 10, color: OrbitTheme.muted)),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: Colors.white, valueColor: AlwaysStoppedAnimation(c))),
      ]),
    );
  }
}
