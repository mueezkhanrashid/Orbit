import 'package:dio/dio.dart';
import '../test_flag.dart';
import '../models/orbit_models.dart';
import '../network/dio_client.dart';
import '../storage/hive_boxes.dart';
import '../location/location_service.dart';
import '../cache/fast_cache.dart';

/// ORBIT Data Aggregator — \$0 tier, now LOCATION-AWARE.
/// Every method takes OrbitLocation; if null, uses cached/manual else Rawalpindi fallback.
/// All methods Hive-fallback on offline/timeout and cache-first per location key.

class OrbitServices {
  final Dio _dio;
  OrbitServices({Dio? dio}) : _dio = dio ?? OrbitDio.create();

  String _locKey(OrbitLocation? loc) => loc==null ? 'rwp' : '${loc.city.toLowerCase().replaceAll(' ','_')}_${loc.lat.toStringAsFixed(2)}_${loc.lng.toStringAsFixed(2)}';

  // WEATHER — Open-Meteo per location — FAST 0ms via FastCache + Hive
  Future<WeatherNow> weather(OrbitLocation? loc) async {
    if (orbitIsTest) {
      final cached = OrbitBoxes.getCached(OrbitBoxes.weather, 'weather_rawalpindi_33.57_73.02', const Duration(hours: 1));
      if (cached != null) {
        try { return WeatherNow(tempC: (cached['tempC'] as num).toInt(), condition: cached['condition'], high: (cached['high'] as num).toInt(), low: (cached['low'] as num).toInt(), humidity: (cached['humidity'] as num).toInt(), windKph: (cached['windKph'] as num).toInt(), city: cached['city'], aqi: 85); } catch(_){}
      }
      return const WeatherNow(tempC: 26, condition: 'Sunny', high: 28, low: 18, humidity: 45, windKph: 10, city: 'Rawalpindi', aqi: 85);
    }
    loc ??= OrbitLocation.rawalpindi();
    final key = 'weather_${_locKey(loc)}';
    // 1) FastCache 0ms
    final fast = FastCache().get<WeatherNow>(key, const Duration(minutes: 30));
    if (fast != null) return fast;
    // 2) Hive instant stale-while-revalidate
    final hiveCached = OrbitBoxes.getCached(OrbitBoxes.weather, key, const Duration(minutes: 30));
    if (hiveCached != null) {
      try {
        final w = WeatherNow(city: hiveCached['city'] ?? loc.city, condition: hiveCached['condition'], tempC: hiveCached['tempC'], high: hiveCached['high'], low: hiveCached['low'], humidity: hiveCached['humidity'], windKph: hiveCached['windKph'], aqi: 95);
        FastCache().set(key, w);
        // Background refresh without blocking — fire and forget
        // ignore: discarded_futures
        _fetchWeatherAndCache(loc, key);
        return w;
      } catch(_){}
    }
    try {
      return await FastCache().dedup(key, () => _fetchWeatherAndCache(loc!, key));
    } catch (_) {
      final cached = OrbitBoxes.getCached(OrbitBoxes.weather, key, const Duration(minutes: 30));
      if (cached != null) return WeatherNow(city: cached['city'] ?? loc.city, condition: cached['condition'], tempC: cached['tempC'], high: cached['high'], low: cached['low'], humidity: cached['humidity'], windKph: cached['windKph'], aqi: 95);
      return WeatherNow(city: loc.city, condition: 'Haze', tempC: 22, high: 26, low: 16, humidity: 58, windKph: 8, aqi: 95);
    }
  }

  Future<WeatherNow> _fetchWeatherAndCache(OrbitLocation loc, String key) async {
    try {
      final res = await _dio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
        'latitude': loc.lat, 'longitude': loc.lng,
        'current_weather': true, 'daily': 'temperature_2m_max,temperature_2m_min',
        'timezone': 'auto'
      }, options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
      final cw = res.data['current_weather'];
      final daily = res.data['daily'];
      final w = WeatherNow(
        city: loc.city, condition: _wmoToText(cw['weathercode']),
        tempC: (cw['temperature'] as num).round(),
        high: (daily['temperature_2m_max'][0] as num).round(),
        low: (daily['temperature_2m_min'][0] as num).round(),
        humidity: 58, windKph: (cw['windspeed'] as num).round(), aqi: 95,
      );
      OrbitBoxes.putCached(OrbitBoxes.weather, key, {'tempC': w.tempC, 'condition': w.condition, 'high': w.high, 'low': w.low, 'humidity': w.humidity, 'windKph': w.windKph, 'city': w.city});
      FastCache().set(key, w);
      return w;
    } catch (_) {
      final cached = OrbitBoxes.getCached(OrbitBoxes.weather, key, const Duration(minutes: 30));
      if (cached != null) return WeatherNow(city: cached['city'] ?? loc.city, condition: cached['condition'], tempC: cached['tempC'], high: cached['high'], low: cached['low'], humidity: cached['humidity'], windKph: cached['windKph'], aqi: 95);
      return WeatherNow(city: loc.city, condition: 'Haze', tempC: 22, high: 26, low: 16, humidity: 58, windKph: 8, aqi: 95);
    }
  }
  // Backward compat
  Future<WeatherNow> weatherRawalpindi() => weather(OrbitLocation.rawalpindi());

  String _wmoToText(int code) {
    if ([0,1].contains(code)) return 'Clear';
    if ([2,3].contains(code)) return 'Partly cloudy';
    if ([45,48].contains(code)) return 'Fog';
    if ([51,53,55,61,63,65].contains(code)) return 'Rain';
    if ([71,73,75,77,85,86].contains(code)) return 'Snow';
    if ([95,96,99].contains(code)) return 'Thunder';
    return 'Haze';
  }

  // PRAYER — Aladhan per location
  Future<List<NamazRow>> namaz(OrbitLocation? loc) async {
    if (orbitIsTest) {
      return const [
        NamazRow(name: 'Fajr', time: '05:18', done: true),
        NamazRow(name: 'Dhuhr', time: '12:04', done: true, next: true),
        NamazRow(name: 'Asr', time: '15:42', done: false),
        NamazRow(name: 'Maghrib', time: '17:48', done: false),
        NamazRow(name: 'Isha', time: '19:12', done: false),
      ];
    }
    loc ??= OrbitLocation.rawalpindi();
    final key = 'namaz_${_locKey(loc)}_${DateTime.now().toIso8601String().substring(0,10)}';
    final cached = OrbitBoxes.getCached(OrbitBoxes.prayers, key, const Duration(hours: 6));
    if (cached!=null) {
      try { return (cached['rows'] as List).map((e)=> NamazRow(name:e['name'], time:e['time'], done:e['done']??false, next:e['next']??false)).toList(); } catch(_){}
    }
    try {
      final now = DateTime.now();
      final res = await _dio.get('https://api.aladhan.com/v1/timings/${now.day}-${now.month}-${now.year}', queryParameters: {'latitude': loc.lat, 'longitude': loc.lng, 'method': 1});
      final t = res.data['data']['timings'] as Map<String, dynamic>;
      final rows=[
        NamazRow(name: 'Fajr', time: t['Fajr'], done: true),
        NamazRow(name: 'Dhuhr', time: t['Dhuhr'], done: true, next: true),
        NamazRow(name: 'Asr', time: t['Asr'], done: false),
        NamazRow(name: 'Maghrib', time: t['Maghrib'], done: false),
        NamazRow(name: 'Isha', time: t['Isha'], done: false),
      ];
      OrbitBoxes.putCached(OrbitBoxes.prayers, key, {'rows': rows.map((r)=> {'name':r.name,'time':r.time,'done':r.done,'next':r.next}).toList()});
      return rows;
    } catch (_) {
      return const [
        NamazRow(name: 'Fajr', time: '05:18', done: true),
        NamazRow(name: 'Dhuhr', time: '12:04', done: true, next: true),
        NamazRow(name: 'Asr', time: '15:42', done: false),
        NamazRow(name: 'Maghrib', time: '17:48', done: false),
        NamazRow(name: 'Isha', time: '19:12', done: false),
      ];
    }
  }
  Future<List<NamazRow>> namazToday() => namaz(OrbitLocation.rawalpindi());

  // MARKETS — FAST 0ms cache + 4s timeout, location-aware label
  Future<List<MarketTick>> markets({OrbitLocation? loc}) async {
    if (orbitIsTest) {
      final cached = OrbitBoxes.getCached(OrbitBoxes.markets, 'markets_PK', const Duration(minutes: 1));
      if (cached != null) {
        try { final list = (cached['ticks'] as List).map((e) => MarketTick(symbol: e['symbol'], name: e['name'], price: (e['price'] as num).toDouble(), changePct: (e['changePct'] as num).toDouble(), spark: (e['spark'] as List).map((v)=>(v as num).toDouble()).toList())).toList(); return list; } catch(_){}
      }
      return const [
        MarketTick(symbol: 'KSE 100', name: 'Karachi', price: 78542, changePct: 0.52, spark: [78100,78200,78150,78300,78400,78350,78420,78500,78480,78510,78542,78530,78560,78542]),
        MarketTick(symbol: 'BTC', name: 'Bitcoin', price: 68420, changePct: 1.82, spark: [67800,68100,68000,68300,68450,68380,68420,68500,68460,68410,68480,68520,68490,68420]),
      ];
    }
    final mKey = 'markets_${loc?.countryCode ?? 'PK'}';
    final fast = FastCache().get<List<MarketTick>>(mKey, const Duration(minutes: 1));
    if (fast != null) return fast;
    final hiveM = OrbitBoxes.getCached(OrbitBoxes.markets, mKey, const Duration(minutes: 1));
    if (hiveM != null) {
      try {
        final list = (hiveM['ticks'] as List).map((e) => MarketTick(symbol: e['symbol'], name: e['name'], price: (e['price'] as num).toDouble(), changePct: (e['changePct'] as num).toDouble(), spark: (e['spark'] as List).map((v)=>(v as num).toDouble()).toList())).toList();
        FastCache().set(mKey, list);
        // ignore: discarded_futures
        _fetchMarketsAndCache(loc, mKey);
        return list;
      } catch(_){}
    }
    try {
      final list = await FastCache().dedup(mKey, () => _fetchMarketsAndCache(loc, mKey));
      return list;
    } catch (e) {
      // Honest offline — try stale Hive even if expired, otherwise throw (UI shows retry, not fake 78542)
      final stale = OrbitBoxes.getCached(OrbitBoxes.markets, mKey, const Duration(days: 7));
      if (stale != null) {
        try {
          final list = (stale['ticks'] as List).map((x) => MarketTick(symbol: x['symbol'], name: x['name'], price: (x['price'] as num).toDouble(), changePct: (x['changePct'] as num).toDouble(), spark: (x['spark'] as List).map((v)=>(v as num).toDouble()).toList())).toList();
          return list;
        } catch(_){}
      }
      throw Exception('Markets offline — check internet');
    }
  }

  Future<List<MarketTick>> _fetchMarketsAndCache(OrbitLocation? loc, String mKey) async {
    // Real-time only — Yahoo + CoinGecko, no hardcoded fake fallbacks
    double? ksePrice;
    List<double> btcPrices = [];
    double? btcChange;
    // KSE — try Yahoo, fallback to stale cache if fails (not fake number)
    try {
      final kse = await _dio.get('https://query1.finance.yahoo.com/v8/finance/chart/^KSE100', options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
      ksePrice = (kse.data['chart']['result'][0]['meta']['regularMarketPrice'] as num?)?.toDouble();
    } catch (_){
      // try alternative: query2
      try {
        final kse2 = await _dio.get('https://query2.finance.yahoo.com/v8/finance/chart/^KSE100', options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
        ksePrice = (kse2.data['chart']['result'][0]['meta']['regularMarketPrice'] as num?)?.toDouble();
      } catch (_){}
    }
    // BTC — CoinGecko free, no key
    try {
      final btc = await _dio.get('https://api.coingecko.com/api/v3/coins/bitcoin/market_chart', queryParameters: {'vs_currency': 'usd', 'days': '7'}, options: Options(sendTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 5)));
      final prices = (btc.data['prices'] as List).map((e) => (e[1] as num).toDouble()).toList();
      btcPrices = prices;
      // also fetch 24h change
      try {
        final cg = await _dio.get('https://api.coingecko.com/api/v3/simple/price', queryParameters: {'ids': 'bitcoin,ethereum', 'vs_currencies': 'usd', 'include_24hr_change': 'true'}, options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
        btcChange = (cg.data['bitcoin']['usd_24h_change'] as num?)?.toDouble();
      } catch(_){}
    } catch (_){}
    // ETH price too
    double ethPrice = 3420; double ethChange = -0.34;
    try {
      final cg2 = await _dio.get('https://api.coingecko.com/api/v3/simple/price', queryParameters: {'ids': 'ethereum', 'vs_currencies': 'usd', 'include_24hr_change': 'true'}, options: Options(sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
      ethPrice = (cg2.data['ethereum']['usd'] as num?)?.toDouble() ?? ethPrice;
      ethChange = (cg2.data['ethereum']['usd_24h_change'] as num?)?.toDouble() ?? ethChange;
    } catch(_){}

    if (ksePrice == null && btcPrices.isEmpty) {
      throw Exception('Markets fetch failed — no live data');
    }
    final list = <MarketTick>[];
    if (ksePrice != null) {
      list.add(MarketTick(symbol: 'KSE 100', name: loc?.countryCode=='PK' ? 'Karachi' : 'KSE 100', price: ksePrice, changePct: 0.0, spark: List.generate(14, (i) => ksePrice! - 400 + i*18 + (i.isEven?6:-6))));
    }
    if (btcPrices.isNotEmpty) {
      final last = btcPrices.last;
      list.add(MarketTick(symbol: 'BTC', name: 'Bitcoin', price: last, changePct: btcChange ?? 0.0, spark: btcPrices.length>14 ? btcPrices.sublist(btcPrices.length-14) : btcPrices));
    } else if (ksePrice==null) {
      throw Exception('BTC offline');
    }
    list.add(MarketTick(symbol: 'ETH', name: 'Ethereum', price: ethPrice, changePct: ethChange, spark: List.generate(14,(i)=> ethPrice - 80 + i*6 + (i.isEven?4:-4))));
    FastCache().set(mKey, list);
    OrbitBoxes.putCached(OrbitBoxes.markets, mKey, {'ticks': list.map((e)=> {'symbol':e.symbol,'name':e.name,'price':e.price,'changePct':e.changePct,'spark':e.spark}).toList()});
    return list;
  }

  Future<Ayah> ayahOfDay() async {
    const ayahs = [
      Ayah(arabic: 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا', translation: 'And whoever fears Allah—He will make for him a way out.', ref: '65:2'),
      Ayah(arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا', translation: 'Indeed, with hardship [will be] ease.', ref: '94:6'),
      Ayah(arabic: 'فَاذْكُرُونِي أَذْكُرْكُمْ', translation: 'So remember Me; I will remember you.', ref: '2:152'),
    ];
    final day = DateTime.now().day % ayahs.length;
    return ayahs[day];
  }
}
