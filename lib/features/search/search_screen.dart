import 'package:flutter/material.dart';
// FUTURISTIC v4 — haptic + hover glow + 60fps staggered
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../widgets/orbit_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState()=> _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen>{
  final _q=TextEditingController();
  String _query='';
  @override void dispose(){ _q.dispose(); super.dispose(); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: Padding(
        padding: const EdgeInsets.only(right:12),
        child: TextField(
          controller: _q, autofocus: true, onChanged: (v)=> setState(()=> _query=v),
          decoration: InputDecoration(
            hintText: 'Search ORBIT — news, jobs, scholarships, Quran…',
            prefixIcon: const Icon(Icons.search, size:18, color:OrbitTheme.muted),
            suffixIcon: _query.isEmpty?null:IconButton(icon: const Icon(Icons.clear, size:18), onPressed: ()=> setState((){ _q.clear(); _query=''; })),
            filled: true, fillColor: OrbitTheme.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color:OrbitTheme.outline)),
          ),
        ),
      )),
      body: ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, padding: const EdgeInsets.only(bottom:24), children: [
        if(_query.isEmpty) ...[
          Padding(padding: const EdgeInsets.fromLTRB(12,12,12,6), child: Text('Trending searches', style: Theme.of(context).textTheme.titleMedium)),
          Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Wrap(spacing:6, runSpacing:6, children:[
            for(final t in ['PSX today','Erasmus Pakistan','Remote jobs','Quran 94:6','ISS live','Rain Rawalpindi']) ActionChip(label: Text(t, style: const TextStyle(fontSize:11)), onPressed: ()=> setState((){ _q.text=t; _query=t; }), backgroundColor: OrbitTheme.bg, side: const BorderSide(color:OrbitTheme.outline)),
          ])),
          OrbitCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Recent', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:8),
            for(final r in ['KSE 100','Fajr time','Scholarship deadline']) ListTile(dense:true, leading: const Icon(Icons.history, size:16, color:OrbitTheme.muted), title: Text(r, style: const TextStyle(fontSize:12)), trailing: const Icon(Icons.north_west, size:14, color:OrbitTheme.muted2), onTap: (){}),
          ])),
        ] else ...[
          Padding(padding: const EdgeInsets.fromLTRB(12,12,12,6), child: Text('Results for "$_query"', style: const TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:OrbitTheme.muted))),
          OrbitCard(child: Column(children:[
            _hit(Icons.newspaper, 'News', 'Pakistan unveils climate budget — Reuters'),
            _hit(Icons.work, 'Jobs', 'Backend Engineer — Systems Ltd • Lahore'),
            _hit(Icons.school, 'Scholarships', 'Erasmus Mundus — fully funded'),
            _hit(Icons.menu_book, 'Faith', 'Ayah 65:2 — And whoever fears Allah…'),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Text('Search across ORBIT', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize:10))),
        ],
      ]),
    );
  }
  Widget _hit(IconData i, String k, String t)=> ListTile(leading: Container(width:32,height:32, decoration: BoxDecoration(color:OrbitTheme.bg, borderRadius:BorderRadius.circular(8), border: Border.all(color:OrbitTheme.outline)), child: Icon(i,size:14,color:OrbitTheme.ink)), title: Text(k, style: const TextStyle(fontSize:10, fontWeight:FontWeight.w700, color:OrbitTheme.muted, letterSpacing:0.4)), subtitle: Text(t, style: const TextStyle(fontSize:12, fontWeight:FontWeight.w600)), trailing: const Icon(Icons.chevron_right,size:16,color:OrbitTheme.muted2), dense:true, onTap: (){});
}
