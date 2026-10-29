// ORBIT Widget Config — user picks swipeable 4x2 cards, preview + reorder, well presented + Qibla compass
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../core/widget/widget_types.dart';
import '../../core/widget/orbit_widget_service.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});
  @override State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> with SingleTickerProviderStateMixin {
  List<OrbitWidgetType> _order = [];
  late List<OrbitWidgetType> _available;
  late PageController _previewCtrl;
  late AnimationController _pulse;
  int _previewIndex = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _order = OrbitWidgetService.loadOrder();
    _available = OrbitWidgetType.values.toList();
    _previewCtrl = PageController(viewportFraction: 0.92);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _previewCtrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    await OrbitWidgetService.saveOrder(_order);
    await OrbitWidgetService.scheduleBackground();
    await OrbitWidgetService.updateWidget();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Widget updated • Swipe on home screen'),
      duration: Duration(seconds: 2),
    ));
  }

  void _toggle(OrbitWidgetType t) {
    setState(() {
      if (_order.contains(t)) {
        _order.remove(t);
      } else {
        if (_order.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 6 cards — remove one first'), duration: Duration(seconds: 1)));
          return;
        }
        HapticFeedback.selectionClick();
        _order.add(t);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? OrbitTheme.darkGround : OrbitTheme.ground,
      appBar: AppBar(
        backgroundColor: isDark ? OrbitTheme.darkGround : OrbitTheme.ground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Widget • Home Screen',
              style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
          Text('Swipeable 4x2 • Medium • Qibla compass',
              style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border)),
        actions: [
          FilledButton(
            onPressed: _saving || _order.isEmpty ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: isDark ? OrbitTheme.darkText : OrbitTheme.text, foregroundColor: isDark ? OrbitTheme.darkGround : Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            child: _saving
                ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? OrbitTheme.darkGround : Colors.white))
                : const Text('Save & Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(cacheExtent: OrbitPerformance.cacheExtent, 
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Preview — swipeable PageView 4x2, well presented flat 1px + Qibla compass live
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Preview — swipe', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
                const Spacer(),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)),
                    child: const Text('4x2 Medium • Swipeable', style: TextStyle(fontSize: 10, color: OrbitTheme.accentDeep, fontWeight: FontWeight.w700))),
                const SizedBox(width: 6),
                Text('${_order.length} cards', style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 164,
                child: _order.isEmpty
                    ? Container(
                        decoration: BoxDecoration(color: isDark ? OrbitTheme.darkSurface : Colors.white, border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border), borderRadius: BorderRadius.circular(16)),
                        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.explore_rounded, size: 14, color: OrbitTheme.muted), const SizedBox(width:4), Text('Pick cards below • Max 6 • Try Qibla', style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted))])),
                      )
                    : PageView.builder(
                        controller: _previewCtrl,
                        onPageChanged: (i) => setState(() => _previewIndex = i),
                        itemCount: _order.length,
                        itemBuilder: (c, i) {
                          final t = _order[i];
                          final mock = _mockCard(t);
                          return Padding(
                            padding: EdgeInsets.only(right: i == _order.length - 1 ? 0 : 10),
                            child: _widgetCardPreview(mock, t, isActive: i == _previewIndex, isDark: isDark),
                          );
                        },
                      ),
              ),
              if (_order.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 0; i < _order.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: i == _previewIndex ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _previewIndex ? OrbitTheme.accent : (isDark ? OrbitTheme.darkBorder : OrbitTheme.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ]),
                const SizedBox(height: 6),
                Text('Swipe left or right on home screen  Tap Qibla card to open compass',
                    style: TextStyle(fontSize: 10, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
              ],
            ]),
          ),
          const SizedBox(height: 14),
          // Reorderable selected — drag to reorder swipe sequence
          if (_order.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: isDark ? OrbitTheme.darkSurface : Colors.white, border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border), borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(children: [
                      Text('Swipe order • Drag to reorder',
                          style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: isDark ? OrbitTheme.darkGround : const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(999)), child: Text('${_order.length}/6', style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _order.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final item = _order.removeAt(oldIdx);
                        _order.insert(newIdx, item);
                        HapticFeedback.selectionClick();
                      });
                    },
                    itemBuilder: (c, i) {
                      final t = _order[i];
                      final isQibla = t == OrbitWidgetType.qibla;
                      return Container(
                        key: ValueKey(t.name),
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: isDark ? OrbitTheme.darkGround : OrbitTheme.ground, border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: isQibla ? OrbitTheme.accent : (isDark ? OrbitTheme.darkText : OrbitTheme.text), borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Icon(t.icon, size: 18, color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(t.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
                              if (isQibla) ...[
                                const SizedBox(width: 6),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)), child: const Text('NEW', style: TextStyle(fontSize: 8, color: OrbitTheme.accent, fontWeight: FontWeight.w800))),
                              ],
                            ]),
                            Text(t.subtitle, style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (isQibla) const Text('256° W  3,522 km  Live', style: TextStyle(fontSize: 10, color: OrbitTheme.accent, fontWeight: FontWeight.w600)),
                          ])),
                          ReorderableDragStartListener(index: i, child: Icon(Icons.drag_handle, size: 18, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
                          const SizedBox(width: 8),
                          InkWell(
                              onTap: () => _toggle(t),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: OrbitTheme.negativeSoft, borderRadius: BorderRadius.circular(999)),
                                  child: const Text('Remove', style: TextStyle(fontSize: 10, color: OrbitTheme.negative, fontWeight: FontWeight.w700)))),
                        ]),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
          const SizedBox(height: 14),
          // Available — tap to add
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add cards • Tap to add • Max 6', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
              const SizedBox(height: 2),
              Text('Tip: add Qibla for Kaaba compass • Namaz already shows Qibla bearing', style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _available.map((t) {
                  final selected = _order.contains(t);
                  final isQibla = t == OrbitWidgetType.qibla;
                  return ChoiceChip(
                    label: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.icon, size: 14, color: selected ? Colors.white : (isDark ? OrbitTheme.darkText : OrbitTheme.text)),
                      const SizedBox(width: 4),
                      Text(t.label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : (isDark ? OrbitTheme.darkText : OrbitTheme.text))),
                      if (isQibla && !selected) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)), child: const Text('NEW', style: TextStyle(fontSize: 7, color: OrbitTheme.accent, fontWeight: FontWeight.w800)))],
                    ]),
                    selected: selected,
                    onSelected: (_) => _toggle(t),
                    selectedColor: isQibla ? OrbitTheme.accent : (isDark ? OrbitTheme.darkText : OrbitTheme.text),
                    backgroundColor: isDark ? OrbitTheme.darkSurface : Colors.white,
                    side: BorderSide(color: selected ? (isQibla ? OrbitTheme.accent : (isDark ? OrbitTheme.darkText : OrbitTheme.text)) : (isDark ? OrbitTheme.darkBorder : OrbitTheme.border)),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  );
                }).toList(),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final ok = await OrbitWidgetService.requestPinWidget();
                  if (!mounted) return;
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Widget pin requested — check home screen' : 'Add widget: long-press home screen  Widgets  ORBIT  drag 4x2'),
                      duration: const Duration(seconds: 2)));
                },
                icon: const Icon(Icons.widgets_outlined, size: 16),
                label: const Text('Add widget to home screen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(foregroundColor: isDark ? OrbitTheme.darkText : OrbitTheme.text, side: BorderSide(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetCardPreview(_MockCard m, OrbitWidgetType t, {required bool isActive, required bool isDark}) {
    final isQibla = t == OrbitWidgetType.qibla;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? OrbitTheme.darkSurface : Colors.white,
        border: Border.all(color: isActive ? (isQibla ? OrbitTheme.accent : (isDark ? OrbitTheme.darkText : OrbitTheme.text)) : (isDark ? OrbitTheme.darkBorder : OrbitTheme.border), width: isActive ? 1.4 : 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 3))] : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: isQibla ? OrbitTheme.accent : (isDark ? OrbitTheme.darkText : OrbitTheme.text), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Icon(t.icon, size: 16, color: Colors.white))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(t.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? OrbitTheme.darkText : OrbitTheme.text)),
              if (isQibla) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999)), child: const Text('QIBLA', style: TextStyle(fontSize: 7, color: OrbitTheme.accent, fontWeight: FontWeight.w800)))],
            ]),
            Text(m.subtitle, style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (isQibla)
            AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: OrbitTheme.accentSoft, borderRadius: BorderRadius.circular(999), border: Border.all(color: OrbitTheme.accent.withOpacity(0.15 + _pulse.value * 0.15))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.navigation_rounded, size: 14, color: OrbitTheme.accent),
                      SizedBox(width: 3),
                      Text('256° W', style: TextStyle(fontSize: 10, color: OrbitTheme.accent, fontWeight: FontWeight.w700)),
                    ])))
          else
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: OrbitTheme.successSoft, borderRadius: BorderRadius.circular(999)),
                child: const Text('Updated 14:32', style: TextStyle(fontSize: 10, color: OrbitTheme.success, fontWeight: FontWeight.w600))),
        ]),
        const Spacer(),
        if (isQibla) ...[
          Row(children: [
            // mini compass preview
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: OrbitTheme.accent, borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.explore_rounded, size: 18, color: Colors.white))),
            const SizedBox(width: 8),
            Expanded(child: Text(m.title, style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.01, color: isDark ? OrbitTheme.darkText : OrbitTheme.text).copyWith(fontFeatures: const [FontFeature.tabularFigures()]))),
          ]),
        ] else
          Text(m.title, style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.01, color: isDark ? OrbitTheme.darkText : OrbitTheme.text).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 2),
        Text(m.meta, style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted)),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(color: isDark ? OrbitTheme.darkGround : OrbitTheme.ground, border: Border.all(color: isDark ? OrbitTheme.darkBorder : OrbitTheme.border), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Text(m.value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? OrbitTheme.darkText : OrbitTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(Icons.chevron_right, size: 12, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted),
            ])),
      ]),
    );
  }

  // ignore: unused_element
  Widget _howRow(String k, String v, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 84, child: Text(k, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? OrbitTheme.darkText : OrbitTheme.text))),
          Expanded(child: Text(v, style: TextStyle(fontSize: 11, color: isDark ? OrbitTheme.darkMuted : OrbitTheme.muted, height: 1.3))),
        ]),
      );
}

class _MockCard {
  final String title, subtitle, meta, value;
  const _MockCard(this.title, this.subtitle, this.meta, this.value);
}

_MockCard _mockCard(OrbitWidgetType t) {
  switch (t) {
    case OrbitWidgetType.namaz:
      return const _MockCard('Fajr 05:18  Dhuhr 12:04', 'Next: Dhuhr in 2h 14m', 'Aladhan  Qibla 256 W', 'Qibla 256 W  3,522 km');
    case OrbitWidgetType.qibla:
      return const _MockCard('Qibla 256 W', 'Kaaba  3,522 km  Rawalpindi', 'Live bearing  14:32  Calibrated', 'Align 256 W  Tap to navigate');
    case OrbitWidgetType.space:
      return const _MockCard('ISS 51.6° • -0.1°', 'Live • 27600 km/h', 'wheretheiss.at • 14:32', 'Next: Falcon 9 • 18:42 UTC');
    case OrbitWidgetType.news:
      return const _MockCard('Pakistan climate budget 2026', 'Reuters • 2h • Auto PK', '100+ daily • 14:32', 'For you • Rawalpindi');
    case OrbitWidgetType.jobs:
      return const _MockCard('3,800 jobs • Rawalpindi', 'Flutter Dev — Careem • Remote', 'Near you • 14:32', 'Arbeitnow + Remotive • 20/page');
    case OrbitWidgetType.weather:
      return const _MockCard('26° Sunny', 'Rawalpindi • H 28° L 18°', 'Open-Meteo • 14:32', 'AQI 85 • Wind 10 kph');
    case OrbitWidgetType.markets:
      return const _MockCard('KSE 100 78542', '+0.52% • BTC 68,420', 'Yahoo/CoinGecko • 60s • 14:32', 'KSE • Crypto • Live');
    case OrbitWidgetType.quran:
      return const _MockCard('Ayah 65:2', 'And whoever fears Allah…', 'Quran.com', 'Tap to read • Audio');
    case OrbitWidgetType.scholarships:
      return const _MockCard('24 Scholarships', 'Erasmus Mundus • Fully funded', 'For Pakistani • 14:32', 'Due 2027-01-15  Apply');
    case OrbitWidgetType.internships:
      return const _MockCard('42 Internships', 'Software Intern • Remote', 'Near you • Stipend', 'Apply  Remote OK');
    case OrbitWidgetType.zikar:
      return const _MockCard('Zikar 33', 'Alhamdulillah • 12/33', 'Today • 14:32', '12/33 • Tap to count');
  }
}
