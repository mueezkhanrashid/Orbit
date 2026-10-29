import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../core/location/location_service.dart';
import '../app/providers.dart';

// Location header — shows "Lahore • Pakistan • Live" or "Rawalpindi • Tap to enable location"
// Handles permission, manual picker, and real-time dot.

class LocationHeader extends ConsumerWidget {
  const LocationHeader({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final locAsync = ref.watch(locationProvider);
    return locAsync.when(
      loading: ()=> _chip(context, 'Locating…', Icons.my_location, OrbitTheme.muted, onTap: ()=> _showPicker(context, ref)),
      error: (_,__)=> _chip(context, 'Rawalpindi • Tap to enable location', Icons.location_off, OrbitTheme.warning, onTap: ()=> _showPicker(context, ref)),
      data: (loc)=> _chip(context, '${loc.city} • ${loc.country} • Live', Icons.location_on, OrbitTheme.success, dot: true, onTap: ()=> _showPicker(context, ref)),
    );
  }
  Widget _chip(BuildContext context, String label, IconData icon, Color c, {bool dot=false, VoidCallback? onTap})=> InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration: BoxDecoration(color: c.withOpacity(0.08), border: Border.all(color: c.withOpacity(0.20)), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children:[
    Icon(icon, size:12, color:c),
    const SizedBox(width:6),
    Text(label, style: TextStyle(fontSize:11, fontWeight:FontWeight.w600, color:c)),
    if(dot) ...[const SizedBox(width:6), Container(width:6,height:6, decoration:BoxDecoration(color:c, shape:BoxShape.circle))],
    const SizedBox(width:4),
    Icon(Icons.expand_more, size:12, color:c),
  ])));
  void _showPicker(BuildContext context, WidgetRef ref){
    showModalBottomSheet(context: context, isScrollControlled:true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_)=> const _LocationPickerSheet());
  }
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();
  @override ConsumerState<_LocationPickerSheet> createState()=> _LocationPickerSheetState();
}
class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet>{
  final _q=TextEditingController();
  List<OrbitLocation> _results=[];
  bool _searching=false;
  @override Widget build(BuildContext context){
    final locAsync = ref.watch(locationProvider);
    return SafeArea(child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children:[
        Container(width:36,height:4, margin: const EdgeInsets.only(top:8), decoration: BoxDecoration(color:OrbitTheme.outline, borderRadius:BorderRadius.circular(999))),
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8), child: Row(children:[
          const Icon(Icons.location_on, color:OrbitTheme.primary, size:18),
          const SizedBox(width:8),
          const Text('Location', style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
          const Spacer(),
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Done')),
        ])),
        locAsync.when(
          loading: ()=> const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth:2)),
          error: (_,__)=> Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: FilledButton.icon(onPressed: () async { await ref.read(locationServiceProvider).current(); ref.invalidate(locationProvider); }, icon: const Icon(Icons.my_location, size:16), label: const Text('Enable location'), style: FilledButton.styleFrom(backgroundColor:OrbitTheme.primary))),
          data: (loc)=> Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: Container(padding: const EdgeInsets.all(12), decoration:BoxDecoration(color: OrbitTheme.surface, borderRadius:BorderRadius.circular(12), border: Border.all(color: OrbitTheme.border)), child: Row(children:[
            Container(width:36,height:36, decoration:BoxDecoration(color:OrbitTheme.primary, borderRadius:BorderRadius.circular(10)), child: const Icon(Icons.my_location, color:Colors.white, size:18)),
            const SizedBox(width:10),
            Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(loc.city, style: const TextStyle(fontSize:13,fontWeight:FontWeight.w700)),
              Text('${loc.country} • ${loc.lat.toStringAsFixed(2)}, ${loc.lng.toStringAsFixed(2)}', style: const TextStyle(fontSize:11,color:OrbitTheme.muted)),
              Text(ref.read(locationServiceProvider).isManual ? 'Manual — tap Use my location to switch back' : 'Auto • Updates when you move 25m', style: const TextStyle(fontSize:10,color:OrbitTheme.muted)),
            ])),
            const Icon(Icons.check_circle, color:OrbitTheme.success, size:18),
          ]))),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16,12,16,6), child: TextField(controller:_q, onChanged: _search, decoration: InputDecoration(hintText:'Search city — London, Dubai, Lahore…', hintStyle: const TextStyle(fontSize:12, color:OrbitTheme.muted), prefixIcon: const Icon(Icons.search, size:16, color:OrbitTheme.muted), suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width:14,height:14, child: CircularProgressIndicator(strokeWidth:2))) : null, filled:true, fillColor:OrbitTheme.bg, contentPadding: const EdgeInsets.symmetric(horizontal:10, vertical:8), border: OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide: const BorderSide(color:OrbitTheme.outline))))),
        if(_results.isNotEmpty) ...[
          const Divider(height:1),
          ConstrainedBox(constraints: const BoxConstraints(maxHeight:220), child: ListView.separated(
            shrinkWrap:true, padding: const EdgeInsets.symmetric(vertical:6),
            itemCount: _results.length, separatorBuilder:(_,__)=> const Divider(height:1, indent:16),
            itemBuilder:(_,i){
              final r=_results[i];
              return ListTile(dense:true, leading: Container(width:32,height:32, decoration:BoxDecoration(color:OrbitTheme.bg, borderRadius:BorderRadius.circular(8), border:Border.all(color:OrbitTheme.outline)), child: const Icon(Icons.location_city, size:16, color:OrbitTheme.ink)), title: Text(r.city, style: const TextStyle(fontSize:13,fontWeight:FontWeight.w600)), subtitle: Text('${r.country} • ${r.countryCode} • ${r.lat.toStringAsFixed(2)}, ${r.lng.toStringAsFixed(2)}', style: const TextStyle(fontSize:11,color:OrbitTheme.muted)), trailing: const Icon(Icons.chevron_right, size:16, color:OrbitTheme.muted2), onTap: () async {
                await ref.read(locationServiceProvider).setManual(r.city, r.lat, r.lng, r.country, r.countryCode);
                ref.invalidate(locationProvider);
                ref.invalidate(weatherProvider);
                ref.invalidate(namazProvider);
                if(context.mounted) Navigator.pop(context);
                if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location set to ${r.city} • ${r.country}'))); 
              });
            },
          )),
        ],
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,12), child: Row(children:[
          Expanded(child: OutlinedButton.icon(onPressed: () async { await ref.read(locationServiceProvider).current(); ref.invalidate(locationProvider); ref.invalidate(weatherProvider); ref.invalidate(namazProvider); if(context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.my_location, size:16), label: const Text('Use my location', style:TextStyle(fontSize:12)))),
          const SizedBox(width:8),
          Expanded(child: OutlinedButton(onPressed: () async { await ref.read(locationServiceProvider).setManual('Rawalpindi', 33.5651, 73.0169, 'Pakistan', 'PK'); ref.invalidate(locationProvider); ref.invalidate(weatherProvider); ref.invalidate(namazProvider); if(context.mounted) Navigator.pop(context); }, child: const Text('Reset to Rawalpindi', style:TextStyle(fontSize:12)))),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16,0,16,16), child: Text('Location powers Weather, Namaz, Qibla, Jobs near you, and News scope.', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize:10))),
      ]),
    ));
  }
  @override void dispose() { _q.dispose(); super.dispose(); }
  Future<void> _search(String q) async {
    if(q.trim().length < 2){ setState(()=> _results=[]); return; }
    setState(()=> _searching=true);
    final res = await ref.read(locationServiceProvider).searchCity(q);
    if(!mounted) return;
    setState((){_results=res; _searching=false;});
  }
}
