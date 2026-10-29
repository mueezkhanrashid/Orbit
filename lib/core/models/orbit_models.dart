// Single-file models for Sprint 1. Codegen via hive_generator in Sprint 2.
class NewsItem { final String title, source, time, category, image; final String url; const NewsItem({required this.title, required this.source, required this.time, required this.category, required this.image, this.url=''}); }
class WeatherNow { final String city, condition; final int tempC, high, low, humidity, windKph, aqi; const WeatherNow({required this.city, required this.condition, required this.tempC, required this.high, required this.low, required this.humidity, required this.windKph, required this.aqi}); }
class MarketTick { final String symbol, name; final double price, changePct; final List<double> spark; const MarketTick({required this.symbol, required this.name, required this.price, required this.changePct, required this.spark}); }
class Opportunity { final String title, org, location, type, deadline, tag; const Opportunity({required this.title, required this.org, required this.location, required this.type, required this.deadline, required this.tag}); }
class Ayah { final String arabic, translation, ref; const Ayah({required this.arabic, required this.translation, required this.ref}); }
class NamazRow { final String name, time; final bool done, next; const NamazRow({required this.name, required this.time, this.done=false, this.next=false}); }
class ZikarToday { final int count, goal; final String phrase; const ZikarToday({required this.count, required this.goal, required this.phrase}); }
