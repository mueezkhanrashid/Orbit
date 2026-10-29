import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// OrbitBalanced — Perfect, Balanced, Professional
/// Enforces framed-sheet rules: 1 gap 24, 1 pad 20, 8 radius, 1px #e8eaec, no shadow
/// Every card shares same metrics, so rows align and grid closes.

class OrbitBalancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const OrbitBalancedCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: OrbitTheme.surface,
          borderRadius: BorderRadius.circular(OrbitTheme.rCard), // 8
          border: Border.all(color: OrbitTheme.border, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(OrbitTheme.rCard),
            splashColor: OrbitTheme.active,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20), // pad 20 per spec
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class OrbitBalancedSkeleton extends StatelessWidget {
  final double height;
  final double width;
  const OrbitBalancedSkeleton({super.key, this.height = 14, this.width = double.infinity});
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: OrbitTheme.raised,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: OrbitTheme.border),
        ),
      ),
    );
  }
}

class OrbitSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const OrbitSectionHeader({super.key, required this.title, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OrbitTheme.muted)),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: OrbitTheme.muted, fontFamily: 'IBM Plex Mono')),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
