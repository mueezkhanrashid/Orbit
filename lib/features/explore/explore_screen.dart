import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../theme/advanced_animations.dart';
import '../../app/providers.dart';
import '../../core/widget/widget_types.dart';
import '../analytics/advanced_analytics_screen.dart';
import '../widget/widget_config_screen.dart';
import '../space/space_screen.dart';
import '../markets/markets_screen.dart';
import '../leads/leads_screen.dart';
import '../opportunities/opportunities_screen.dart';
import '../faith/faith_screen.dart';
import '../assistant/assistant_screen.dart';
import '../productivity/productivity_screen.dart';
import '../notebook/notebook_screen.dart';
import '../fitness/fitness_screen.dart';
import '../scholarships/scholarships_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }
  void _push(Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, OrbitMotion.sharedAxisRoute(page));
  }
  @override Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider).valueOrNull;
    final city = loc?.city ?? 'Rawalpindi';
    final markets = ref.watch(marketsProvider).valueOrNull;
    final qLbl = loc != null ? QiblaMath.bearingLabel(loc.lat, loc.lng) : QiblaMath.bearingLabel(33.5651, 73.0169);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      color: OrbitTheme.accent,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        ref.invalidate(locationProvider);
        ref.invalidate(marketsProvider);
        ref.invalidate(weatherProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        cacheExtent: OrbitPerformance.cacheExtent,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (markets != null && markets.isNotEmpty)
            Container(
              height: 28,
              color: isDark ? OrbitTheme.darkText : OrbitTheme.text,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                OrbitPulse(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF1B6E66), shape: BoxShape.circle))),
                const SizedBox(width: 6),
                const Text('LIVE 60s', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final m in markets.take(5))
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text('${m.symbol} ${m.price.toStringAsFixed(0)} ${m.changePct >= 0 ? '+' : ''}${m.changePct.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 10, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
                        ),
                    ]),
                  ),
                ),
                Icon(Icons.chevron_right, size: 12, color: Colors.white.withOpacity(0.6)),
              ]),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: BoxDecoration(color: isDark ? OrbitTheme.darkSurface : OrbitTheme.raised, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border)),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: isDark ? OrbitTheme.darkText : OrbitTheme.text),
                  decoration: InputDecoration(
                    hintText: 'Search ORBIT — jobs near $city, scholarships, Quran…',
                    hintStyle: Theme.of(context).textTheme.bodySmall,
                    prefixIcon: const Icon(Icons.search, size: 16, color: OrbitTheme.muted),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mic_none, size: 16, color: OrbitTheme.muted),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice search — on-device'), duration: Duration(seconds: 1)));
                          },
                        ),
                        if (loc != null)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isDark ? OrbitTheme.darkGround : OrbitTheme.surface, border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border), borderRadius: BorderRadius.circular(999)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.location_on, size: 10, color: OrbitTheme.muted), const SizedBox(width: 3), Text(city, style: const TextStyle(fontSize: 11, color: OrbitTheme.muted))]),
                          ),
                      ],
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (q) {
                    HapticFeedback.lightImpact();
                    ref.read(searchQueryProvider.notifier).state = q;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Searching "$q" across ORBIT…'), duration: const Duration(seconds: 1)));
                  },
                  onChanged: (q) {
                    if (q.length > 2) ref.read(searchQueryProvider.notifier).state = q;
                  },
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in ['All', 'Jobs', 'Scholarships', 'News', 'Weather'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _filter = f);
                        },
                        selectedColor: isDark ? OrbitTheme.darkText : const Color(0xFFEEEEEE),
                        backgroundColor: isDark ? OrbitTheme.darkSurface : OrbitTheme.surface,
                        side: BorderSide(color: _filter == f ? (isDark ? OrbitTheme.darkText : OrbitTheme.text).withOpacity(0.12) : (isDark ? OrbitTheme.darkBorder : OrbitTheme.border)),
                        labelStyle: TextStyle(fontSize: 11, fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w400, color: _filter == f ? (isDark ? OrbitTheme.darkGround : OrbitTheme.text) : (isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OrbitFuturisticCard(
              glow: true,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, OrbitMotion.sharedAxisRoute(const AdvancedAnalyticsScreen()));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: isDark ? OrbitTheme.darkText : OrbitTheme.text, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.analytics_outlined, size: 20, color: isDark ? OrbitTheme.darkGround : Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Advanced Analytics', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999), border: Border.all(color: OrbitTheme.accent.withOpacity(0.12))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [OrbitPulse(child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: OrbitTheme.accent, shape: BoxShape.circle))), const SizedBox(width: 4), const Text('LIVE', style: TextStyle(fontSize: 10, color: OrbitTheme.accent, fontWeight: FontWeight.w700))]),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [Text('Your activity & top leads • Qibla $qLbl', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11)), const SizedBox(width:4), const Icon(Icons.navigation_rounded, size:12, color: OrbitTheme.accent)]),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: OrbitTheme.muted),
                ]),
              ),
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.28,
              children: OrbitMotion.futuristicGrid(context, [
                _futuristicTile(context, 'Weather 7-day', '$city • Hourly • AQ Live', Icons.wb_sunny_outlined, isDark, onTap: () => _push(_WeatherDetail(city: city))),
                _futuristicTile(context, 'Space Live', 'ISS 5s • Earth • Missions • APOD', Icons.language_outlined, isDark, onTap: () => _push(const SpaceScreen())),
                _futuristicTile(context, 'Markets 15', 'KSE • BTC • ETH • SOL • 15 tickers', Icons.show_chart, isDark, onTap: () => _push(const MarketsScreen())),
                _futuristicTile(context, 'Leads Smart', 'Ranked for you • Hot • CRM', Icons.bolt_outlined, isDark, onTap: () => _push(const LeadsScreen())),
                _futuristicTile(context, 'Jobs 15k', 'Near you • 5,000+ jobs', Icons.work_outline, isDark, onTap: () => _push(const OpportunitiesScreen())),
                _futuristicTile(context, 'Faith Full', 'Quran 114 • Namaz • Qibla $qLbl • Audio', Icons.menu_book_outlined, isDark, onTap: () => _push(const FaithScreen())),
                _futuristicTile(context, 'Assistant+', 'Chat • Jobs • Scholarships • Namaz', Icons.auto_awesome_outlined, isDark, onTap: () => _push(const AssistantScreen())),
                _futuristicTile(context, 'Productivity Pro', 'Pomodoro • Calendar • Habits • Insights', Icons.task_alt_outlined, isDark, onTap: () => _push(const ProductivityScreen())),
                _futuristicTile(context, 'Widget 4x2 NEW', 'Qibla $qLbl • Swipeable • Live', Icons.widgets_outlined, isDark, onTap: () { HapticFeedback.mediumImpact(); Navigator.push(context, OrbitMotion.sharedAxisRoute(const WidgetConfigScreen())); }),
                _futuristicTile(context, 'Notebook+', 'Markdown • Tags • Search • Sync', Icons.edit_note_outlined, isDark, onTap: () => _push(const NotebookScreen())),
                _futuristicTile(context, 'Fitness+', 'Health • Steps • Qibla-walk', Icons.favorite_border, isDark, onTap: () => _push(const FitnessScreen())),
                _futuristicTile(context, 'Scholarships', '24 live • For Pakistani • Due soon', Icons.school_outlined, isDark, onTap: () => _push(const ScholarshipsScreen())),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _futuristicTile(BuildContext context, String title, String sub, IconData icon, bool isDark, {VoidCallback? onTap}) => OrbitFuturisticCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: isDark ? OrbitTheme.darkGround : OrbitTheme.ground, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border)), child: Icon(icon, size: 16, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
            const Spacer(),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? OrbitTheme.darkText : OrbitTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted, height: 1.25), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  // ignore: unused_element
  Widget _bullet(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('•  ', style: TextStyle(color: OrbitTheme.muted, fontSize: 11)), Expanded(child: Text(t, style: const TextStyle(fontSize: 11, height: 1.4, color: OrbitTheme.muted)))]),
      );
  // _bullet retained for future use
}

class _WeatherDetail extends StatelessWidget {
  final String city;
  const _WeatherDetail({required this.city});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Weather 7-day')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Weather for $city • 26° Sunny • H 28° L 18°\n\nHourly + AQ live in Home • Pull to refresh there.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium))),
      );
}
