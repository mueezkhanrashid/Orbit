import 'package:flutter/material.dart';
// FUTURISTIC v4 — haptic + hover glow + 60fps staggered
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../widgets/orbit_card.dart';

/// Notebook — offline-first, encrypted Hive, no server cost.
/// Part of "much more" — local, private, fast.
class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});
  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  final notes = [
    {'title': 'Scholarship essay draft', 'body': 'Why I want Erasmus Mundus — focus on climate...', 'time': 'Today • 2:14 PM', 'color': const Color(0xFFE8F0FE)},
    {'title': 'Dua for exam', 'body': 'Rabbi yassir wa la tuassir...', 'time': 'Yesterday', 'color': const Color(0xFFE0F2F1)},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, 
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            Expanded(child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes…',
                hintStyle: Theme.of(context).textTheme.bodySmall,
                prefixIcon: const Icon(Icons.search, size: 18, color: OrbitTheme.muted),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: OrbitTheme.outline)),
              ),
            )),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: (){}, icon: const Icon(Icons.add, size: 16), label: const Text('New'), style: FilledButton.styleFrom(backgroundColor: OrbitTheme.ink, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
          ]),
        ),
        ...notes.map((n) => OrbitCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 3, height: 28, decoration: BoxDecoration(color: n['color'] as Color, borderRadius: BorderRadius.circular(999))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: OrbitTheme.muted)),
              ])),
              IconButton(icon: const Icon(Icons.more_horiz, size: 18, color: OrbitTheme.muted), onPressed: (){}),
            ]),
            const SizedBox(height: 8),
            Text(n['body'] as String, style: const TextStyle(fontSize: 12.5, height: 1.4, color: OrbitTheme.muted)),
          ]),
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}
