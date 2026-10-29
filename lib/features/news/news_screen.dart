import 'package:flutter/material.dart';
import '../../core/test_flag.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../theme/advanced_animations.dart';
import '../../widgets/orbit_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/news_service.dart';
import '../../app/providers.dart';
import '../../core/location/location_service.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});
  @override ConsumerState<NewsScreen> createState()=> _NewsScreenState();
}
class _NewsScreenState extends ConsumerState<NewsScreen> with SingleTickerProviderStateMixin{
  late TabController _tab;
  final _svc=NewsService();
  final chips=const ['All','Pakistan','World','Business','Tech','Sports'];
  int chip=0;
  int _page=1; final _perPage=20;
  final _articles=<NewsArticle>[]; bool _hasMore=true, _loading=false; String _scope='Auto';

  @override void initState(){ super.initState(); _tab=TabController(length:2, vsync:this); _load(reset:true); }
  @override void dispose(){ _tab.dispose(); super.dispose(); }

  Future<void> _load({bool reset=false}) async {
    if (orbitIsTest) { try{ if(mounted) setState(()=> _loading=false); } catch(_){} return; }
    try{ if(WidgetsBinding.instance.runtimeType.toString().contains('Test')) return; } catch(_){}
    if(_loading) return;
    setState(()=> _loading=true);
    if(reset){ _page=1; _articles.clear(); _hasMore=true; }
    final cat = chips[chip];
    final trending = _tab.index==1;
    final loc = await ref.read(locationProvider.future).catchError((_)=> OrbitLocation.rawalpindi());
    final res = await _svc.fetch(page:_page, perPage:_perPage, category: cat=='All'?'All':cat, scope: _scope, trending: trending, location: loc);
    if(!mounted) return;
    setState((){_articles.addAll(res.articles); _hasMore=res.hasMore; _page++; _loading=false;});
  }

  @override Widget build(BuildContext context){
    final loc = ref.watch(locationProvider).valueOrNull;
    final scopeLabel = _scope=='Auto' ? (loc?.countryCode=='PK' ? 'Auto Pakistan' : loc==null? 'Auto' : 'Auto World') : _scope;
    return Column(children:[
      Container(color:OrbitTheme.surface, child: Column(children:[
        TabBar(controller:_tab, onTap:(_)=> _load(reset:true), indicatorColor:OrbitTheme.primary, labelColor:OrbitTheme.primary, unselectedLabelColor:OrbitTheme.muted, indicatorWeight:2, tabs: const [Tab(text:'For you • 100+ daily'), Tab(text:'Trending')]),
        SizedBox(height:44, child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
          scrollDirection: Axis.horizontal,
          itemBuilder:(_,i)=> ChoiceChip(label: Text(chips[i], style: TextStyle(fontSize:12, fontWeight: chip==i?FontWeight.w700:FontWeight.w500, color: chip==i?OrbitTheme.text:OrbitTheme.muted)), selected: chip==i, onSelected:(_){ HapticFeedback.selectionClick(); setState(()=> chip=i); _load(reset:true);}, selectedColor: const Color(0xFFEEEEEE), backgroundColor:OrbitTheme.bg, side: const BorderSide(color: OrbitTheme.border), shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(999)), showCheckmark:false, visualDensity:VisualDensity.compact),
          separatorBuilder:(_,__)=> const SizedBox(width:6), itemCount: chips.length,
        )),
        Padding(padding: const EdgeInsets.fromLTRB(12,0,12,8), child: Row(children:[
          const Text('Scope:', style:TextStyle(fontSize:11,color:OrbitTheme.muted)), const SizedBox(width:6),
          ChoiceChip(label: Text('Auto', style: TextStyle(fontSize:11, fontWeight: _scope=='Auto'?FontWeight.w700:FontWeight.w500, color: _scope=='Auto'?OrbitTheme.text:OrbitTheme.muted)), selected:_scope=='Auto', onSelected:(_){ HapticFeedback.selectionClick(); setState(()=> _scope='Auto'); _load(reset:true);}, selectedColor: const Color(0xFFEEEEEE), showCheckmark:false, visualDensity:VisualDensity.compact, backgroundColor:OrbitTheme.bg, side: const BorderSide(color: OrbitTheme.border)),
          const SizedBox(width:6),
          ChoiceChip(label: Text('Pakistan', style: TextStyle(fontSize:11, color: _scope=='Pakistan'?OrbitTheme.text:OrbitTheme.muted)), selected:_scope=='Pakistan', onSelected:(_){ HapticFeedback.selectionClick(); setState(()=> _scope='Pakistan'); _load(reset:true);}, selectedColor: const Color(0xFFEEEEEE), showCheckmark:false, visualDensity:VisualDensity.compact, backgroundColor:OrbitTheme.bg, side: const BorderSide(color: OrbitTheme.border)),
          const SizedBox(width:6),
          ChoiceChip(label: Text('World', style: TextStyle(fontSize:11, color: _scope=='World'?OrbitTheme.text:OrbitTheme.muted)), selected:_scope=='World', onSelected:(_){ HapticFeedback.selectionClick(); setState(()=> _scope=='World'); _load(reset:true);}, selectedColor: const Color(0xFFEEEEEE), showCheckmark:false, visualDensity:VisualDensity.compact, backgroundColor:OrbitTheme.bg, side: const BorderSide(color: OrbitTheme.border)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:3), decoration:BoxDecoration(color:OrbitTheme.successSoft, borderRadius:BorderRadius.circular(999)), child: Row(mainAxisSize:MainAxisSize.min, children:[const Icon(Icons.location_on, size:10, color:OrbitTheme.success), const SizedBox(width:3), Text(loc?.city ?? '…', style: const TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:OrbitTheme.success))])),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(12,0,12,6), child: Text('$scopeLabel • ${loc?.country ?? 'Pakistan'} • tap Auto to follow GPS', style: const TextStyle(fontSize:10, color:OrbitTheme.muted))),
      ])),
      Expanded(child: _articles.isEmpty && _loading ? ListView.builder(
          cacheExtent: OrbitPerformance.cacheExtent,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,padding: const EdgeInsets.only(bottom:24), itemCount:6, itemBuilder:(_,__)=> const OrbitCard(child: SizedBox(height:72, child: Center(child: CircularProgressIndicator(strokeWidth:2))))) : NotificationListener<ScrollNotification>(
        onNotification:(n){ if(n.metrics.pixels > n.metrics.maxScrollExtent - 400 && !_loading && _hasMore) _load(); return false; },
        child: ListView.builder(
          cacheExtent: OrbitPerformance.cacheExtent,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          padding: const EdgeInsets.only(bottom:24),
          itemCount: _articles.length + (_hasMore?1:0),
          itemBuilder:(c,i){
            if(i==_articles.length) return Padding(padding: const EdgeInsets.all(16), child: Center(child: _loading? const CircularProgressIndicator(strokeWidth:2) : TextButton(onPressed: _load, child: const Text('Load more 20'))));
            final a=_articles[i];
            final isLocal = loc!=null && (a.source=='Dawn'||a.source=='Geo') && loc.countryCode=='PK';
            return OrbitFuturisticCard(onTap: (){ HapticFeedback.lightImpact(); }, child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Row(children:[
                  Container(width:20,height:20, decoration:BoxDecoration(color: a.source=='Dawn'?OrbitTheme.primary:OrbitTheme.teal, borderRadius:BorderRadius.circular(6))),
                  const SizedBox(width:6),
                  Text(a.source, style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700)),
                  const SizedBox(width:6),
                  Text('• ${a.timeAgo}', style: const TextStyle(fontSize:11,color:OrbitTheme.muted)),
                  if(a.trending) ...[const SizedBox(width:6), Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color: OrbitTheme.surface, borderRadius:BorderRadius.circular(999)), child: const Text('TRENDING', style:TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:OrbitTheme.primary)))],
                  if(isLocal) ...[const SizedBox(width:6), Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color:OrbitTheme.successSoft, borderRadius:BorderRadius.circular(999)), child: Row(mainAxisSize:MainAxisSize.min, children:[const Icon(Icons.location_on, size:9, color:OrbitTheme.success), const SizedBox(width:2), Text(loc.city, style: const TextStyle(fontSize:11,fontWeight:FontWeight.w500,color:OrbitTheme.success))]))],
                ]),
                const SizedBox(height:6),
                Text(a.title, style: const TextStyle(fontSize:13,fontWeight:FontWeight.w600,height:1.25)),
                const SizedBox(height:4),
                Text('${a.category} • ${_scope=='Auto' ? (loc?.countryCode=='PK'?'Pakistan':'World') : _scope} • ${loc?.city ?? 'your location'}', style: const TextStyle(fontSize:11,color:OrbitTheme.muted)),
              ])),
              const SizedBox(width:12),
              ClipRRect(borderRadius:BorderRadius.circular(10), child: Container(width:72,height:72,color:OrbitTheme.bg, child: Icon([Icons.public, Icons.trending_up, Icons.phone_iphone, Icons.water_drop][i%4], color:OrbitTheme.muted2))),
            ]))).animate(delay: (i%3*50).ms).fadeIn(duration:260.ms).slideY(begin:0.04,end:0);
          },
        ),
      )),
    ]);
  }
}
