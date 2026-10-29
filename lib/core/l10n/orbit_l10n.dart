// ORBIT i18n — English + Urdu (RTL) ready. Best app = local, not translated.
// Sprint 2: wire with flutter_localizations. Sprint 3: Urdu strings audit.

class OrbitL10n {
  static const supported = ['en', 'ur'];
  static const _en = {
    'appTitle': 'ORBIT',
    'home': 'Home', 'news': 'News', 'space': 'Space', 'explore': 'Explore', 'faith': 'Faith',
    'goodMorning': 'Good morning',
    'offlineCached': 'Showing cached',
    'retry': 'Retry',
    'weatherLive': 'Live • 30m',
    'zikarToday': 'Zikar today',
    'namaz': 'Namaz',
    'qibla': 'Qibla',
  };
  static const _ur = {
    'appTitle': 'آربٹ',
    'home': 'ہوم', 'news': 'خبریں', 'space': 'خلا', 'explore': 'دریافت', 'faith': 'ایمان',
    'goodMorning': 'صبح بخیر',
    'offlineCached': 'محفوظ شدہ',
    'retry': 'دوبارہ کوشش کریں',
    'weatherLive': 'براہ راست • 30 منٹ',
    'zikarToday': 'آج کا ذکر',
    'namaz': 'نماز',
    'qibla': 'قبلہ',
  };
  static String t(String key, {String locale='en'}) {
    final m = locale=='ur' ? _ur : _en;
    return m[key] ?? key;
  }
}
