import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../theme/advanced_animations.dart';
import '../../app/providers.dart';
import '../../core/location/location_service.dart';

/// Markets — LIVE PSX + Crypto (Yahoo Chart + CoinGecko free, no dummy)
/// Pull to refresh, per-location, 60s foreground, honest offline
class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsAsync = ref.watch(marketsProvider);
    final locAsync = ref.watch(locationProvider);
    final loc = locAsync.valueOrNull ?? OrbitLocation.rawalpindi();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(marketsProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      color: OrbitTheme.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12,12,12,24),
        children: [
          // Header — live badge + location
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: OrbitTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: OrbitTheme.border)),
            child: Row(children:[
              Text('Markets', style: GoogleFonts.instrumentSans(fontSize:16, fontWeight: FontWeight.w700, color: OrbitTheme.text)),
              const SizedBox(width:8),
              OrbitPulse(child: Container(width:6,height:6, decoration: const BoxDecoration(color: OrbitTheme.success, shape: BoxShape.circle))),
              const SizedBox(width:6),
              Container(padding: const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration: BoxDecoration(color: OrbitTheme.successSoft, borderRadius: BorderRadius.circular(999)), child: const Text('Live • 60s', style: TextStyle(fontSize:10, fontWeight: FontWeight.w700, color: OrbitTheme.success))),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration: BoxDecoration(color: const Color(0xFFF3F3F3), border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(999)), child: Text(loc.countryCode, style: const TextStyle(fontSize:10, color: OrbitTheme.muted))),
            ]),
          ).animate().fadeIn(duration:300.ms).slideY(begin:0.06,end:0),
          const SizedBox(height:8),
          Text('PSX • Crypto • Real-time Yahoo + CoinGecko • Tap refresh if stale', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize:10)),
          const SizedBox(height:12),

          marketsAsync.when(
            loading: ()=> Column(children: List.generate(3, (i)=> Container(margin: const EdgeInsets.only(bottom:10), height:84, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(12)), child: const Center(child: SizedBox(width:16,height:16, child: CircularProgressIndicator(strokeWidth:2)))))),
            error: (e,_)=> Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(12)), child: Column(children:[ const Icon(Icons.wifi_off, color: OrbitTheme.muted), const SizedBox(height:8), Text('Markets offline • $e', style: const TextStyle(fontSize:11, color:OrbitTheme.muted), textAlign: TextAlign.center), const SizedBox(height:8), FilledButton(onPressed: ()=> ref.invalidate(marketsProvider), child: const Text('Retry'))])),
            data: (list){
              if(list.isEmpty){
                return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: OrbitTheme.border), borderRadius: BorderRadius.circular(12)), child: Column(children:[ const Icon(Icons.show_chart, color: OrbitTheme.muted), const SizedBox(height:8), const Text('No market data — pull to refresh', style: TextStyle(fontSize:11, color:OrbitTheme.muted)), const SizedBox(height:8), FilledButton(onPressed: ()=> ref.invalidate(marketsProvider), child: const Text('Retry'))]));
              }
              return Column(children:[
                for(final m in list) Padding(
                  padding: const EdgeInsets.only(bottom:10),
                  child: OrbitFuturisticCard(
                    onTap: (){ HapticFeedback.selectionClick(); },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                        Row(children:[
                          Container(width:7,height:7, decoration: BoxDecoration(color: m.changePct>=0? OrbitTheme.success : OrbitTheme.negative, shape: BoxShape.circle)),
                          const SizedBox(width:7),
                          Expanded(child: Text('${m.symbol} • ${m.name}', style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700))),
                          Container(padding: const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration: BoxDecoration(color: m.changePct>=0? OrbitTheme.successSoft : OrbitTheme.negativeSoft, borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children:[ Icon(m.changePct>=0? Icons.arrow_drop_up : Icons.arrow_drop_down, size:14, color: m.changePct>=0? OrbitTheme.success : OrbitTheme.negative), Text('${m.changePct>=0?'+':''}${m.changePct.toStringAsFixed(2)}%', style: TextStyle(fontSize:11, fontWeight: FontWeight.w700, color: m.changePct>=0? OrbitTheme.success : OrbitTheme.negative)) ])),
                        ]),
                        const SizedBox(height:6),
                        Text(m.price >= 1000 ? m.price.toStringAsFixed(0) : m.price.toStringAsFixed(2), style: GoogleFonts.instrumentSans(fontSize:22, fontWeight: FontWeight.w700, color: OrbitTheme.text, letterSpacing:-0.3).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                        const SizedBox(height:10),
                        // sparkline — thin line 2px, no fill, 3 faint grids
                        SizedBox(height:32, child: CustomPaint(painter: _SparkPainter(values: m.spark, up: m.changePct>=0), size: const Size(double.infinity, 32))),
                        const SizedBox(height:6),
                        Text('${m.symbol} - Yahoo/Coingecko - Live 60s', style: const TextStyle(fontSize:10, color: OrbitTheme.muted)),
                      ]),
                    ),
                  ).animate().fadeIn(duration:260.ms).slideY(begin:0.04,end:0),
                ),
                const SizedBox(height:8),
                Text('Live markets • Pull to refresh • ${loc.city} • No dummy — real Yahoo & CoinGecko free 0', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize:10), textAlign: TextAlign.center),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values; final bool up;
  _SparkPainter({required this.values, required this.up});
  @override void paint(Canvas c, Size s){
    if(values.length<2) return;
    final minV = values.reduce((a,b)=> a<b?a:b);
    final maxV = values.reduce((a,b)=> a>b?a:b);
    final range = (maxV-minV).abs() < 1 ? 1.0 : (maxV-minV);
    final p = Paint()..color = (up? const Color(0xFF2E7D32) : const Color(0xFFB42318)).withOpacity(0.85)..strokeWidth=2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    final grid = Paint()..color= const Color(0xFFEAEAEA)..strokeWidth=0.7;
    for(int i=1;i<3;i++){ final y=s.height*i/3; c.drawLine(Offset(0,y), Offset(s.width,y), grid); }
    final path = Path();
    for(int i=0;i<values.length;i++){
      final x = s.width * i / (values.length-1);
      final y = s.height - ((values[i]-minV)/range * (s.height-8) + 4);
      if(i==0) path.moveTo(x,y); else path.lineTo(x,y);
    }
    c.drawPath(path, p);
  }
  @override bool shouldRepaint(covariant CustomPainter o)=> false;
}
