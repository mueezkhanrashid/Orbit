import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../widgets/orbit_card.dart';
import '../../widgets/location_header.dart';
import '../../app/providers.dart';
import '../widget/widget_config_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override ConsumerState<SettingsScreen> createState()=> _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen>{
  bool urdu=false;
  @override Widget build(BuildContext context){
    final locAsync = ref.watch(locationProvider);
    final isDark = ref.watch(themeModeProvider)==ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontSize:16, fontWeight:FontWeight.w700))),
      body: ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, padding: const EdgeInsets.only(bottom:24), children:[
        OrbitCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[const Icon(Icons.location_on, size:16, color:OrbitTheme.primary), const SizedBox(width:6), Text('Location', style: Theme.of(context).textTheme.titleMedium)]),
          const SizedBox(height:6),
          Text('Weather, Namaz, Qibla and jobs near you follow your location.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height:10),
          locAsync.when(
            loading: ()=> const SizedBox(height:40, child: Center(child: CircularProgressIndicator(strokeWidth:2))),
            error: (_,__)=> Container(padding: const EdgeInsets.all(10), decoration:BoxDecoration(color: const Color(0xFFFFF3E0), border:Border.all(color:const Color(0xFFFFE0B2)), borderRadius:BorderRadius.circular(12)), child: Row(children:[const Icon(Icons.location_off, size:16, color:Color(0xFFEF6C00)), const SizedBox(width:8), const Expanded(child: Text('Location off — using Rawalpindi', style:TextStyle(fontSize:11,color:OrbitTheme.muted))), TextButton(onPressed: ()=> _openLocation(), child: const Text('Enable'))])),
            data: (loc)=> Container(padding: const EdgeInsets.all(10), decoration:BoxDecoration(color: OrbitTheme.surface, border:Border.all(color:OrbitTheme.primary.withOpacity(0.14)), borderRadius:BorderRadius.circular(12)), child: Row(children:[
              Container(width:32,height:32, decoration:BoxDecoration(color:OrbitTheme.primary, borderRadius:BorderRadius.circular(9)), child: const Icon(Icons.my_location, size:16, color:Colors.white)),
              const SizedBox(width:10),
              Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(loc.label, style: const TextStyle(fontSize:12, fontWeight:FontWeight.w700)), Text('${loc.lat.toStringAsFixed(3)}, ${loc.lng.toStringAsFixed(3)}', style: const TextStyle(fontSize:11,color:OrbitTheme.muted))])),
              const Icon(Icons.check_circle, color:OrbitTheme.success, size:16),
            ])),
          ),
          const SizedBox(height:8),
          SizedBox(width:double.infinity, child: OutlinedButton.icon(onPressed: _openLocation, icon: const Icon(Icons.edit_location, size:16), label: const Text('Change location'))),
        ])),
        // Widget 4x2
        OrbitCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[Container(width:28,height:28, decoration:BoxDecoration(color:OrbitTheme.ink, borderRadius:BorderRadius.circular(7)), child: const Icon(Icons.widgets_rounded, size:14, color:Colors.white)), const SizedBox(width:6), Text('Home widget', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration:BoxDecoration(color:OrbitTheme.successSoft, borderRadius:BorderRadius.circular(999)), child: const Text('NEW', style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:OrbitTheme.success)))]),
          const SizedBox(height:6),
          const Text('Pin Namaz, Space, News, Jobs, Weather and Markets to your home screen.', style:TextStyle(fontSize:11,color:OrbitTheme.muted)),
          const SizedBox(height:8),
          SizedBox(width:double.infinity, child: OutlinedButton.icon(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const WidgetConfigScreen())), icon: const Icon(Icons.widgets_outlined, size:14), label: const Text('Configure widget', style:TextStyle(fontSize:12)))),
        ])),
        // Appearance
        OrbitCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Row(children:[const Icon(Icons.palette, size:14, color:Color(0xFF7C4DFF)), const SizedBox(width:6), Text('Appearance', style: Theme.of(context).textTheme.titleMedium)]),
          const SizedBox(height:6),
          SwitchListTile(value: isDark, onChanged:(v){ ref.read(themeModeProvider.notifier).state = v? ThemeMode.dark:ThemeMode.light; }, title: const Text('Dark mode', style:TextStyle(fontSize:13,fontWeight:FontWeight.w600)), subtitle: const Text('Dark theme for night use', style:TextStyle(fontSize:11,color:OrbitTheme.muted)), activeColor: const Color(0xFF7C4DFF), secondary: Container(width:28,height:28, decoration:BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius:BorderRadius.circular(7)), child: const Icon(Icons.dark_mode, size:14, color:Colors.white))),
        ])),
        OrbitCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),
          SwitchListTile(value: urdu, onChanged:(v)=>setState(()=>urdu=v), title: const Text('اردو — Urdu', style:TextStyle(fontSize:13,fontWeight:FontWeight.w600)), subtitle: const Text('Urdu translations', style:TextStyle(fontSize:11,color:OrbitTheme.muted)), activeColor: OrbitTheme.primary),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Text('ORBIT 1.5.0 • Pakistan Super-App', style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize:10))),
      ]),
    );
  }
  void _openLocation()=> showModalBottomSheet(context: context, isScrollControlled:true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_)=> const LocationHeader());
}
