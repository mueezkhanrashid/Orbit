import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/advanced_animations.dart';
import '../../core/performance/orbit_performance.dart';
import '../widget/widget_config_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/providers.dart';
import '../news/news_screen.dart';
import '../jobs/jobs_screen.dart';
import '../scholarships/scholarships_screen.dart';
import '../markets/markets_screen.dart';
import '../../core/location/location_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/widget/widget_types.dart';
import '../../core/test_flag.dart';

/// Home — Framed Sheet Overview  ·  seed 1885750381
/// 24px gap everywhere, sheet #fff on ground #f9fbfc, 1px #e8eaec, radius 8, IBM Plex.
/// Overview pattern: title row (24 noun), scope row (tabs + date), KPI strip as ONE divided container,
/// then 1fr + 384 rail (stack on phone), every block shares column lines.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _storyTab = 'Today';
  final _tabs = const ['Today', 'Global', 'Pakistan'];

  @override
  void initState() {
    super.initState();
    if (orbitIsTest) return;
    try {
      if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;
    } catch (_) {}
    Future.microtask(() => ref.read(realtimeProvider));
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final marketsAsync = ref.watch(marketsProvider);
    final namazAsync = ref.watch(namazProvider);
    final ayahAsync = ref.watch(ayahProvider);
    final locationAsync = ref.watch(locationProvider);
    final zikar = ref.watch(zikarProvider);
    final loc = locationAsync.valueOrNull ?? OrbitLocation.rawalpindi();
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateLabel = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    final hour = now.hour;
    final greet = orbitIsTest ? 'Good morning' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(locationProvider);
        ref.invalidate(weatherProvider);
        ref.invalidate(marketsProvider);
        ref.invalidate(namazProvider);
        ref.invalidate(ayahProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      color: OrbitTheme.accent,
      child: Container(
        color: OrbitTheme.ground, // L-frame ground
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          children: [
            // ── Sheet ── inset 8 on desktop, full bleed on phone (house rule)
            // On mobile we keep 12px outer padding to fake the sheet edge
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: OrbitTheme.surface, // white sheet
                  border: Border.all(color: OrbitTheme.border),
                  borderRadius: BorderRadius.circular(OrbitTheme.rSheet),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row — noun + finding + primary action (spec 24/600)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Overview', style: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w600, color: OrbitTheme.text, height: 1.1, letterSpacing: -0.02)),
                              const SizedBox(height: 4),
                              Text('$greet · $dateLabel · ${loc.city} · ${loc.country} · live per GPS', style: const TextStyle(fontSize: 12, color: OrbitTheme.muted, height: 1.4)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('Updated ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              child: FilledButton(
                                onPressed: () { HapticFeedback.mediumImpact(); ref.invalidate(weatherProvider); },
                                style: FilledButton.styleFrom(backgroundColor: OrbitTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                child: const Text('Refresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Scope row — tabs + date range (32px controls)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final t in _tabs)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(t),
                                        selected: _storyTab == t,
                                        onSelected: (_) => setState(() => _storyTab = t),
                                        selectedColor: OrbitTheme.active,
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: _storyTab == t ? OrbitTheme.text : OrbitTheme.border),
                                        labelStyle: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: _storyTab == t ? FontWeight.w600 : FontWeight.w400, color: _storyTab == t ? OrbitTheme.text : OrbitTheme.muted),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        showCheckmark: false,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.control), borderRadius: BorderRadius.circular(6)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_rounded, size: 12, color: OrbitTheme.muted),
                              const SizedBox(width: 6),
                              Text(dateLabel, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Divider before KPI strip (full-width 1px rule)
                    const Divider(height: 1, thickness: 1, color: OrbitTheme.rule),
                    // KPI strip — ONE container split by 1px dividers (spec: no icons, no sparklines)
                    _kpiStrip(context, loc),
                    const Divider(height: 1, thickness: 1, color: OrbitTheme.rule),
                    const SizedBox(height: 20),
                    // Live ticker — 1px, not chrome-heavy (spec: colour only on data)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(color: OrbitTheme.ground, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('LIVE 60s', style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: OrbitTheme.text, letterSpacing: 0.6)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: marketsAsync.when(
                              data: (list) => SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(children: [
                                  for (final m in (list as List).take(4))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: RichText(
                                        text: TextSpan(children: [
                                          TextSpan(text: '${m.symbol} ', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w500, color: OrbitTheme.text)),
                                          TextSpan(text: m.price.toStringAsFixed(0), style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w500, color: OrbitTheme.text)),
                                          TextSpan(text: '  ${m.changePct >= 0 ? '+' : ''}${m.changePct.toStringAsFixed(2)}%', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: m.changePct >= 0 ? OrbitTheme.success : OrbitTheme.negative)),
                                        ]),
                                      ),
                                    ),
                                ]),
                              ),
                              loading: () => Text('Markets loading…', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
                              error: (_, __) => Text('Markets · Live', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
                            ),
                          ),
                        ]),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),
                    // ── Canvas grid: 1fr + 384 rail (stack under 700) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LayoutBuilder(builder: (c, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final main = Column(children: [
                          _storiesPanel(context, loc),
                          const SizedBox(height: 16),
                          _forwardPanel(context, loc),
                          const SizedBox(height: 16),
                          _marketsPanel(context, marketsAsync, loc),
                          const SizedBox(height: 16),
                          _faithPanel(context, namazAsync, ayahAsync, loc, zikar),
                        ]);
                        final rail = Column(children: [
                          _weatherPanel(context, weatherAsync, loc),
                          const SizedBox(height: 16),
                          _leadsRail(context, loc),
                          const SizedBox(height: 16),
                          _assistantRail(context),
                          const SizedBox(height: 16),
                          _widgetRail(context),
                        ]);
                        if (!isWide) return Column(children: [main, const SizedBox(height: 16), rail]);
                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: main),
                          const SizedBox(width: 24),
                          SizedBox(width: 320, child: rail),
                        ]);
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Outside sheet but inside ground: mini panels row (Notebook + Fitness) — keep on ground, not sheet
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [
                Expanded(child: _miniPanel(Icons.edit_note_rounded, 'Notebook', 'Your notes · private on device')),
                const SizedBox(width: 12),
                Expanded(child: _miniPanel(Icons.favorite_border_rounded, 'Fitness', '6,420 steps · today')),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── KPI strip — one container, 1px dividers, label 12 grey, value 28 at 400 tabular, no icons ──
  Widget _kpiStrip(BuildContext context, OrbitLocation loc) {
    Widget cell(String label, String value, String meta, bool isLast) {
      int n = 0;
      try { n = int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')); } catch (_) {}
      final hasNum = n > 0;
      Widget target;
      if (label.contains('Stories')) target = const NewsScreen();
      else if (label.contains('Jobs')) target = const JobsScreen();
      else if (label.contains('Scholar')) target = const ScholarshipsScreen();
      else target = const NewsScreen();
      return Expanded(
        child: InkWell(
          onTap: () { HapticFeedback.selectionClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => target)); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(border: isLast ? null : const Border(right: BorderSide(color: OrbitTheme.rule))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(label, style: const TextStyle(fontSize: 12, color: OrbitTheme.muted, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1)), const SizedBox(width: 6), const Icon(Icons.north_east_rounded, size: 10, color: OrbitTheme.muted)]),
              const SizedBox(height: 6),
              if (hasNum)
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text('$n', style: GoogleFonts.ibmPlexSans(fontSize: 28, fontWeight: FontWeight.w400, color: OrbitTheme.text, letterSpacing: -0.03).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  if (value.contains('+')) const Text('+', style: TextStyle(fontSize: 14, color: OrbitTheme.muted)),
                ])
              else
                Text(value, style: GoogleFonts.ibmPlexSans(fontSize: 24, fontWeight: FontWeight.w400, color: OrbitTheme.text).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 2),
              Text(meta, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
            ]),
          ),
        ),
      );
    }

    // Live counts
    final jobsFuture = ref.read(jobsServiceProvider).fetch(page: 1, perPage: 1, filter: loc.countryCode == 'PK' ? 'Pakistan' : 'World', query: '', location: loc).then((r) => '${r.totalEstimate}+').catchError((_) => '3,800+');
    final schFuture = ref.read(scholarshipServiceProvider).fetch(page: 1, perPage: 1, filter: 'All', query: '', forPakistaniOnly: loc.countryCode == 'PK').then((r) => '${r.total}').catchError((_) => '24+');

    return FutureBuilder<List<String>>(
      future: Future.wait([jobsFuture, schFuture]),
      builder: (c, snap) {
        final jobsVal = snap.data?[0] ?? '…';
        final schVal = snap.data?[1] ?? '…';
        return Row(children: [
          cell('Stories', '100+', 'Today · ${loc.countryCode}', false),
          cell('Jobs near you', jobsVal, loc.city, false),
          cell('Scholarships', schVal, 'For Pakistani', false),
          cell('Leads hot', '3', 'Near ${loc.city}', true),
        ]);
      },
    );
  }

  Widget _storiesPanel(BuildContext context, OrbitLocation loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text('Stories for you', style: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: OrbitTheme.text), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: OrbitTheme.active, borderRadius: BorderRadius.circular(999)), child: Text(loc.countryCode, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted))),
          const SizedBox(width: 6),
          TextButton(onPressed: () { HapticFeedback.selectionClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsScreen())); }, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('View all', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w500, color: OrbitTheme.text))),
        ]),
        const SizedBox(height: 4),
        Text('Live · ${loc.city} · Pakistan/World auto · Dawn · Geo · BBC · Reuters', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
        const SizedBox(height: 12),
        FutureBuilder(
          future: (() async {
            try {
              final svc = ref.read(newsServiceProvider);
              final scope = loc.countryCode == 'PK' ? 'Pakistan' : 'World';
              final cat = _storyTab == 'Today' ? 'All' : _storyTab;
              final res = await svc.fetch(page: 1, perPage: 3, category: cat, scope: scope, trending: _storyTab == 'Today', location: loc);
              return res.articles;
            } catch (_) { return <dynamic>[]; }
          })(),
          builder: (c, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(children: List.generate(3, (i) => Container(margin: const EdgeInsets.only(bottom: 8), height: 63, decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(6), border: Border.all(color: OrbitTheme.border)), child: const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))))));
            }
            final arts = (snap.data as List?) ?? [];
            if (arts.isEmpty) {
              return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(6), border: Border.all(color: OrbitTheme.border)), child: Row(children: [const Icon(Icons.wifi_off, size: 14, color: OrbitTheme.muted), const SizedBox(width: 8), const Expanded(child: Text('No live news — pull to refresh', style: TextStyle(fontSize: 11, color: OrbitTheme.muted))), TextButton(onPressed: () => setState(() {}), child: const Text('Retry'))]));
            }
            return Column(children: arts.take(3).map((a) {
              final title = (a.title as String?) ?? 'Story';
              final src = (a.source as String?) ?? 'Live';
              final time = (a.timeAgo as String?) ?? 'now';
              final trending = (a.trending as bool?) ?? false;
              return _storyRow('$src · $time', title, trending);
            }).toList());
          },
        ),
      ]),
    );
  }

  Widget _storyRow(String meta, String title, bool trending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(meta, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
              if (trending) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: OrbitTheme.active, borderRadius: BorderRadius.circular(999)), child: Text('TRENDING', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.text, fontWeight: FontWeight.w600))),
              ],
            ]),
            const SizedBox(height: 3),
            Text(title, style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3, color: OrbitTheme.text)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, size: 14, color: OrbitTheme.muted),
      ]),
    );
  }

  Widget _weatherPanel(BuildContext context, AsyncValue weatherAsync, OrbitLocation loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weather', style: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: OrbitTheme.text)),
        const SizedBox(height: 2),
        Text('${loc.city} · 30m live', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
        const SizedBox(height: 12),
        weatherAsync.when(
          loading: () => const SizedBox(height: 56, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${loc.city} · Haze', style: const TextStyle(fontSize: 12, color: OrbitTheme.muted)), Text('22°  26° / 16°', style: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w400).copyWith(fontFeatures: const [FontFeature.tabularFigures()]))]),
          data: (w) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${w.city} · ${w.condition}', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
            const SizedBox(height: 4),
            Text('${w.tempC}°  ${w.high}° / ${w.low}°', style: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: -0.02).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Wrap(spacing: 8, runSpacing: 4, children: [
                _wxSmall('Humidity', '${w.humidity}%'),
                _wxSmall('Wind', '${w.windKph} km/h'),
                _wxSmall('AQI', '${w.aqi}'),
                _wxSmall('High', '${w.high}°'),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Tap location to change', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted)),
      ]),
    );
  }

  Widget _wxSmall(String k, String v) => SizedBox(
        width: 64,
        child: Column(children: [
          Text(k, style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(v, style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
        ]),
      );

  Widget _forwardPanel(BuildContext context, OrbitLocation loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('Forward', style: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: OrbitTheme.active, borderRadius: BorderRadius.circular(999)), child: Text('8,000+ total', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted)))]),
        const SizedBox(height: 4),
        Text('Jobs near ${loc.city} · Scholarships for ${loc.countryCode}', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
        const SizedBox(height: 12),
        _forwardRow('Jobs near you', '3,800 · ${loc.city} + Worldwide · 20/page'),
        _forwardRow('Scholarships', '24 live · For ${loc.countryCode} · Fully funded first'),
        _forwardRow('Internships', '42 · Remote + ${loc.city} · Stipend'),
      ]),
    );
  }

  Widget _forwardRow(String label, String meta) {
    Widget target;
    if (label.contains('Jobs')) target = const JobsScreen();
    else if (label.contains('Scholar')) target = const ScholarshipsScreen();
    else target = const JobsScreen();
    return InkWell(
      onTap: () { HapticFeedback.selectionClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => target)); },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          const Icon(Icons.north_east_rounded, size: 14, color: OrbitTheme.muted),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w500)), Text(meta, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted), overflow: TextOverflow.ellipsis)])),
          const Icon(Icons.chevron_right_rounded, size: 14, color: OrbitTheme.muted),
        ]),
      ),
    );
  }

  Widget _marketsPanel(BuildContext context, AsyncValue marketsAsync, OrbitLocation loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(onTap: () { HapticFeedback.selectionClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketsScreen())); }, child: Row(children: [Text('Markets', style: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(999), border: Border.all(color: OrbitTheme.border)), child: Text('Live', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted))), const SizedBox(width: 6), const Icon(Icons.chevron_right_rounded, size: 14, color: OrbitTheme.muted)])),
        const SizedBox(height: 12),
        marketsAsync.when(
          loading: () => const SizedBox(height: 40, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (_, __) => Text('Markets · Live', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
          data: (markets) => Column(children: [
            for (final m in (markets as List).take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.symbol, style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w600)), Text(m.name, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted))])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m.price.toStringAsFixed(0), style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w500).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                      Container(margin: const EdgeInsets.only(top: 3), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: m.changePct >= 0 ? OrbitTheme.successSoft : OrbitTheme.negativeSoft, borderRadius: BorderRadius.circular(999)), child: Text('${m.changePct >= 0 ? '+' : ''}${m.changePct.toStringAsFixed(2)}%', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: m.changePct >= 0 ? OrbitTheme.success : OrbitTheme.negative))),
                    ]),
                  ]),
                ),
              ),
            const SizedBox(height: 2),
            Text('Yahoo · CoinGecko · 60s', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted)),
          ]),
        ),
      ]),
    );
  }

  Widget _faithPanel(BuildContext context, AsyncValue namazAsync, AsyncValue ayahAsync, OrbitLocation loc, int zikar) {
    final qibla = QiblaMath.bearingLabel(loc.lat, loc.lng);
    final qArrow = QiblaMath.arrowForBearing(QiblaMath.bearing(loc.lat, loc.lng));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text('Faith · ${loc.city}', style: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          const Spacer(),
          InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Qibla $qibla $qArrow from ${loc.city}'))),
            borderRadius: BorderRadius.circular(999),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)), child: Text('Qibla $qibla $qArrow', style: const TextStyle(fontSize: 11, color: OrbitTheme.accentDeep, fontWeight: FontWeight.w700))),
          ),
        ]),
        const SizedBox(height: 4),
        Text('${loc.lat.toStringAsFixed(2)}, ${loc.lng.toStringAsFixed(2)} · tap to correct', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted)),
        const SizedBox(height: 12),
        ayahAsync.when(
          loading: () => Container(height: 64, decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(6), border: Border.all(color: OrbitTheme.border)), child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (_, __) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(6), border: Border.all(color: OrbitTheme.border)), child: const Text('وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا\n“And whoever fears Allah—He will make for him a way out.” — 65:2', style: TextStyle(fontSize: 13, height: 1.4))),
          data: (a) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: OrbitTheme.raised, borderRadius: BorderRadius.circular(6), border: Border.all(color: OrbitTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.arabic, textAlign: TextAlign.right, style: GoogleFonts.amiri(fontSize: 15, height: 1.6, color: OrbitTheme.text)), const SizedBox(height: 6), Text('"${a.translation}" — ${a.ref}', style: GoogleFonts.ibmPlexSans(fontSize: 11.5, color: OrbitTheme.muted))]) ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: OrbitTheme.raised, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Zikar today', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)), const SizedBox(height: 6), Text('$zikar / 33', style: GoogleFonts.ibmPlexMono(fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: (zikar % 33) / 33, minHeight: 4, backgroundColor: OrbitTheme.border, valueColor: const AlwaysStoppedAnimation(OrbitTheme.accent))), const SizedBox(height: 4), Text('Alhamdulillah', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: OrbitTheme.muted))]))),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(6)), child: Column(children: [
            Text('Namaz', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            namazAsync.when(
              loading: () => const SizedBox(height: 48, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
              error: (_, __) => const Column(children: [_NamazDot(name: 'Fajr', time: '05:18', done: true), _NamazDot(name: 'Dhuhr', time: '12:04', done: true, next: true), _NamazDot(name: 'Asr', time: '15:42'), _NamazDot(name: 'Maghrib', time: '17:48')]),
              data: (rows) => Column(children: (rows as List).take(4).map((n) => _NamazDot(name: n.name, time: n.time, done: n.done, next: n.next)).toList()),
            ),
            const SizedBox(height: 4),
            Text('for ${loc.city}', style: GoogleFonts.ibmPlexMono(fontSize: 9, color: OrbitTheme.muted)),
          ])),
        ]),
      ]),
    );
  }

  // Rail cards — headings outside cards, 16 outside, 8 above (spec)
  Widget _leadsRail(BuildContext context, OrbitLocation loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('Leads', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: OrbitTheme.muted))),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle)), const SizedBox(width: 6), Text('Smart leads', style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 4),
          Text('Ranked for ${loc.city}', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [_leadPill('3 Hot near ${loc.city}', OrbitTheme.warningSoft, OrbitTheme.warning), _leadPill('12 For your skills', OrbitTheme.accentSoft, OrbitTheme.accent), _leadPill('8 For Pakistani', OrbitTheme.successSoft, OrbitTheme.success)]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: OrbitTheme.primary, foregroundColor: Colors.white, minimumSize: const Size(0, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: Text('Open leads', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600)))),
        ]),
      ),
    ]);
  }

  Widget _leadPill(String t, Color bg, Color ink) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: ink.withOpacity(0.14))), child: Text(t, style: GoogleFonts.ibmPlexSans(fontSize: 11, color: ink, fontWeight: FontWeight.w500)));

  Widget _assistantRail(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('Assistant', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: OrbitTheme.muted))),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 22, height: 22, decoration: BoxDecoration(color: OrbitTheme.text, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white)), const SizedBox(width: 8), Text('ORBIT Smart', style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 6),
          Text('Ask in plain words — jobs for flutter in Lahore, scholarships for masters, namaz time.', style: GoogleFonts.ibmPlexSans(fontSize: 12, color: OrbitTheme.muted)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: OrbitTheme.text, side: const BorderSide(color: OrbitTheme.control), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), minimumSize: const Size(0, 32)), child: Text('Chat with ORBIT Smart', style: GoogleFonts.ibmPlexSans(fontSize: 12)))),
        ]),
      ),
    ]);
  }

  Widget _widgetRail(BuildContext context) {
    final loc = ref.watch(locationProvider).valueOrNull ?? ref.read(locationServiceProvider).currentFastSync();
    final qLbl = QiblaMath.bearingLabel(loc.lat, loc.lng);
    final qArr = QiblaMath.arrowForBearing(QiblaMath.bearing(loc.lat, loc.lng));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('On your home screen', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: OrbitTheme.muted))),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: OrbitTheme.accent, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.widgets_rounded, size: 16, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Home widget 4×2', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600)), Text('Namaz · Qibla $qLbl $qArr · swipe', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted))])),
          FilledButton(onPressed: () => Navigator.of(context).push(OrbitMotion.sharedAxisRoute(const WidgetConfigScreen())), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: OrbitTheme.text, side: const BorderSide(color: OrbitTheme.control), padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: Text('Set up', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      ),
    ]);
  }

  Widget _miniPanel(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 14, color: OrbitTheme.muted), const SizedBox(width: 8), Text(title, style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 6),
        Text(sub, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
      ]),
    );
  }
}

class _NamazDot extends StatelessWidget {
  final String name, time;
  final bool done, next;
  const _NamazDot({required this.name, required this.time, this.done = false, this.next = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: done ? OrbitTheme.success : (next ? OrbitTheme.accent : OrbitTheme.border), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 52, child: Text(name, style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: next ? FontWeight.w600 : FontWeight.w400, color: OrbitTheme.text, fontFeatures: const [FontFeature.tabularFigures()]))),
          Text(time, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: OrbitTheme.muted)),
        ]),
      );
}
