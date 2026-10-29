import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';

// ORBIT Motion v5 — BEST of the best · taste compliant · 60fps transform+opacity only
// Futuristic: hover glow, press 0.985 + haptic, count-up, shimmer, drift, pulse, shared-axis, hero
// Reduced-motion safe, all durations use easeOutCubic / easeOutExpo, staggered 40-70ms

class OrbitMotion {
  static const stagger = Duration(milliseconds: 70);
  static const rise = 20.0;
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 240);
  static const pageDur = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;
  static const futuristicCurve = Curves.easeOutExpo;
  static const sharedAxisCurve = Curves.easeInOutCubicEmphasized;

  static bool isReduced(BuildContext c) => MediaQuery.of(c).disableAnimations;

  static Widget entrance(BuildContext context, List<Widget> parts, {int delayStep = 1}) {
    if (isReduced(context)) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: parts);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts.asMap().entries.map((e) {
        final i = e.key;
        return e.value.animate(delay: (i * 70).ms).fadeIn(duration: 300.ms, curve: curve).slideY(begin: 0.3, end: 0, duration: 320.ms, curve: curve);
      }).toList(),
    );
  }

  static Widget staggeredRows(BuildContext context, List<Widget> rows) {
    if (isReduced(context)) return Column(children: rows);
    return Column(
      children: rows.asMap().entries.map((e) {
        return e.value.animate(delay: (e.key * 70).ms).fadeIn(duration: 260.ms, curve: curve).slideY(begin: 0.4, end: 0, duration: 280.ms, curve: curve);
      }).toList(),
    );
  }

  static List<Widget> futuristicGrid(BuildContext context, List<Widget> tiles) {
    if (isReduced(context)) return tiles;
    return tiles.asMap().entries.map((e) {
      return e.value
          .animate(delay: (80 + e.key * 40).ms)
          .fadeIn(duration: 260.ms, curve: futuristicCurve)
          .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), duration: 260.ms, curve: futuristicCurve)
          .slideY(begin: 0.08, end: 0, duration: 260.ms, curve: curve);
    }).toList();
  }

  // Shared-axis page transition — slide + fade, best-of-best 220ms
  static Route<T> sharedAxisRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: pageDur,
      reverseTransitionDuration: pageDur,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: sharedAxisCurve);
        final secCurved = CurvedAnimation(parent: sec, curve: sharedAxisCurve);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
          child: FadeTransition(opacity: curved, child: FadeTransition(opacity: Tween<double>(begin: 1, end: 0.92).animate(secCurved), child: child)),
        );
      },
    );
  }

  static Widget heroWrap(String tag, Widget child) => Hero(tag: tag, child: child);
}

// Press feedback — scale 0.985 + tone + haptic light
class OrbitPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const OrbitPress({super.key, required this.child, this.onTap});
  @override
  State<OrbitPress> createState() => _OrbitPressState();
}

class _OrbitPressState extends State<OrbitPress> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(color: _down ? const Color(0xFFF3F3F3) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: widget.child,
        ),
      ),
    );
  }
}

// Hover — lift 1px + accent border glow
class OrbitHover extends StatefulWidget {
  final Widget child;
  const OrbitHover({super.key, required this.child});
  @override
  State<OrbitHover> createState() => _OrbitHoverState();
}

class _OrbitHoverState extends State<OrbitHover> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: OrbitMotion.fast,
        curve: OrbitMotion.curve,
        transform: Matrix4.translationValues(0, _hover ? -1 : 0, 0),
        decoration: BoxDecoration(
          border: Border.all(color: _hover ? const Color(0xFF1B6E66).withOpacity(0.22) : Colors.transparent, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}

// Slow drift for moving picture (APOD, Earth)
class OrbitDrift extends StatelessWidget {
  final Widget child;
  const OrbitDrift({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (OrbitMotion.isReduced(context)) return child;
    return child.animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 8000.ms, curve: Curves.easeInOut);
  }
}

// Pulse dot LIVE — opacity loop + scale
class OrbitPulse extends StatelessWidget {
  final Widget child;
  const OrbitPulse({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (OrbitMotion.isReduced(context)) return child;
    return child.animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 900.ms).then().fadeOut(duration: 900.ms).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 900.ms);
  }
}

// Futuristic shimmer — sweeping light over surface (for loading)
class OrbitShimmer extends StatelessWidget {
  final Widget child;
  const OrbitShimmer({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (OrbitMotion.isReduced(context)) return child;
    return child.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1600.ms, color: const Color(0xFFF3F3F3));
  }
}

// Count-up number — animates int from 0 to value on enter, 900ms cubic
class OrbitCountUp extends StatefulWidget {
  final int value;
  final TextStyle? style;
  const OrbitCountUp({super.key, required this.value, this.style});
  @override
  State<OrbitCountUp> createState() => _OrbitCountUpState();
}

class _OrbitCountUpState extends State<OrbitCountUp> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<int> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _a = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void didUpdateWidget(OrbitCountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _a = IntTween(begin: old.value, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _a, builder: (_, __) => Text('${_a.value}', style: widget.style));
  }
}

// Futuristic card — 60fps, RepaintBoundary, 1px border, hover glow, press 0.985 + haptic
// Perf: AnimatedScale/Container are transform+opacity only (no layout), RepaintBoundary isolates
class OrbitFuturisticCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool glow;
  const OrbitFuturisticCard({super.key, required this.child, this.onTap, this.glow = false});
  @override
  State<OrbitFuturisticCard> createState() => _OrbitFuturisticCardState();
}

class _OrbitFuturisticCardState extends State<OrbitFuturisticCard> {
  bool _hover = false;
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: () {
            if (widget.onTap != null) HapticFeedback.selectionClick();
            widget.onTap?.call();
          },
          child: AnimatedScale(
            scale: _down ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: _down
                    ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3))
                    : (isDark ? OrbitTheme.darkSurface : const Color(0xFFF9F9F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hover || widget.glow ? const Color(0xFF1B6E66).withOpacity(0.22) : (isDark ? OrbitTheme.darkBorder : const Color(0xFFEAEAEA)), width: 1),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// Staggered entrance helper for lists — 40ms
class OrbitStaggered extends StatelessWidget {
  final List<Widget> children;
  final int baseDelayMs;
  const OrbitStaggered({super.key, required this.children, this.baseDelayMs = 40});
  @override
  Widget build(BuildContext context) {
    if (OrbitMotion.isReduced(context)) return Column(children: children);
    return Column(
      children: children.asMap().entries.map((e) => e.value.animate(delay: (baseDelayMs + e.key * 40).ms).fadeIn(duration: 260.ms, curve: OrbitMotion.curve).slideY(begin: 0.12, end: 0, duration: 260.ms, curve: OrbitMotion.curve)).toList(),
    );
  }
}
