// ORBIT iOS Widget — swipeable via TabView PageTabViewStyle, 4×2 medium, well presented + Qibla compass
// Shows 6 cards via WidgetKit Timeline, updates 15m + 60s when app open · group.com.example.orbit
import WidgetKit
import SwiftUI

struct OrbitCard: Codable {
    let type, title, subtitle, meta, value, glyph: String
    let updatedAt: String
    let bearing: Double?
    let bearingLabel: String?
    let arrow: String?
}

struct OrbitEntry: TimelineEntry {
    let date: Date
    let cards: [OrbitCard]
    let updatedAt: String
}

struct OrbitProvider: TimelineProvider {
    func placeholder(in context: Context) -> OrbitEntry {
        OrbitEntry(date: Date(), cards: [
            OrbitCard(type:"namaz", title:"Fajr 05:18 • Dhuhr 12:04", subtitle:"Next: Dhuhr in 2h", meta:"Aladhan • Qibla 256° W", value:"Qibla 256° W ← • 3522 km", glyph:"◈", updatedAt: ISO8601DateFormatter().string(from: Date()), bearing: 256.0, bearingLabel: "256° W", arrow: "←"),
            OrbitCard(type:"qibla", title:"Qibla 256° W ←", subtitle:"Kaaba • 3522 km • Rawalpindi • Tap to navigate", meta:"Live bearing • 14:32", value:"↗ Align 256° W • Calibrated • North-up", glyph:"⌖", updatedAt: ISO8601DateFormatter().string(from: Date()), bearing: 256.0, bearingLabel: "256° W", arrow: "←"),
            OrbitCard(type:"space", title:"ISS 51.6° • -0.1°", subtitle:"Live • 27600", meta:"wheretheiss", value:"Missions 6", glyph:"⬡", updatedAt: ISO8601DateFormatter().string(from: Date()), bearing: nil, bearingLabel: nil, arrow: nil)
        ], updatedAt: "14:32")
    }
    func getSnapshot(in context: Context, completion: @escaping (OrbitEntry) -> Void) { completion(placeholder(in: context)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<OrbitEntry>) -> Void) {
        let shared = UserDefaults(suiteName: "group.com.example.orbit")
        let json = shared?.string(forKey: "orbit_widget_data") ?? ""
        var cards: [OrbitCard] = []
        var updated = ""
        if let data = json.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
           let arr = obj["cards"] as? [[String:Any]] {
            updated = obj["updatedAt"] as? String ?? ""
            for j in arr {
                cards.append(OrbitCard(
                    type: j["type"] as? String ?? "",
                    title: j["title"] as? String ?? "",
                    subtitle: j["subtitle"] as? String ?? "",
                    meta: j["meta"] as? String ?? "",
                    value: j["value"] as? String ?? "",
                    glyph: j["glyph"] as? String ?? "•",
                    updatedAt: j["updatedAt"] as? String ?? "",
                    bearing: j["bearing"] as? Double,
                    bearingLabel: j["bearingLabel"] as? String,
                    arrow: j["arrow"] as? String
                ))
            }
        }
        if cards.isEmpty { cards = placeholder(in: context).cards }
        let entry = OrbitEntry(date: Date(), cards: cards, updatedAt: updated)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct OrbitWidgetView: View {
    var entry: OrbitEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("O").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    .frame(width: 22, height: 22).background(Color(red: 0.06, green: 0.30, blue: 0.27)).cornerRadius(6)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ORBIT • Swipeable").font(.system(size: 11, weight: .semibold))
                    Text("\(entry.cards.count) cards • \(entry.updatedAt.suffix(5))")
                        .font(.system(size: 9)).foregroundColor(.gray)
                }
                Spacer()
                // Qibla quick compass badge in header shows first qibla bearing if present
                if let q = entry.cards.first(where: { $0.type == "qibla" || $0.bearing != nil }) {
                    HStack(spacing: 3) {
                        Text(q.arrow ?? "⌖").font(.system(size: 11, weight: .bold)).foregroundColor(Color(red: 0.06, green: 0.30, blue: 0.27))
                        Text(q.bearingLabel ?? "").font(.system(size: 9, weight: .semibold)).foregroundColor(Color(red: 0.06, green: 0.30, blue: 0.27))
                    }.padding(.horizontal, 6).padding(.vertical, 3).background(Color(red: 0.90, green: 0.94, blue: 0.93)).cornerRadius(999)
                }
                Text("↻").font(.system(size: 10)).foregroundColor(.gray)
                    .frame(width: 24, height: 24).background(Color.white).cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2)))
            }.padding(.bottom, 6)

            TabView {
                ForEach(entry.cards.indices, id: \.self) { i in
                    let c = entry.cards[i]
                    let isQibla = c.type == "qibla" || c.bearing != nil
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7).fill(Color(red: 0.12, green: 0.12, blue: 0.11))
                                Text(c.glyph).font(.system(size: 13)).foregroundColor(.white)
                                // compass ring overlay for qibla
                                if isQibla {
                                    Circle().stroke(Color.white.opacity(0.5), lineWidth: 1).frame(width: 22, height: 22)
                                }
                            }.frame(width: 26, height: 26)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(c.type.capitalized).font(.system(size: 11, weight: .bold))
                                Text(c.subtitle).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                            }
                            Spacer()
                            if isQibla, let lbl = c.bearingLabel, let arr = c.arrow {
                                HStack(spacing: 3) {
                                    Text(arr).font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 0.06, green: 0.30, blue: 0.27))
                                    Text(lbl).font(.system(size: 9, weight: .bold)).foregroundColor(Color(red: 0.06, green: 0.30, blue: 0.27))
                                }.padding(.horizontal, 7).padding(.vertical, 3).background(Color(red: 0.90, green: 0.94, blue: 0.93)).cornerRadius(999)
                            } else {
                                Text(c.meta).font(.system(size: 8)).foregroundColor(.gray).padding(.horizontal, 6).padding(.vertical, 3).background(Color.gray.opacity(0.12)).cornerRadius(999).lineLimit(1)
                            }
                        }
                        Text(c.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Text(c.meta).font(.system(size: 10)).foregroundColor(.gray).lineLimit(1)
                        Spacer(minLength: 2)
                        HStack(spacing: 4) {
                            // large arrow for qibla card
                            if isQibla, let arr = c.arrow {
                                Text(arr).font(.system(size: 16, weight: .bold)).foregroundColor(Color(red: 0.06, green: 0.30, blue: 0.27))
                                    .frame(width: 28, height: 28).background(Color(red: 0.90, green: 0.94, blue: 0.93)).cornerRadius(8)
                            }
                            Text(c.value).font(.system(size: 10, weight: .medium)).foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.11)).lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(.gray)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.95))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15)))
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                    .padding(.horizontal, 1)
                }
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            Text("Swipe left/right • Tap to open • Qibla live \(entry.cards.first(where: { $0.bearing != nil })?.bearingLabel ?? "—")")
                .font(.system(size: 8)).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
        }
        .padding(8)
        .background(Color(red: 0.96, green: 0.96, blue: 0.95))
        .widgetURL(URL(string: "orbit://open"))
    }
}

@main
struct OrbitWidget: Widget {
    let kind = "OrbitWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrbitProvider()) { entry in OrbitWidgetView(entry: entry) }
            .configurationDisplayName("ORBIT")
            .description("Swipeable 4×2 • Namaz • Qibla compass • Space • News • Jobs • Weather")
            .supportedFamilies([.systemMedium, .systemLarge])
    }
}
extension String { var capitalized: String { prefix(1).uppercased() + dropFirst() } }
