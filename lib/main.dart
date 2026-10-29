import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/test_flag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/news/news_screen.dart';
import 'features/space/space_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/faith/faith_screen.dart';
import 'features/opportunities/opportunities_screen.dart';
import 'features/notebook/notebook_screen.dart';
import 'features/fitness/fitness_screen.dart';
import 'features/scholarships/scholarships_screen.dart';
import 'features/assistant/assistant_screen.dart';
import 'features/leads/leads_screen.dart';
import 'features/productivity/productivity_screen.dart';
import 'core/storage/hive_boxes.dart';
import 'core/cache/fast_cache.dart';
import 'app/providers.dart';
import 'core/location/location_service.dart';
import 'core/services/jobs_service.dart';
import 'core/widget/orbit_widget_service.dart';
import 'core/widget/widget_types.dart';
import 'core/performance/orbit_performance.dart';
import 'core/brain/orbit_brain.dart';
import 'core/realtime/orbit_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OrbitPerformance.init();
  FlutterError.onError = (d) => FlutterError.presentError(d);
  await OrbitBoxes.init();
  final loc = _fastLocationSync();
  if (loc != null) FastCache().set('orbit_location_fast', loc);
  runApp(const ProviderScope(child: OrbitApp()));
}

OrbitLocation? _fastLocationSync() {
  try {
    final cached = OrbitBoxes.getCached(OrbitBoxes.prefs, 'orbit_location', const Duration(hours: 1));
    if (cached != null) return OrbitLocation.fromJson(Map<String, dynamic>.from(cached));
    final last = OrbitBoxes.box(OrbitBoxes.prefs).get('orbit_location');
    if (last is Map) return OrbitLocation.fromJson(Map<String, dynamic>.from(last));
  } catch (_) {}
  return OrbitLocation.rawalpindi();
}

class OrbitApp extends ConsumerWidget {
  const OrbitApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'ORBIT',
      debugShowCheckedModeBanner: false,
      theme: OrbitTheme.light,
      darkTheme: OrbitTheme.dark,
      themeMode: mode,
      home: const OrbitShell(),
      // Global snackbar + transitions
    );
  }
}

class OrbitShell extends ConsumerStatefulWidget {
  const OrbitShell({super.key});
  @override
  ConsumerState<OrbitShell> createState() => _OrbitShellState();
}

class _OrbitShellState extends ConsumerState<OrbitShell> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmup());
    WidgetsBinding.instance.addPostFrameCallback((_) { try { ref.read(orbitSyncProvider); ref.read(orbitBrainProvider); } catch (_) {} });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(const Duration(seconds: 2));
        await OrbitWidgetService.updateWidget();
        await OrbitWidgetService.scheduleBackground();
      } catch (_) {}
    });
  }

  Future<void> _warmup() async {
    if (orbitIsTest) return;
    try {
      if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;
    } catch (_) {}
    try {
      ref.read(locationServiceProvider).current(requestPermission: false).then((l) {
        FastCache().set('orbit_location_fast', l);
        ref.invalidate(weatherProvider);
        ref.invalidate(marketsProvider);
        ref.invalidate(namazProvider);
      });
      final loc = ref.read(locationServiceProvider).currentFastSync();
      ref.read(orbitServicesProvider).weather(loc);
      ref.read(orbitServicesProvider).markets(loc: loc);
      ref.read(orbitServicesProvider).namaz(loc);
      final repo = ref.read(advancedRepositoryProvider);
      repo.weatherAdvanced(loc).catchError((_) => <String, dynamic>{});
      repo.jobsAdvanced(loc: loc, page: 1, perPage: 6).catchError((_) => const JobsPage(jobs: [], hasMore: false, totalEstimate: 0));
      // Pre-warm qibla bearing for widget
      final b = QiblaMath.bearing(loc.lat, loc.lng);
      debugPrint('ORBIT warmup qibla $b ${QiblaMath.bearingLabel(loc.lat, loc.lng)} for ${loc.city}');
    } catch (_) {}
  }

  static const _titles = ['ORBIT', 'News', 'Space', 'Explore', 'Faith'];
  // ignore: unused_field
  static const _subs = ['Home • Rawalpindi', '100+ daily • Auto PK', 'Live ISS • Missions', 'Search everything', 'Quran • Namaz • Qibla'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = ref.watch(locationProvider).valueOrNull;
    final qibla = loc != null ? QiblaMath.bearingLabel(loc.lat, loc.lng) : (ref.read(locationServiceProvider).currentFastSync().let((l) => QiblaMath.bearingLabel(l.lat, l.lng)));
    // update Faith sub with live qibla
    final subsLive = ['Home • ${loc?.city ?? 'Rawalpindi'}', '100+ daily • Auto PK', 'Live ISS • Missions', 'Search everything', 'Quran • Namaz • Qibla $qibla'];

    return Scaffold(
      backgroundColor: isDark ? OrbitTheme.darkGround : OrbitTheme.ground,
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 16,
        backgroundColor: isDark ? OrbitTheme.darkGround : OrbitTheme.ground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(children: [
          Hero(
            tag: 'orbit-logo',
            child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: isDark ? OrbitTheme.darkText : OrbitTheme.accent, borderRadius: BorderRadius.circular(6)),
                child: const Center(child: Text('O', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.5)))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_titles[_idx], style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
            Text(subsLive[_idx], style: GoogleFonts.instrumentSans(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
          ]),
          const Spacer(),
          // Theme toggle (best interactive)
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              final cur = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state = cur == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border)), minimumSize: const Size(36, 36)),
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 6),
          _action(Icons.search_outlined, () => setState(() => _idx = 3), isDark),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border)),
      ),
      body: _LazyShellBody(idx: _idx),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border))),
        child: NavigationBar(
          height: 64,
          backgroundColor: isDark ? OrbitTheme.darkGround : OrbitTheme.ground,
          indicatorColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFEEEEEE),
          elevation: 0,
          selectedIndex: _idx,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _idx = i);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: 'News'),
            NavigationDestination(icon: Icon(Icons.language_outlined), selectedIcon: Icon(Icons.language), label: 'Space'),
            NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Faith'),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData i, VoidCallback t, bool isDark) => IconButton(
      onPressed: t,
      icon: Icon(i, size: 18, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted),
      style: IconButton.styleFrom(backgroundColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border)), minimumSize: const Size(36, 36)));
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

class _LazyShellBody extends StatelessWidget {
  final int idx;
  const _LazyShellBody({required this.idx});
  @override
  Widget build(BuildContext context) {
    switch (idx) {
      case 0:
        return const HomeScreen();
      case 1:
        return const NewsScreen();
      case 2:
        return const SpaceScreen();
      case 3:
        return const ExploreScreen();
      default:
        return const _FaithPocket();
    }
  }
}

class _FaithPocket extends StatelessWidget {
  const _FaithPocket({super.key}); // ignore: unused_element
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 8,
      child: Column(children: [
        Container(
          decoration: BoxDecoration(color: isDark ? OrbitTheme.darkGround : OrbitTheme.ground, border: Border(bottom: BorderSide(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border))),
          child: TabBar(
            isScrollable: true,
            indicatorColor: isDark ? OrbitTheme.darkText : OrbitTheme.text,
            labelColor: isDark ? OrbitTheme.darkText : OrbitTheme.text,
            unselectedLabelColor: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w400, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted),
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Faith'), Tab(text: 'Leads'), Tab(text: 'Jobs'), Tab(text: 'Scholarships'), Tab(text: 'Assistant'), Tab(text: 'Productivity'), Tab(text: 'Notes'), Tab(text: 'Fit')],
          ),
        ),
        const Expanded(child: TabBarView(children: [FaithScreen(), LeadsScreen(), OpportunitiesScreen(), ScholarshipsScreen(), AssistantScreen(), ProductivityScreen(), NotebookScreen(), FitnessScreen()])),
      ]),
    );
  }
}
