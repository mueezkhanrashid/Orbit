import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/orbit_card.dart';
import '../../core/storage/hive_boxes.dart';

// CRM BOARD — Kanban for leads (Applied  Interview  Offer) + follow-ups.
// User asked "user will get leads"  leads need pipeline, not just inbox.
// 

class CrmBoard extends StatefulWidget {
  const CrmBoard({super.key});
  @override State<CrmBoard> createState()=> _CrmBoardState();
}
class _CrmBoardState extends State<CrmBoard>{
  // Hive key: orbit_crm_v2 -> {applied:[], interview:[], offer:[]}
  late Map<String, List<Map<String,String>>> _board;
  @override void initState(){
    super.initState();
    final v = OrbitBoxes.box(OrbitBoxes.notebook).get('orbit_crm_v2');
    if(v is Map){
      _board = {
        'applied': List<Map<String,String>>.from((v['applied'] as List? ?? []).map((e)=> Map<String,String>.from(e))),
        'interview': List<Map<String,String>>.from((v['interview'] as List? ?? []).map((e)=> Map<String,String>.from(e))),
        'offer': List<Map<String,String>>.from((v['offer'] as List? ?? []).map((e)=> Map<String,String>.from(e))),
      };
    } else {
      _board = {
        'applied': [{'title':'Flutter Dev — Careem','org':'Careem','due':'Follow up in 3 days'}],
        'interview': [{'title':'Backend — Systems Ltd','org':'Systems Ltd','due':'Interview Tue 3pm'}],
        'offer': [],
      };
    }
  }
  void _save(){
    OrbitBoxes.box(OrbitBoxes.notebook).put('orbit_crm_v2', _board);
    setState((){});
  }
  void _move(String from, int idx, String to){
    final item = _board[from]!.removeAt(idx);
    _board[to]!.insert(0, item);
    _save();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved to $to  ${item['title']}')));
  }

  @override Widget build(BuildContext context){
    return ListView(padding: const EdgeInsets.only(bottom:24), children:[
      Padding(padding: const EdgeInsets.fromLTRB(12,12,12,6), child: Row(children:[
        Text('Leads CRM', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width:8),
        Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4), decoration:BoxDecoration(color: OrbitTheme.surface, borderRadius:BorderRadius.circular(999)), child: Text('${_board.values.fold(0, (a,b)=> a+b.length)} leads in pipeline', style: const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:OrbitTheme.primary))),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Text('Drag your leads through pipeline — Applied  Interview  Offer. Reminders.', style: Theme.of(context).textTheme.bodySmall)),
      const SizedBox(height:8),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(crossAxisAlignment:CrossAxisAlignment.start, children:[
        _col('Applied', _board['applied']!, OrbitTheme.primary, Icons.send, (i)=> _move('applied', i, 'interview')),
        _col('Interview', _board['interview']!, OrbitTheme.warning, Icons.groups, (i)=> _move('interview', i, 'offer')),
        _col('Offer', _board['offer']!, OrbitTheme.success, Icons.emoji_events, (i){}),
      ])),
      OrbitCard(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Row(children:[const Icon(Icons.notifications_active, size:14, color:OrbitTheme.warning), const SizedBox(width:6), Text('Follow-ups', style: Theme.of(context).textTheme.titleMedium)]),
        const SizedBox(height:6),
        _follow('Careem — Flutter Dev','Follow up email in 3 days', 'High', OrbitTheme.warning),
        _follow('Systems Ltd — Backend','Interview prep — Focus 25m x 2', 'Medium', OrbitTheme.primary),
        const SizedBox(height:8),
        SizedBox(width:double.infinity, child: OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.calendar_today, size:14), label: const Text('Add to Calendar'))),
      ])),
    ]);
  }
  Widget _col(String title, List<Map<String,String>> items, Color c, IconData icon, void Function(int) onNext){
    return Container(width:280, margin: const EdgeInsets.only(left:12), padding: const EdgeInsets.all(10), decoration:BoxDecoration(color: c.withOpacity(0.06), borderRadius:BorderRadius.circular(12), border:Border.all(color: c.withOpacity(0.18))), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(children:[Container(width:24,height:24, decoration:BoxDecoration(color:c, borderRadius:BorderRadius.circular(7)), child: Icon(icon, size:14, color:Colors.white)), const SizedBox(width:8), Text(title, style: const TextStyle(fontSize:12, fontWeight:FontWeight.w700)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(999)), child: Text('${items.length}', style: TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:c)))]),
      const SizedBox(height:8),
      if(items.isEmpty) Container(padding: const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(10), border:Border.all(color:OrbitTheme.outline)), child: const Text('No leads here — drag from left or save from Leads inbox', style:TextStyle(fontSize:11,color:OrbitTheme.muted))),
      for(int i=0;i<items.length;i++) Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.all(10), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(10), border:Border.all(color:OrbitTheme.outline)), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(items[i]['title']!, style: const TextStyle(fontSize:12,fontWeight:FontWeight.w600)),
        Text(items[i]['org']!, style: const TextStyle(fontSize:11,color:OrbitTheme.muted)),
        const SizedBox(height:4),
        Text(items[i]['due']!, style: TextStyle(fontSize:10,color:c, fontWeight:FontWeight.w600)),
        const SizedBox(height:6),
        Row(children:[
          Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('Notes', style:TextStyle(fontSize:11)))),
          const SizedBox(width:6),
          Expanded(child: FilledButton(onPressed: ()=> onNext(i), style: FilledButton.styleFrom(backgroundColor:c), child: Text(title=='Applied'? ' Interview' : title=='Interview'? ' Offer' : 'Done', style: const TextStyle(fontSize:11)))),
        ]),
      ])),
    ]));
  }
  Widget _follow(String what, String when, String pri, Color c)=> Padding(padding: const EdgeInsets.only(bottom:6), child: Row(children:[
    Container(width:3,height:28, decoration:BoxDecoration(color:c, borderRadius:BorderRadius.circular(999))),
    const SizedBox(width:8),
    Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(what, style: const TextStyle(fontSize:11,fontWeight:FontWeight.w600)), Text(when, style: const TextStyle(fontSize:11,color:OrbitTheme.muted))])),
    Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration:BoxDecoration(color:c.withOpacity(0.10), borderRadius:BorderRadius.circular(999)), child: Text(pri, style: TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:c))),
  ]));
}
