import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../storage/hive_boxes.dart';
import '../location/location_service.dart';

// NEWS — REAL-TIME, \$0, NO demo duplication.
// Sources (free, no key required for RSS):
// - GNews (if key in Settings, 100/d) — optional
// - RSS via rss2json (free, no key): Dawn, Geo, BBC, Reuters — primary
// No synthetic filler, no while(...<100) duplication. Real count (20-40) with honest empty state.
// Trending: real by recency from RSS pubDate, not fake trending flags.

class NewsArticle {
  final String title, source, timeAgo, category, image, url;
  final bool trending;
  final DateTime? publishedAt;
  const NewsArticle({required this.title, required this.source, required this.timeAgo, required this.category, required this.image, required this.url, this.trending=false, this.publishedAt});
  Map<String,dynamic> toJson()=> {'title':title,'source':source,'timeAgo':timeAgo,'category':category,'image':image,'url':url,'trending':trending,'publishedAt':publishedAt?.toIso8601String()};
  factory NewsArticle.fromJson(Map j)=> NewsArticle(title:j['title'], source:j['source'], timeAgo:j['timeAgo'], category:j['category'], image:j['image'], url:j['url'], trending:j['trending']??false, publishedAt: j['publishedAt']!=null ? DateTime.tryParse(j['publishedAt']) : null);
}

class NewsPage {
  final List<NewsArticle> articles; final bool hasMore;
  const NewsPage({required this.articles, required this.hasMore});
}

class NewsService {
  final Dio _dio;
  NewsService({Dio? dio}) : _dio = dio ?? OrbitDio.create();

  Future<NewsPage> fetch({int page=1, int perPage=20, String category='All', String scope='Auto', bool trending=false, OrbitLocation? location}) async {
    location ??= OrbitLocation.rawalpindi();
    const key='news_live_v3';
    // 15m cache, but always try live first for pull-to-refresh freshness
    final cached = OrbitBoxes.getCached(OrbitBoxes.news, key, const Duration(minutes:15));
    List<NewsArticle> cachedList=[];
    if (cached!=null) {
      try {
        cachedList = (cached['articles'] as List).map((e)=> NewsArticle.fromJson(Map<String,dynamic>.from(e))).toList();
      } catch (_) {}
    }

    // Fetch live (if network fails, use cached; if no cached, return empty honest, NOT fake)
    final live = await _fetchLive();
    List<NewsArticle> all;
    if (live.isNotEmpty) {
      all = live;
      OrbitBoxes.putCached(OrbitBoxes.news, key, {'articles': all.map((a)=> a.toJson()).toList(), 'fetchedAt': DateTime.now().toIso8601String()});
    } else if (cachedList.isNotEmpty) {
      all = cachedList;
    } else {
      // Honest empty — caller shows "No news. Pull to retry. Check internet." No fake 24.
      return const NewsPage(articles: [], hasMore: false);
    }

    var f = all;
    if (category!='All') f = f.where((a)=> a.category.toLowerCase()==category.toLowerCase()).toList();
    final effectiveScope = scope=='Auto' ? (location.countryCode=='PK' ? 'Pakistan' : 'World') : scope;
    if (effectiveScope=='World') f = f.where((a)=> a.category!='Pakistan' || a.source=='BBC' || a.source=='Reuters').toList();
    if (trending) f = f.where((a)=> a.trending).toList();
    f = _rankByLocation(f, location);
    final paged = f.skip((page-1)*perPage).take(perPage).toList();
    return NewsPage(articles: paged, hasMore: f.length > page*perPage);
  }

  List<NewsArticle> _rankByLocation(List<NewsArticle> list, OrbitLocation loc){
    final isPK = loc.countryCode=='PK';
    // Trending first, then PK sources if PK
    list.sort((a,b){
      if (a.trending && !b.trending) return -1;
      if (!a.trending && b.trending) return 1;
      // Then recency
      final at = a.publishedAt ?? DateTime(2000);
      final bt = b.publishedAt ?? DateTime(2000);
      final recency = bt.compareTo(at);
      if (recency!=0) return recency;
      int sa = (isPK && (a.source=='Dawn'||a.source=='Geo')?1:0);
      int sb = (isPK && (b.source=='Dawn'||b.source=='Geo')?1:0);
      return sb.compareTo(sa);
    });
    return list;
  }

  Future<List<NewsArticle>> _fetchLive() async {
    final out=<NewsArticle>[];
    // 1. GNews if key in prefs (optional, 100/d free)
    final gkey = OrbitBoxes.box(OrbitBoxes.prefs).get('gnews_key');
    if (gkey!=null && (gkey as String).isNotEmpty) {
      try {
        final r = await _dio.get('https://gnews.io/api/v4/top-headlines',
          queryParameters:{'country':'pk','lang':'en','max':20,'apikey':gkey},
          options: Options(sendTimeout: const Duration(seconds: 7), receiveTimeout: const Duration(seconds: 7)),
        );
        for(final a in (r.data['articles'] as List? ?? [])){
          final pub = a['publishedAt']!=null ? DateTime.tryParse(a['publishedAt']) : null;
          out.add(NewsArticle(
            title: (a['title']??'').toString(),
            source: (a['source']?['name']??'GNews').toString(),
            timeAgo: pub!=null ? _timeAgo(pub) : '1h',
            category: 'World',
            image: (a['image']??'').toString(),
            url: (a['url']??'').toString(),
            trending: false,
            publishedAt: pub,
          ));
        }
      } catch(_){}
    }
    // 2. RSS fallbacks — Dawn, Geo, BBC, Reuters via rss2json (free, no key) — parallel
    const rssMap = {
      'https://www.dawn.com/feed': {'source': 'Dawn', 'category':'Pakistan'},
      'https://www.geo.tv/rss/1/0': {'source': 'Geo', 'category':'Pakistan'},
      'https://feeds.bbci.co.uk/news/world/rss.xml': {'source': 'BBC', 'category':'World'},
      'https://www.reutersagency.com/feed/?best-topics=tech&post_type=best': {'source': 'Reuters', 'category':'Tech'},
    };
    final rssFutures = rssMap.entries.map((e) => _fetchRss(e.key, e.value['source']!, e.value['category']!).catchError((_)=> <NewsArticle>[]));
    final rssResults = await Future.wait(rssFutures);
    for (final list in rssResults) { out.addAll(list); }

    if (out.isEmpty) return [];
    // No duplication to 100 — return real count (20-60)
    // Mark top 4 most recent as trending honestly
    out.sort((a,b)=> (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
    for (int i=0;i<out.length && i<4;i++) {
      out[i] = NewsArticle(title: out[i].title, source: out[i].source, timeAgo: out[i].timeAgo, category: out[i].category, image: out[i].image, url: out[i].url, trending: true, publishedAt: out[i].publishedAt);
    }
    // De-dupe by url
    final seen=<String,NewsArticle>{};
    for (final a in out) {
      final key = a.url.isNotEmpty ? a.url : a.title;
      if (!seen.containsKey(key)) seen[key]=a;
    }
    return seen.values.toList();
  }

  Future<List<NewsArticle>> _fetchRss(String rssUrl, String source, String category) async {
    try {
      final r = await _dio.get('https://api.rss2json.com/v1/api.json',
        queryParameters:{'rss_url': rssUrl},
        options: Options(sendTimeout: const Duration(seconds: 7), receiveTimeout: const Duration(seconds: 7)),
      );
      if (r.data['status'] != 'ok') return [];
      final items = r.data['items'] as List? ?? [];
      final list=<NewsArticle>[];
      for(final item in items.take(10)){
        final title = (item['title']??'').toString().trim();
        if (title.isEmpty) continue;
        final pub = item['pubDate']!=null ? DateTime.tryParse(item['pubDate']) : null;
        final enclosure = item['enclosure'] is Map ? item['enclosure']['link'] : null;
        final thumb = enclosure?.toString() ?? (item['thumbnail']??'').toString();
        list.add(NewsArticle(
          title: title,
          source: source,
          timeAgo: pub!=null ? _timeAgo(pub) : '2h',
          category: category,
          image: thumb,
          url: (item['link']??'').toString(),
          trending: false,
          publishedAt: pub,
        ));
      }
      return list;
    } catch(_){
      return [];
    }
  }

  String _timeAgo(DateTime dt){
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
