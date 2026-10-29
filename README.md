# ORBIT — Pakistan Super-App 1.5.24

**Pakistan’s everyday app — News, Jobs, Scholarships, Weather, Space, Markets, Quran, Namaz, Qibla**

ORBIT brings Pakistan together in one beautiful, fast app. Built for Google quality, tuned for Rawalpindi and every city.

## What ORBIT does
- **News** — Daily Pakistan & World, trending
- **Jobs & Internships** — Worldwide + Pakistan filter, near you first
- **Scholarships** — Worldwide, for Pakistani students, fully funded first
- **Weather** — 7-day + hourly + AQI, per your GPS
- **Space** — ISS live, Earth view, missions, APOD
- **Markets** — Stocks & Crypto live 60s
- **Faith** — Quran 114, Namaz times per GPS, Qibla compass live, Zikar, Notebook
- **Productivity** — Tasks, Focus, Habits, Calendar
- **Home Widget 4×2** — Swipeable, Qibla live, Namaz/Space/News/Jobs/Weather/Markets
- **Explore** — Search everything in one place

## Run
```bash
cd orbit_app
flutter pub get
flutter analyze   # 0 errors
flutter test      # 21/21
flutter run
flutter build apk --release --split-per-abi
```

## Build without local SDK
Push to GitHub → Actions → **Build ORBIT APK** → download `orbit-apk` artifact. Workflow auto-fixes Gradle (`settings.gradle` 22% rounding, `$flutterSdkPath`).

## Design
- `orbit_brand_guide.html` — Brand identity (icon + wordmark, flat, 22% radius, teal #0E4C46)
- `orbit-icon.png` 2048 master + `mipmap-*` deployed
- Google-quality UI, 390px no overflow, flat 1px #e8e8e8, quiet 3% colour

## Structure
- `lib/app` — providers, router
- `lib/theme` — OrbitTheme + advanced animations
- `lib/core` — location, services, storage, widget
- `lib/features` — home, news, jobs, scholarships, space, markets, leads, assistant, productivity, faith, explore, settings, widget
- `lib/widgets` — orbit_card, location_header
- `test` — verified (6), interaction (4), smoke (3), speed (8) — 21 tests
