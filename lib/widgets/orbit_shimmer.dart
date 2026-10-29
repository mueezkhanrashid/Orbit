import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loading — flat grey bar at real size, no shimmer gradient (app spec §11)
/// Labels and headers shown at once, no shift when data lands. No shimmer.
class OrbitShimmer extends StatelessWidget {
  final double width, height; final double radius;
  const OrbitShimmer({super.key, required this.width, required this.height, this.radius = 6});
  @override Widget build(BuildContext context) {
    return Container(width: width, height: height, decoration: BoxDecoration(color: OrbitTheme.border, borderRadius: BorderRadius.circular(radius)));
  }
}

class OrbitErrorCard extends StatelessWidget {
  final String title, subtitle; final VoidCallback onRetry;
  const OrbitErrorCard({super.key, required this.title, required this.subtitle, required this.onRetry});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.wifi_off, size: 18, color: OrbitTheme.muted),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OrbitTheme.text)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: OrbitTheme.muted)),
      ])),
      TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(fontSize: 11, color: OrbitTheme.text))),
    ]),
  );
}
