import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Generic paginated sliver — 20/page, builder, loading/next/error, 60fps.
// Used for 5000 jobs / 2000 interns / 1000 scholarships / 100 news — same widget, no jank.

class PaginatedSliverList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) onFetch;
  final Widget Function(BuildContext, T) itemBuilder;
  final int perPage;
  final String emptyText;
  const PaginatedSliverList({super.key, required this.onFetch, required this.itemBuilder, this.perPage=20, this.emptyText='No results'});
  @override State<PaginatedSliverList<T>> createState()=> _PaginatedSliverListState<T>();
}
class _PaginatedSliverListState<T> extends State<PaginatedSliverList<T>>{
  final _items=<T>[];
  int _page=1; bool _hasMore=true, _loading=false; String? _error;
  final _scroll=ScrollController();

  @override void initState(){
    super.initState();
    _load();
    _scroll.addListener((){
      if(_scroll.position.pixels > _scroll.position.maxScrollExtent - 400 && !_loading && _hasMore && _error==null){
        _load();
      }
    });
  }
  @override void dispose(){ _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    if(_loading) return;
    setState(()=> _loading=true);
    try{
      final chunk = await widget.onFetch(_page);
      if(!mounted) return;
      setState((){_items.addAll(chunk); _hasMore = chunk.length==widget.perPage; _page++; _error=null; _loading=false;});
    }catch(e){
      if(!mounted) return;
      setState((){_error=e.toString(); _loading=false;});
    }
  }

  @override Widget build(BuildContext context){
    if(_items.isEmpty && _loading){
      return SliverList.builder(itemCount:6, itemBuilder:(_,__)=> Padding(padding: const EdgeInsets.fromLTRB(12,8,12,0), child: Container(height:88, decoration:BoxDecoration(color:OrbitTheme.bg, borderRadius:BorderRadius.circular(12), border:Border.all(color:OrbitTheme.outline)))));
    }
    if(_items.isEmpty && _error!=null){
      return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Column(children:[const Icon(Icons.wifi_off, color:OrbitTheme.muted), const SizedBox(height:8), Text(_error!, style: const TextStyle(fontSize:11, color:OrbitTheme.muted)), const SizedBox(height:8), FilledButton(onPressed:(){ setState(()=> _error=null); _load();}, child: const Text('Retry'))])));
    }
    if(_items.isEmpty){
      return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(widget.emptyText, style: const TextStyle(color:OrbitTheme.muted)))));
    }
    return SliverList.builder(
      itemCount: _items.length + (_hasMore?1:0),
      itemBuilder:(c,i){
        if(i==_items.length){
          return Padding(padding: const EdgeInsets.all(16), child: Center(child: _loading ? const SizedBox(width:16,height:16, child: CircularProgressIndicator(strokeWidth:2)) : TextButton(onPressed: _load, child: const Text('Load more'))));
        }
        return widget.itemBuilder(c, _items[i]);
      },
    );
  }
}
