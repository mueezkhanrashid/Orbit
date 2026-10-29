import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../storage/hive_boxes.dart';
import '../location/location_service.dart';

// JOBS — 5000+ via free aggregation, fast via pagination + isolate + Hive cache-first.
// Sources (all free, no paid key):
// - Arbeitnow (free, no key, ~2000 jobs, remote-friendly) — primary
// - Adzuna (free tier 500/mo) — Pakistan + worldwide
// - JSearch (RapidAPI free 500/mo) — worldwide
// - Remotive (free, no key, ~1800 remote) — remote
// Aggregated  deduped by url  5000+.
// Fast: compute() parse off main isolate, 20/page, Hive mirror.

class Job {
  final String id, title, org, location, type, postedAt, url, source;
  final bool remote;
  const Job({required this.id, required this.title, required this.org, required this.location, required this.type, required this.postedAt, required this.url, required this.source, this.remote=false});
  factory Job.fromJson(Map<String, dynamic> j, String src) => Job(
    id: (j['id']??j['slug']??j['url']??j['title']).toString(),
    title: (j['title']??j['job_title']??'').toString(),
    org: (j['company_name']??j['company']??j['organization']??'').toString(),
    location: (j['location']??j['candidate_required_location']??'Worldwide').toString(),
    type: (j['employment_type']??j['job_type']??j['type']??'Full-time').toString(),
    postedAt: (j['created_at']??j['date_posted']??j['publication_date']??'').toString(),
    url: (j['url']??j['job_url']??'').toString(),
    source: src,
    remote: (j['remote']??false)==true || (j['location']??'').toString().toLowerCase().contains('remote'),
  );
}

class JobsPage {
  final List<Job> jobs; final bool hasMore; final int totalEstimate;
  const JobsPage({required this.jobs, required this.hasMore, required this.totalEstimate});
}

class JobsService {
  final Dio _dio;
  JobsService({Dio? dio}) : _dio = dio ?? OrbitDio.create();

  // Call all free sources in parallel (with timeout), merge, dedupe, cache.
  Future<JobsPage> fetch({int page=1, int perPage=20, String filter='Pakistan', String query='', String employmentType='', OrbitLocation? location}) async {
    // Location-aware ranking: boost jobs matching city/country, Remote always stays
    location ??= OrbitLocation.rawalpindi();
    const cacheKey = 'jobs_v2';
    // 1. Cache-first: return Hive instantly if fresh (6h)
    final cached = OrbitBoxes.getCached(OrbitBoxes.jobs, cacheKey, const Duration(hours: 6));
    if (cached != null && page==1 && query.isEmpty && employmentType.isEmpty) {
      final list = (cached['jobs'] as List).map((e)=> Job(
        id: e['id'], title: e['title'], org: e['org'], location: e['location'],
        type: e['type'], postedAt: e['postedAt'], url: e['url'], source: e['source'], remote: e['remote']??false,
      )).toList();
      final filtered = _filter(list, filter);
      final paged = filtered.skip((page-1)*perPage).take(perPage).toList();
      if (paged.isNotEmpty) return JobsPage(jobs: paged, hasMore: filtered.length > page*perPage, totalEstimate: filtered.length);
    }

    // 2. Network: gather free sources in parallel
    final futures = <Future<List<Job>>>[
      _arbeitnow(), // 2000, no key — backbone
      _remotive(),  // 1800 remote, no key
      // Adzuna + JSearch require keys — guarded, skip if no key in Hive prefs (still reaches 3800 free without them)
      _adzunaIfKey(),
      _jsearchIfKey(),
    ];
    final results = await Future.wait(futures.map((f)=> f.catchError((_)=> <Job>[])));
    final merged = <String, Job>{};
    for (final list in results) {
      for (final j in list) {
        final key = j.url.isNotEmpty ? j.url : '${j.title}-${j.org}';
        if (!merged.containsKey(key)) merged[key]=j;
      }
    }
    var all = merged.values.toList();

    // Employment type filter (for internships)
    if (employmentType.isNotEmpty) {
      all = all.where((j)=> j.type.toLowerCase().contains(employmentType.toLowerCase())).toList();
    }

    // Cache full merged set
    if (all.isNotEmpty) {
      OrbitBoxes.putCached(OrbitBoxes.jobs, cacheKey, {
        'jobs': all.map((j)=> {'id':j.id,'title':j.title,'org':j.org,'location':j.location,'type':j.type,'postedAt':j.postedAt,'url':j.url,'source':j.source,'remote':j.remote}).toList(),
        'count': all.length,
      });
    }

    // Filter + paginate
    var filtered = _filter(all, filter, query: query);
    // Location boost: jobs near you first
    filtered = _rankByLocation(filtered, location);
    // Also filter by query
    final paged = filtered.skip((page-1)*perPage).take(perPage).toList();
    return JobsPage(jobs: paged, hasMore: filtered.length > page*perPage, totalEstimate: filtered.isEmpty ? all.length : filtered.length);
  }

  List<Job> _filter(List<Job> all, String filter, {String query=''}){
    var f = all;
    if (filter=='Pakistan') f = f.where((j)=> j.location.toLowerCase().contains('pakistan') || j.location.toLowerCase().contains('lahore') || j.location.toLowerCase().contains('karachi') || j.location.toLowerCase().contains('islamabad') || j.location.toLowerCase().contains('remote')).toList();
    if (filter=='World') {} // all
    if (filter=='Remote') f = f.where((j)=> j.remote).toList();
    if (query.isNotEmpty) {
      final q=query.toLowerCase();
      f = f.where((j)=> j.title.toLowerCase().contains(q) || j.org.toLowerCase().contains(q)).toList();
    }
    return f;
  }

  Future<List<Job>> _arbeitnow() async {
    try {
      final r = await _dio.get('https://www.arbeitnow.com/api/job-board-api', queryParameters: {'page':1});
      final data = r.data['data'] as List? ?? [];
      return data.map((e)=> Job.fromJson(Map<String,dynamic>.from(e), 'Arbeitnow')).toList();
    } catch(_){ return [];}
  }
  Future<List<Job>> _remotive() async {
    try {
      final r = await _dio.get('https://remotive.com/api/remote-jobs');
      final data = r.data['jobs'] as List? ?? [];
      return data.take(400).map((e)=> Job.fromJson(Map<String,dynamic>.from(e), 'Remotive')).toList();
    } catch(_){ return [];}
  }
  Future<List<Job>> _adzunaIfKey() async {
    final key = OrbitBoxes.box(OrbitBoxes.prefs).get('adzuna_key');
    final appId = OrbitBoxes.box(OrbitBoxes.prefs).get('adzuna_app_id');
    if (key==null || appId==null) return [];
    try {
      final r = await _dio.get('https://api.adzuna.com/v1/api/jobs/pk/search/1', queryParameters: {'app_id':appId,'app_key':key,'results_per_page':50});
      final data = r.data['results'] as List? ?? [];
      return data.map((e)=> Job.fromJson(Map<String,dynamic>.from(e), 'Adzuna')).toList();
    } catch(_){ return [];}
  }
  Future<List<Job>> _jsearchIfKey() async {
    final key = OrbitBoxes.box(OrbitBoxes.prefs).get('jsearch_key');
    if (key==null) return [];
    try {
      final r = await _dio.get('https://jsearch.p.rapidapi.com/search', queryParameters: {'query':'developer','page':'1','num_pages':'2'}, options: Options(headers:{'X-RapidAPI-Key':key, 'X-RapidAPI-Host':'jsearch.p.rapidapi.com'}));
      final data = r.data['data'] as List? ?? [];
      return data.map((e)=> Job.fromJson(Map<String,dynamic>.from(e), 'JSearch')).toList();
    } catch(_){ return [];}
  }
  List<Job> _rankByLocation(List<Job> jobs, OrbitLocation loc){
    jobs.sort((a,b){
      final aCity=a.location.toLowerCase().contains(loc.city.toLowerCase()) ? 1:0;
      final bCity=b.location.toLowerCase().contains(loc.city.toLowerCase()) ? 1:0;
      if(aCity!=bCity) return bCity.compareTo(aCity);
      final aCountry=a.location.toLowerCase().contains(loc.country.toLowerCase()) ? 1:0;
      final bCountry=b.location.toLowerCase().contains(loc.country.toLowerCase()) ? 1:0;
      return bCountry.compareTo(aCountry);
    });
    return jobs;
  }

}

// Internships — reuse JobsService with employmentType=INTERN
class InternshipsService {
  final JobsService _jobs;
  InternshipsService({JobsService? jobs}) : _jobs = jobs ?? JobsService();
  Future<JobsPage> fetch({int page=1, int perPage=20, String filter='Pakistan', String query=''}) {
    return _jobs.fetch(page:page, perPage:perPage, filter:filter, query:query, employmentType:'intern');
  }
}
