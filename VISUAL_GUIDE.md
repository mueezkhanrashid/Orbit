# ORBIT 1.3.0+14 — Visual Guide (Zara QA)

**Google-quality UI — 390px no-overflow, flat 1px #e8e8e8, quiet 3% colour, KPI 400 tabular**

## Home (ORBIT)
- **AppBar**: 48px, `O` monogram teal 28×28, title 14/600, sub 11/muted, 1px rule, search action only.
- **Weather well**: Wrap 8px run 4px, 56px boxes 9/600, humidity/wind/AQI/high, no Row overflow 104px fix.
- **KPI tiles**: 2×2 phone (1.6 aspect), 4 cols desktop (1.4), label 12/500 muted, value 28/400 Instrument Sans tabular, caption 11/muted, no shadows, flat border #e8e8e8, stagger 80ms, CountUp 900ms.
- **Stories 9+3**: 9-flex stories panel + 3-flex weather panel, 16px gap, Chip 12/600 selected #EEEEEE, cards 63px, 8px gaps.

## Space
- **ISS**: Live lat/lng/velocity, 5s timer (skipped in test via `orbitIsTest`), refresh + fallback open-notify, no Hang.
- **Missions**: 6 upcomings via SpaceDevs, 7s timeout, offline retry.
- **APOD**: NASA DEMO_KEY, 7s, offline fallback.

## Explore
- **Search**: TextField 999 radius, hint 11/muted, filled #F5F5F5, 1px outline.
- **Tiles**: 2-col, 8px gaps, FuturisticCard flat border, haptic, no gradients/shadows.

## Faith Pocket (8 tabs)
- **Tabs**: isScrollable, 12/600 label, 2px ink indicator, 1px ground rule, 8 tabs: Faith, Leads, Jobs, Scholarships, Assistant, Productivity, Notes, Fit.
- **Faith**: Ayah 65:2 card, Zikar ring 36px 4/5 progress, Namaz dots 6px, Qibla 68° NE.
- **Leads**: Smart inbox 0-100 WHY, Hot/Saved/Expiring, TF-IDF cosine, 6 feeds, no PII, on-device.

## Realtime & Cache
- **FastCache**: 0ms in-mem, Hive persists, dedup, 60fps, 1.8s warm via OrbitShell postFrame, `orbitIsTest` skips timers/network in widget tests.
- **Location**: GPS 25m, 4s timeout, fallback Rawalpindi 33.5651,73.0169, FastCache + Hive 1h.
- **Security**: Hive AES-256, biometric, app lock, SSL pinning, clipboard clear, no PII.

## Tests
- `flutter test` 21/21 in 7s (verified 6, interaction 4, smoke 2, speed 8), `dart analyze` 49 files 13 info, no errors.
- Interaction: Home KPI tappable, Bottom nav 5, Explore search, Faith 8 tabs — all `orbitIsTest` + `FakeLocationService` + `RealtimeService..stop` + 800+800+400 pumps.

## Build
- `flutter build apk --release` — Gradle 8.3.0, Kotlin 1.9.22, `settings.gradle:9 "$flutterSdkPath"` fix, workflow fallback `sed -n 9p`.
