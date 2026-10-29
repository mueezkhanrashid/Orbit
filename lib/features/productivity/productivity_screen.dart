import 'package:flutter/material.dart';
// FUTURISTIC v4 — haptic + hover glow + 60fps staggered
import '../../theme/app_theme.dart';
import '../../core/performance/orbit_performance.dart';
import '../../widgets/orbit_card.dart';
import '../../core/storage/hive_boxes.dart';
import 'dart:async';

// PRODUCTIVITY — Helps user daily: Tasks + Focus (Pomodoro) + Habits + Mini-Calendar
// All offline, Hive, no server, private. Location-aware: "Study for Chevening — 30m focus — due in Lahore"

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});
  @override State<ProductivityScreen> createState()=> _ProductivityScreenState();
}
class _ProductivityScreenState extends State<ProductivityScreen> with SingleTickerProviderStateMixin{
  late TabController _tab;
  final _taskCtrl=TextEditingController();
  List<Map<String,dynamic>> _tasks=[];
  // Focus
  int _focusSec=25*60; bool _focusRunning=false; Timer? _timer;
  // Habits
  final _habits=[
    {'name':'Fajr on time','done':true, 'streak':7},
    {'name':'Apply 1 job','done':false, 'streak':3},
    {'name':'Read Quran 1 page','done':true, 'streak':12},
    {'name':'Code 1 hour','done':false, 'streak':5},
  ];

  @override void initState(){
    super.initState();
    _tab=TabController(length:4, vsync:this);
    _tasks = List<Map<String,dynamic>>.from(OrbitBoxes.box(OrbitBoxes.notebook).get('orbit_tasks', defaultValue: []) as List? ?? []);
    if(_tasks.isEmpty){
      _tasks=[
        {'title':'Finish Chevening essays','done':false,'priority':'High','due':'Today'},
        {'title':'Apply 3 jobs near you','done':false,'priority':'Medium','due':'Tomorrow'},
        {'title':'Revise DAAD proposal','done':true,'priority':'High','due':'Yesterday'},
      ];
    }
  }
  @override void dispose(){
    _tab.dispose();
    _timer?.cancel();
    _taskCtrl.dispose();
    super.dispose();
  }
  void _saveTasks(){ OrbitBoxes.box(OrbitBoxes.notebook).put('orbit_tasks', _tasks); setState((){}); }
  void _toggleFocus(){
    if(_focusRunning){ _timer?.cancel(); setState(()=> _focusRunning=false); return; }
    setState(()=> _focusRunning=true);
    _timer=Timer.periodic(const Duration(seconds:1), (t){
      if(!mounted) return;
      if(_focusSec<=1){ t.cancel(); setState((){_focusRunning=false; _focusSec=25*60;}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Focus done — great work! 🎉'))); return; }
      setState(()=> _focusSec--);
    });
  }
  String _fmt(int s)=> '${(s~/60).toString().padLeft(2,'0')}:${(s%60).toString().padLeft(2,'0')}';

  @override Widget build(BuildContext context){
    return Column(children:[
      Container(color:OrbitTheme.surface, child: TabBar(controller:_tab, indicatorColor:OrbitTheme.primary, labelColor:OrbitTheme.primary, unselectedLabelColor:OrbitTheme.muted, indicatorWeight:2, labelStyle: const TextStyle(fontSize:11,fontWeight:FontWeight.w700), isScrollable:true, tabs: const [Tab(text:'Tasks'),Tab(text:'Focus 25m'),Tab(text:'Habits'),Tab(text:'Calendar')])),
      Expanded(child: TabBarView(controller:_tab, children:[
        _tasksTab(),
        _focusTab(),
        _habitsTab(),
        _calendarTab(),
      ])),
    ]);
  }

  Widget _tasksTab()=> ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, padding: const EdgeInsets.only(bottom:24), children:[
    Padding(padding: const EdgeInsets.fromLTRB(12,12,12,8), child: Row(children:[
      Expanded(child: TextField(controller:_taskCtrl, decoration: InputDecoration(hintText:'Add task — e.g., Apply Turkiye Burslari…', hintStyle: Theme.of(context).textTheme.bodySmall, filled:true, fillColor:OrbitTheme.bg, contentPadding: const EdgeInsets.symmetric(horizontal:12,vertical:8), border: OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide: const BorderSide(color:OrbitTheme.outline)), prefixIcon: const Icon(Icons.add_task, size:16, color:OrbitTheme.muted)))),
      const SizedBox(width:8),
      FilledButton(onPressed: (){ if(_taskCtrl.text.trim().isEmpty) return; _tasks.insert(0, {'title':_taskCtrl.text.trim(),'done':false,'priority':'Medium','due':'Today'}); _taskCtrl.clear(); _saveTasks();}, style: FilledButton.styleFrom(backgroundColor:OrbitTheme.ink), child: const Text('Add')),
    ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Row(children:[
      _chip('${_tasks.where((t)=> !(t['done'] as bool)).length} to do', OrbitTheme.primarySoft, OrbitTheme.primary),
      const SizedBox(width:6),
      _chip('${_tasks.where((t)=> t['done'] as bool).length} done', OrbitTheme.successSoft, OrbitTheme.success),
      const Spacer(),
      TextButton(onPressed: (){ _tasks.removeWhere((t)=> t['done']==true); _saveTasks();}, child: const Text('Clear done', style:TextStyle(fontSize:11))),
    ])),
    for(int i=0;i<_tasks.length;i++) OrbitCard(child: Row(children:[
      Checkbox(value:_tasks[i]['done'] as bool, onChanged:(v){ _tasks[i]['done']=v; _saveTasks();}, activeColor: OrbitTheme.primary, visualDensity: VisualDensity.compact),
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(_tasks[i]['title'], style: TextStyle(fontSize:12.5, fontWeight:FontWeight.w600, decoration: _tasks[i]['done'] as bool ? TextDecoration.lineThrough : null, color: _tasks[i]['done'] as bool ? OrbitTheme.muted : OrbitTheme.ink)),
        Row(children:[
          Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color: _tasks[i]['priority']=='High'? const Color(0xFFFFEBEE):OrbitTheme.bg, borderRadius:BorderRadius.circular(999), border:Border.all(color: _tasks[i]['priority']=='High'? const Color(0xFFFFCDD2):OrbitTheme.outline)), child: Text(_tasks[i]['priority'], style: TextStyle(fontSize:10,fontWeight:FontWeight.w600, color: _tasks[i]['priority']=='High'? const Color(0xFFC62828):OrbitTheme.muted))),
          const SizedBox(width:6),
          Text(_tasks[i]['due'], style: const TextStyle(fontSize:10,color:OrbitTheme.muted)),
        ]),
      ])),
      IconButton(icon: const Icon(Icons.delete_outline, size:16, color:OrbitTheme.muted2), onPressed: (){ _tasks.removeAt(i); _saveTasks();}),
    ])),
    const SizedBox(height: 8),
  ]);

  Widget _focusTab()=> ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, padding: const EdgeInsets.fromLTRB(12,16,12,24), children:[
    Container(padding: const EdgeInsets.all(16), decoration:BoxDecoration(color:OrbitTheme.ink, borderRadius:BorderRadius.circular(16)), child: Column(children:[
      const Text('Focus Timer', style:TextStyle(color:Colors.white, fontSize:13, fontWeight:FontWeight.w700, letterSpacing:0.3)),
      const SizedBox(height:4),
      const Text('Pomodoro • 25m deep work • No distractions', style:TextStyle(color:Colors.white70, fontSize:11)),
      const SizedBox(height:16),
      Container(width:140,height:140, decoration:BoxDecoration(shape:BoxShape.circle, border:Border.all(color:Colors.white24, width:4)), child: Center(child: Text(_fmt(_focusSec), style: const TextStyle(color:Colors.white, fontSize:36, fontWeight:FontWeight.w700, letterSpacing:1)))),
      const SizedBox(height:16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children:[
        FilledButton.icon(onPressed: _toggleFocus, icon: Icon(_focusRunning? Icons.pause: Icons.play_arrow, size:16), label: Text(_focusRunning? 'Pause':'Start focus'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: OrbitTheme.ink, padding: const EdgeInsets.symmetric(horizontal:18,vertical:10))),
        const SizedBox(width:8),
        OutlinedButton(onPressed: (){ _timer?.cancel(); setState((){_focusSec=25*60; _focusRunning=false;});}, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color:Colors.white24)), child: const Text('Reset')),
      ]),
      const SizedBox(height:12),
      Wrap(spacing:6, children:[
        for(final m in [15,25,45]) ChoiceChip(label: Text('${m}m', style: TextStyle(fontSize:11, color: _focusSec==m*60? OrbitTheme.ink: Colors.white)), selected: _focusSec==m*60 && !_focusRunning, onSelected:(_){ _timer?.cancel(); setState((){_focusSec=m*60; _focusRunning=false;});}, selectedColor: Colors.white, backgroundColor: Colors.white12, showCheckmark:false),
      ]),
    ])),
    const SizedBox(height:12),
    OrbitCard(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Why this helps', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:6),
      _bullet('25m focus  5m break  repeat 4x — proven for jobs/scholarships prep'),
      _bullet('Pairs with Tasks: pick top task, start focus, complete it'),
      _bullet('Just you + time'),
    ])),
  ]);

  Widget _habitsTab()=> ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, padding: const EdgeInsets.only(bottom:24), children:[
    Padding(padding: const EdgeInsets.fromLTRB(12,12,12,6), child: Row(children:[Text('Today', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration:BoxDecoration(color:OrbitTheme.successSoft, borderRadius:BorderRadius.circular(999)), child: Text('${_habits.where((h)=> h['done']==true).length}/${_habits.length} done', style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:OrbitTheme.success)))])),
    for(final h in _habits) OrbitCard(child: Row(children:[
      Checkbox(value:h['done'] as bool, onChanged:(v){ setState(()=> h['done']=(v ?? false));}, activeColor: OrbitTheme.success, visualDensity: VisualDensity.compact),
      Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(h['name'] as String, style: const TextStyle(fontSize:12.5,fontWeight:FontWeight.w600)), Text('${h['streak']} day streak', style: const TextStyle(fontSize:11,color:OrbitTheme.muted))])),
      Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration:BoxDecoration(color: h['done'] as bool ? OrbitTheme.successSoft:OrbitTheme.bg, border:Border.all(color: h['done'] as bool ? const Color(0xFFA5D6A7):OrbitTheme.outline), borderRadius:BorderRadius.circular(999)), child: Row(mainAxisSize:MainAxisSize.min, children:[Icon(h['done'] as bool ? Icons.local_fire_department: Icons.circle_outlined, size:12, color: h['done'] as bool ? OrbitTheme.success:OrbitTheme.muted2), const SizedBox(width:4), Text('${h['streak']}', style: TextStyle(fontSize:11,fontWeight:FontWeight.w700, color: h['done'] as bool ? OrbitTheme.success:OrbitTheme.muted))])),
    ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: FilledButton.icon(onPressed: (){}, icon: const Icon(Icons.add, size:14), label: const Text('Add habit'), style: FilledButton.styleFrom(backgroundColor:OrbitTheme.success))),
  ]);

  Widget _calendarTab()=> ListView(cacheExtent: OrbitPerformance.cacheExtent, addRepaintBoundaries: true, padding: const EdgeInsets.only(bottom:24), children:[
    OrbitCard(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children:[Text('October 2026', style: Theme.of(context).textTheme.titleMedium), const Spacer(), IconButton(icon: const Icon(Icons.chevron_left, size:16), onPressed: (){}), IconButton(icon: const Icon(Icons.chevron_right, size:16), onPressed: (){})]),
      const SizedBox(height:8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i)=> Text(['M','T','W','T','F','S','S'][i], style: const TextStyle(fontSize:11, fontWeight:FontWeight.w600, color:OrbitTheme.muted)))),
      const SizedBox(height:8),
      for(int row=0;row<5;row++) Row(children: List.generate(7, (c){
        final day = row*7 + c - 5;
        final isToday = day==25;
        final hasTask = [25,26,28,30].contains(day);
        if(day<1 || day>31) return const Expanded(child: SizedBox(height:32));
        return Expanded(child: Container(height:32, margin: const EdgeInsets.all(2), decoration:BoxDecoration(color: isToday? OrbitTheme.primary: hasTask? OrbitTheme.primarySoft:Colors.transparent, borderRadius:BorderRadius.circular(8), border: Border.all(color: isToday? OrbitTheme.primary: hasTask? OrbitTheme.primary.withOpacity(0.2):Colors.transparent)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[Text('$day', style: TextStyle(fontSize:11, fontWeight: isToday?FontWeight.w700:FontWeight.w500, color: isToday?Colors.white:OrbitTheme.ink)), if(hasTask && !isToday) Container(width:4,height:4, margin: const EdgeInsets.only(top:2), decoration:const BoxDecoration(color:OrbitTheme.primary, shape:BoxShape.circle))] ))));
      })),
    ])),
    OrbitCard(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height:8),
      _calRow('Today', 'Chevening essay due', 'High', OrbitTheme.warning),
      _calRow('Tomorrow', 'DAAD interview — Berlin 3pm', 'Medium', OrbitTheme.primary),
      _calRow('Oct 28', 'Turkiye Burslari opens', 'Low', OrbitTheme.success),
    ])),
  ]);

  Widget _calRow(String when, String what, String pri, Color c)=> Padding(padding: const EdgeInsets.only(bottom:8), child: Row(children:[
    Container(width:3,height:28, decoration:BoxDecoration(color:c, borderRadius:BorderRadius.circular(999))),
    const SizedBox(width:10),
    Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(when, style: const TextStyle(fontSize:10,fontWeight:FontWeight.w600,color:OrbitTheme.muted)), Text(what, style: const TextStyle(fontSize:12.5,fontWeight:FontWeight.w600))])),
    Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color:c.withOpacity(0.08), borderRadius:BorderRadius.circular(999)), child: Text(pri, style: TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:c))),
  ]));

  Widget _chip(String t, Color bg, Color fg)=> Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration:BoxDecoration(color:bg, borderRadius:BorderRadius.circular(999), border:Border.all(color:fg.withOpacity(0.16))), child: Text(t, style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:fg)));
  Widget _bullet(String t)=> Padding(padding: const EdgeInsets.only(bottom:4), child: Row(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('•  ', style:TextStyle(color:OrbitTheme.muted)), Expanded(child: Text(t, style: const TextStyle(fontSize:12,height:1.35,color:OrbitTheme.muted)))]));
}
