// Constants — single source, no magic numbers in widgets.
class OrbitConstants {
  static const cityLat = 33.5651;
  static const cityLng = 73.0169;
  static const cityName = 'Rawalpindi';
  static const cacheTtlNews = Duration(minutes: 15);
  static const cacheTtlWeather = Duration(minutes: 30);
  static const cacheTtlMarkets = Duration(minutes: 1);
  static const cacheTtlJobs = Duration(hours: 6);
  static const cacheTtlSpace = Duration(hours: 1);
  static const zikarGoal = 33;
  static const apkTargetSizeMb = 45;
  static const coldStartBudgetMs = 2500;
}

class OrbitEndpoints {
  static const openMeteo = 'https://api.open-meteo.com/v1/forecast';
  static const aladhan = 'https://api.aladhan.com/v1/timings';
  static const coingecko = 'https://api.coingecko.com/api/v3/coins';
  static const yahooChart = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const launchLibrary = 'https://ll.thespacedevs.com/2.2.0/launch/upcoming';
  static const apod = 'https://api.nasa.gov/planetary/apod';
  // GNews free tier (user adds key in Settings  free 100/d) else RSS fallback
  static const gnews = 'https://gnews.io/api/v4';
}
