import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../theme/advanced_animations.dart';
import '../../core/data/orbit_advanced_repository.dart';
import '../../core/location/location_service.dart';
import '../../app/providers.dart';

/// Advanced Analytics — FUTURISTIC, , private, interactive
/// KPI with count-up, hover glow, 7-day spark, top leads live pulse.

class AdvancedAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAnalyticsScreen({super.key});
  @override ConsumerState<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}
class _AdvancedAnalyticsScreenState extends ConsumerState<AdvancedAnalyticsScreen> {
  Map<String, dynamic>? _snapshot;
  List<dynamic>? _leads;
  Map<String, dynamic>? _weatherAdv;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = OrbitAdvancedRepository(dio: ref.read(dioProvider));
      final loc = await ref.read(locationProvider.future).catchError((_) => OrbitLocation.rawalpindi());
      final snap = await repo.analyticsSnapshot();
      final leads = await repo.smartLeadsAdvanced(loc, limit: 6);
      Map<String, dynamic>? weather;
      try { weather = await repo.weatherAdvanced(loc); } catch (_) {}
      if (!mounted) return;
      setState(() { _snapshot = snap; _leads = leads; _weatherAdv = weather; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitTheme.ground,
      appBar: AppBar(title: const Text('Advanced Analytics'), backgroundColor: OrbitTheme.ground, elevation: 0, surfaceTintColor: Colors.transparent),
      body: RefreshIndicator(
        onRefresh: _load,
        color: OrbitTheme.accent,
        child: ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, 
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(children:[
              Text('Analytics', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width:8),
              Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999), border: Border.all(color: OrbitTheme.accent.withOpacity(0.12))), child: Row(mainAxisSize:MainAxisSize.min, children:[OrbitPulse(child: Container(width:5,height:5, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle))), const SizedBox(width:4), const Text('LIVE', style: TextStyle(fontSize:10, color:OrbitTheme.accent, fontWeight:FontWeight.w700))])),
            ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0),
            const SizedBox(height: 4),
            Text('Updated now', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (_loading)
              OrbitShimmer(child: Container(height:120, decoration: BoxDecoration(color: OrbitTheme.surface, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(12))))
            else ...[
              // KPI strip — futuristic count-up + hover glow
              OrbitFuturisticCard(
                child: Row(children: [
                  _kpiFuturistic('Taps', _snapshot?['totalTaps'] ?? 0, 'All time'),
                  _divider(),
                  _kpiFuturistic('Saves', _snapshot?['totalSaves'] ?? 0, 'Hot ≥82'),
                  _divider(),
                  _kpiFuturistic('Keywords', ((_snapshot?['topKeywords'] as String? ?? '').split(',').where((s) => s.trim().isNotEmpty).length), 'Learned'),
                  _divider(),
                  _kpiFuturistic('Leads', _leads?.length ?? 0, 'Top ranked'),
                ]),
              ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              // Learned keywords — interactive chips with haptic
              OrbitFuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Learned for you', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('From your activity', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final kw in ((_snapshot?['topKeywords'] as String? ?? 'flutter, erasmus, rawalpindi').split(',').take(5)))
                        InkWell(
                          onTap: (){ HapticFeedback.selectionClick(); ref.read(searchQueryProvider.notifier).state = kw.trim(); },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(999), border: Border.all(color: OrbitTheme.border)), child: Text(kw.trim(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: OrbitTheme.text))),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Text('History: ${_snapshot?['historyCount'] ?? 0} events • Last: ${_snapshot?['generatedAt']?.toString().substring(11,16) ?? '--'} • Tap chip to search', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10)),
                  ]),
                ),
              ).animate(delay: 140.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              // Weather 7-day — futuristic bars with accent gradient illusion via opacity steps
              if (_weatherAdv != null)
                OrbitFuturisticCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children:[Text('Weather 7-day • Hourly + AQ', style: Theme.of(context).textTheme.titleMedium), const Spacer(), OrbitPulse(child: Container(width:6,height:6, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle))), const SizedBox(width:4), const Text('Live', style: TextStyle(fontSize:10, color:OrbitTheme.accent, fontWeight:FontWeight.w700))]),
                      const SizedBox(height: 8),
                      Text('High ${_weatherAdv?['daily']?['temperature_2m_max']?[0] ?? '--'}° • Low ${_weatherAdv?['daily']?['temperature_2m_min']?[0] ?? '--'}° • Sunrise ${_weatherAdv?['daily']?['sunrise']?[0]?.toString().substring(11,16) ?? '--'} • AQ ${_weatherAdv?['air_quality']?['current']?['us_aqi'] ?? '--'}', style: const TextStyle(fontSize: 11, color: OrbitTheme.muted)),
                      const SizedBox(height: 10),
                      SizedBox(height: 56, child: Row(children: List.generate(7, (i) {
                        final max = _weatherAdv?['daily']?['temperature_2m_max']?[i] ?? 0;
                        final min = _weatherAdv?['daily']?['temperature_2m_min']?[i] ?? 0;
                        final prob = _weatherAdv?['daily']?['precipitation_probability_max']?[i];
                        return Expanded(child: Column(children: [
                          Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i % 7], style: const TextStyle(fontSize: 9, color: OrbitTheme.muted)),
                          const SizedBox(height: 4),
                          Container(height: 22, width: 6, decoration: BoxDecoration(color: OrbitTheme.accent.withOpacity(0.14 + i*0.09), borderRadius: BorderRadius.circular(3))),
                          const SizedBox(height: 4),
                          Column(children:[Text('${max.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])), Text('${min.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 8, color: OrbitTheme.muted, fontFeatures: [FontFeature.tabularFigures()]))]),
                          if(prob!=null) Text('${prob.toStringAsFixed(0)}%', style: const TextStyle(fontSize:7, color: OrbitTheme.muted)),
                        ]));
                      }))),
                    ]),
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              // Top leads — interactive, haptic, WHY
              OrbitFuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text('Top leads', style: Theme.of(context).textTheme.titleMedium), const Spacer(), OrbitPulse(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle))), const SizedBox(width: 6), const Text('Live • Futuristic', style: TextStyle(fontSize: 11, color: OrbitTheme.accent))]),
                    const SizedBox(height: 8),
                    for (final l in (_leads ?? []).take(4))
                      InkWell(
                        onTap: (){ HapticFeedback.lightImpact(); },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.title.length > 48 ? '${l.title.substring(0,48)}…' : l.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${l.org} • ${l.location} • ${l.match}%', style: const TextStyle(fontSize: 10, color: OrbitTheme.muted, fontFeatures: [FontFeature.tabularFigures()])),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: l.match >= 82 ? OrbitTheme.successSoft : const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(999)), child: Text('${l.match}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: l.match >= 82 ? OrbitTheme.success : OrbitTheme.muted))),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text('Tap to view details', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize:10)),
                  ]),
                ),
              ).animate(delay: 260.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiFuturistic(String label, int value, String caption) => Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, color: OrbitTheme.muted)),
    const SizedBox(height: 4),
    OrbitCountUp(value: value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: OrbitTheme.text, fontFeatures: [FontFeature.tabularFigures()])),
    Text(caption, style: const TextStyle(fontSize: 10, color: OrbitTheme.muted)),
  ])));
  Widget _divider() => Container(width: 1, height: 56, color: OrbitTheme.border);
}
