import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Editorial-greeting panel — tonal one step off white (#f9f9f9), 1px #eaeaea, radius 12, pad 16, no shadow.
/// One gap 16. White inner card used once for main chart (use OrbitChartCard). Rules: app-screens.md §4.2, §9.4
class OrbitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool tonal; // true = surface #f9f9f9 (default per sheet), false = white raised for chart
  final Color? color;
  const OrbitCard({super.key, required this.child, this.margin, this.padding, this.onTap, this.tonal = true, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: color ?? (tonal ? OrbitTheme.surface : OrbitTheme.raised),
        borderRadius: BorderRadius.circular(OrbitTheme.rPanel),
        border: Border.all(color: OrbitTheme.border, width: 1),
        // No shadow on resting cards — app rule 9.4
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(OrbitTheme.rPanel),
          // Ink splash on tonal is subtle — use active #eeeeee
          splashColor: const Color(0xFFEEEEEE),
          highlightColor: const Color(0xFFF3F3F3),
          child: Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Main chart white inner card — the one white card inside tonal panel per sheet (home)
class OrbitChartCard extends StatelessWidget {
  final Widget child;
  const OrbitChartCard({super.key, required this.child});
  @override Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(8), border: Border.all(color: OrbitTheme.border)),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class OrbitSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool live;
  final String? countChip; // e.g. "8,000+ total" — 12px grey header label, not pill above heading
  const OrbitSectionTitle({super.key, required this.title, this.action, this.onAction, this.live = false, this.countChip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium), // 14/600 per sheet
        if (countChip != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: OrbitTheme.surfaceTint, borderRadius: BorderRadius.circular(999), border: Border.all(color: OrbitTheme.border)),
            child: Text(countChip!, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: OrbitTheme.muted, fontSize: 11)),
          ),
        ],
        if (live) ...[
          const SizedBox(width: 6),
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Live', style: Theme.of(context).textTheme.labelSmall!.copyWith(color: OrbitTheme.accent, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
        const Spacer(),
        if (action != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(children: [
                Text(action!, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: OrbitTheme.text, fontWeight: FontWeight.w500)), // ink link, chevron 12
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right, size: 12, color: OrbitTheme.text),
              ]),
            ),
          ),
      ],
    );
  }
}
