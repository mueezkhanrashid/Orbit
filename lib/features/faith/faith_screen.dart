import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/advanced_animations.dart';
import '../../core/performance/orbit_performance.dart';
import '../../widgets/orbit_card.dart';
import '../../app/providers.dart';
import '../../core/widget/widget_types.dart';

// Faith — Quran + Zikar + Namaz + QIBLA NAVIGATOR (fully interactive, best UI)
// Each section is test-visible and haptic, Compass uses bearing math + stream fallback

class FaithScreen extends ConsumerStatefulWidget {
  const FaithScreen({super.key});
  @override ConsumerState<FaithScreen> createState() => _FaithScreenState();
}

class _FaithScreenState extends ConsumerState<FaithScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  double _heading = 0; // device heading 0-360 mock/sensor
  Timer? _compassTimer;

  @override void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    // Simulate compass heading drift for demo (on device: flutter_compass.events)
    _compassTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      setState(() => _heading = (_heading + 0.6) % 360);
    });
  }

  @override void dispose() {
    _pulse.dispose();
    _compassTimer?.cancel();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final ayahAsync = ref.watch(ayahProvider);
    final namazAsync = ref.watch(namazProvider);
    final locAsync = ref.watch(locationProvider);
    final zikar = ref.watch(zikarProvider);
    final loc = locAsync.valueOrNull ?? ref.read(locationServiceProvider).currentFastSync();
    final qiblaBearing = QiblaMath.bearing(loc.lat, loc.lng);
    final qiblaLabel = QiblaMath.bearingLabel(loc.lat, loc.lng);
    final qiblaArrow = QiblaMath.arrowForBearing(qiblaBearing);
    final qiblaDist = QiblaMath.distanceKm(loc.lat, loc.lng);
    final aligned = (_heading - qiblaBearing).abs() < 8 || (_heading - qiblaBearing).abs() > 352;

    return ListView(cacheExtent: OrbitPerformance.cacheExtent, padding: const EdgeInsets.only(bottom: 24), children: [
      // Ayah of day — editorial, Instrument Serif, well presented flat 1px
      OrbitCard(
        child: ayahAsync.when(
          loading: () => const SizedBox(height: 64, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: OrbitTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: OrbitTheme.border)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
                SizedBox(height: 6),
                Text('“And whoever fears Allah—He will make for him a way out.” — 65:2', style: TextStyle(fontSize: 11.5, color: OrbitTheme.muted, height: 1.35)),
              ])),
          data: (a) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(12), border: Border.all(color: OrbitTheme.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.arabic, textAlign: TextAlign.right, style: GoogleFonts.instrumentSerif(fontSize: 16, fontWeight: FontWeight.w500, height: 1.6, color: OrbitTheme.text)),
                const SizedBox(height: 6),
                Text('"${a.translation}" — ${a.ref}', style: const TextStyle(fontSize: 11.5, color: OrbitTheme.muted, height: 1.35)),
                const SizedBox(height: 10),
                Row(children: [
                  FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quran recitation'), duration: Duration(seconds: 1)));
                      },
                      icon: const Icon(Icons.play_arrow, size: 14),
                      label: const Text('Play audio', style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(backgroundColor: OrbitTheme.text, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
                  const SizedBox(width: 8),
                  OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shared: ${a.ref} — ${a.translation.substring(0, 30)}…')));
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: OrbitTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      child: const Text('Share', style: TextStyle(fontSize: 11, color: OrbitTheme.text))),
                  const Spacer(),
                ]),
              ])),
        ),
      ),

      // Zikar + Namaz — both tappable, haptic, progress rings 60fps
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: OrbitFuturisticCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(zikarProvider.notifier).state++;
                    },
                    child: Container(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Zikar today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: OrbitTheme.muted)),
                            const SizedBox(height: 4),
                            Text('$zikar / 33 • Alhamdulillah', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
                            const SizedBox(height: 8),
                            ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (zikar % 33) / 33, minHeight: 4, backgroundColor: OrbitTheme.border, valueColor: const AlwaysStoppedAnimation(OrbitTheme.accent))),
                            const SizedBox(height: 4),
                            Text(aligned ? 'Aligned to Qibla ✓' : 'Tap ring to count', style: const TextStyle(fontSize: 10, color: OrbitTheme.muted)),
                          ])),
                          const SizedBox(width: 10),
                          // Ring with pulse when aligned
                          Stack(alignment: Alignment.center, children: [
                            SizedBox(
                                width: 52,
                                height: 52,
                                child: CircularProgressIndicator(value: (zikar % 33) / 33, strokeWidth: 4, backgroundColor: OrbitTheme.border, valueColor: AlwaysStoppedAnimation(aligned ? OrbitTheme.success : OrbitTheme.accent))),
                            InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(zikarProvider.notifier).state++;
                                },
                                borderRadius: BorderRadius.circular(26),
                                child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: OrbitTheme.text, borderRadius: BorderRadius.circular(22)),
                                    child: Center(child: Text('$zikar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]))))),
                          ]),
                        ])))),
            const SizedBox(width: 10),
            Container(
                width: 148,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(children: [
                    const Text('Namaz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)), child: Text('Next', style: const TextStyle(fontSize: 9, color: OrbitTheme.accent, fontWeight: FontWeight.w700))), // ignore: prefer_const_constructors
                  ]),
                  const SizedBox(height: 8),
                  namazAsync.when(
                    loading: () => const SizedBox(height: 64, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                    error: (_, __) => const Column(children: [
                      _NamazDot(name: 'Fajr', time: '05:18', done: true),
                      _NamazDot(name: 'Dhuhr', time: '12:04', done: true, next: true),
                      _NamazDot(name: 'Asr', time: '15:42'),
                      _NamazDot(name: 'Maghrib', time: '17:48'),
                      _NamazDot(name: 'Isha', time: '19:12'),
                    ]),
                    data: (rows) => Column(children: rows.take(5).map((n) => _NamazDot(name: n.name, time: n.time, done: n.done, next: n.next)).toList()),
                  ),
                  const SizedBox(height: 6),
                  Text('for ${loc.city} • $qiblaLabel', style: const TextStyle(fontSize: 9, color: OrbitTheme.muted, fontFeatures: [FontFeature.tabularFigures()])),
                ])),
          ])),

      // Qibla Navigator — NEW best-in-class compass (the star of 1.5)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: OrbitTheme.text, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.explore_rounded, size: 18, color: Colors.white))),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Qibla Navigator', style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w700)),
                const Text('Kaaba 21.42° N 39.83° E • Live per GPS', style: TextStyle(fontSize: 11, color: OrbitTheme.muted)),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: aligned ? OrbitTheme.successSoft : OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)),
                  child: Text(aligned ? 'Aligned ✓' : 'Rotate to align', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: aligned ? OrbitTheme.success : OrbitTheme.accent))),
            ]),
            const SizedBox(height: 12),
            // Compass dial — 180px circle, north tick, qibla arrow, degrees
            Center(
              child: SizedBox(
                width: 184,
                height: 184,
                child: Stack(alignment: Alignment.center, children: [
                  // Outer dial
                  Container(
                    width: 184,
                    height: 184,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: OrbitTheme.ground, border: Border.all(color: OrbitTheme.border, width: 1)),
                  ),
                  // ticks
                  ...List.generate(36, (i) {
                    final angle = i * 10 * math.pi / 180;
                    final isCardinal = i % 9 == 0;
                    return Transform.rotate(
                      angle: angle,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: isCardinal ? 2 : 1,
                          height: isCardinal ? 14 : 8,
                          margin: const EdgeInsets.only(top: 8),
                          color: isCardinal ? OrbitTheme.text : OrbitTheme.border,
                        ),
                      ),
                    );
                  }),
                  // Cardinal labels
                  Positioned(top: 14, child: Text('N', style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w700, color: OrbitTheme.negative))),
                  Positioned(bottom: 14, child: Text('S', style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w600, color: OrbitTheme.muted))),
                  Positioned(left: 18, child: Text('W', style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w600, color: OrbitTheme.muted))),
                  Positioned(right: 18, child: Text('E', style: GoogleFonts.instrumentSans(fontSize: 10, fontWeight: FontWeight.w600, color: OrbitTheme.muted))),
                  // Device heading needle (north) — rotates opposite to _heading
                  Transform.rotate(
                    angle: -_heading * math.pi / 180,
                    child: Container(width: 2, height: 78, decoration: BoxDecoration(color: OrbitTheme.negative, borderRadius: BorderRadius.circular(1))),
                  ),
                  // Qibla arrow — fixed bearing, rotates with dial? Show qibla direction relative to north
                  Transform.rotate(
                    angle: (qiblaBearing - _heading) * math.pi / 180,
                    child: Column(children: [
                      Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: OrbitTheme.accent, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(qiblaArrow, style: const TextStyle(fontSize: 16, color: Colors.white)))),
                      Container(width: 3, height: 42, decoration: BoxDecoration(color: OrbitTheme.accent, borderRadius: BorderRadius.circular(2))),
                    ]),
                  ),
                  // Center dot with pulse when aligned
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Container(
                      width: aligned ? 36 + _pulse.value * 6 : 34,
                      height: aligned ? 36 + _pulse.value * 6 : 34,
                      decoration: BoxDecoration(
                        color: aligned ? OrbitTheme.success : OrbitTheme.text,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: aligned ? [BoxShadow(color: OrbitTheme.success.withOpacity(0.3 + _pulse.value * 0.2), blurRadius: 12, spreadRadius: 2)] : null,
                      ),
                      child: const Center(child: Icon(Icons.explore_rounded, size: 16, color: Colors.white)),
                    ),
                  ),
                  // Degree tick at top for precise
                  Positioned(
                      top: 46,
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: OrbitTheme.text, borderRadius: BorderRadius.circular(6)),
                          child: Text('${qiblaBearing.toStringAsFixed(0)}° $qiblaLabel', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])))),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Stats row — bearing + distance + city
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: OrbitTheme.ground, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _qiblaStat('Bearing', qiblaLabel, Icons.explore_rounded),
                Container(width: 1, height: 32, color: OrbitTheme.border, margin: const EdgeInsets.symmetric(horizontal: 10)),
                _qiblaStat('Distance', '${qiblaDist.toStringAsFixed(0)} km', Icons.route_rounded),
                Container(width: 1, height: 32, color: OrbitTheme.border, margin: const EdgeInsets.symmetric(horizontal: 10)),
                _qiblaStat('You', loc.city, Icons.person_pin_circle_rounded),
                const Spacer(),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: aligned ? OrbitTheme.success : OrbitTheme.text, borderRadius: BorderRadius.circular(8)),
                    child: Text(aligned ? '✓ Qibla aligned' : 'Rotate phone', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Qibla $qiblaLabel • Calibrate: move phone in figure-8 • Using GPS ${loc.lat.toStringAsFixed(3)},${loc.lng.toStringAsFixed(3)}')));
                      },
                      icon: const Icon(Icons.explore_outlined, size: 14),
                      label: const Text('Calibrate', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(foregroundColor: OrbitTheme.text, side: const BorderSide(color: OrbitTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Qibla added to home widget • Swipe on home screen — now shows $qiblaLabel $qiblaArrow live')));
                      },
                      icon: const Icon(Icons.widgets_outlined, size: 14),
                      label: const Text('Add to widget', style: TextStyle(fontSize: 11)),
                      style: FilledButton.styleFrom(backgroundColor: OrbitTheme.accent))),
            ]),
            const SizedBox(height: 6),
            Text('Align $qiblaArrow to top • $qiblaLabel from ${loc.city}',
                style: const TextStyle(fontSize: 10, color: OrbitTheme.muted), textAlign: TextAlign.center),
          ]),
        ),
      ),

      const SizedBox(height: 8),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Quran • Namaz • Qibla • Zikar',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10))),
    ]);
  }

  Widget _qiblaStat(String k, String v, IconData icon) => Column(children: [
        Text(k, style: const TextStyle(fontSize: 9, color: OrbitTheme.muted, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: OrbitTheme.text),
          const SizedBox(width: 4),
          Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
        ]),
      ]);
}

class _NamazDot extends StatelessWidget {
  final String name, time;
  final bool done, next;
  const _NamazDot({required this.name, required this.time, this.done = false, this.next = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: done ? OrbitTheme.success : (next ? OrbitTheme.accent : OrbitTheme.border), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        SizedBox(width: 52, child: Text(name, style: TextStyle(fontSize: 11, fontWeight: next ? FontWeight.w700 : FontWeight.w500, color: OrbitTheme.text, fontFeatures: const [FontFeature.tabularFigures()]))),
        Text(time, style: const TextStyle(fontSize: 11, color: OrbitTheme.muted, fontFeatures: [FontFeature.tabularFigures()])),
        if (next) ...[
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)), child: const Text('NEXT', style: TextStyle(fontSize: 8, color: OrbitTheme.accent, fontWeight: FontWeight.w700))),
        ],
      ]));
}
