import SwiftUI

struct FunStatsView: View {
    let mode: MetricMode
    @EnvironmentObject var hk: HealthKitManager

    var body: some View {
        ZStack {
            Tron.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                modeTag.padding(.top, 56).padding(.bottom, 8)

                if dataReady {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                        ForEach(stats) { stat in
                            MiniStatCard(stat: stat, accent: mode.accent, dimAccent: mode.dimAccent)
                        }
                    }
                    .padding(.horizontal, 12)
                } else {
                    Spacer()
                    ProgressView().tint(mode.accent).scaleEffect(1.4)
                    Spacer()
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Mode tag

    private var modeTag: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon).font(.caption)
            Text("FUN STATS  ·  \(mode.label)").font(.caption.monospaced()).tracking(2)
        }
        .foregroundStyle(mode.accent)
        .tronGlow(color: mode.accent, radius: 4)
    }

    private var dataReady: Bool {
        mode == .steps ? hk.yearAvg != nil : hk.yearAvgHR != nil
    }

    // MARK: - Stats

    private var stats: [FunStat] {
        mode == .steps ? stepStats : heartRateStats
    }

    // MARK: Steps fun stats

    private let mPerStep: Double = 0.762

    private var yearStepTotal: Double { (hk.yearAvg ?? 0) * 365 }
    private var yearDistKm: Double    { yearStepTotal * mPerStep / 1000 }

    private var stepStats: [FunStat] {
        [
            FunStat("🌙", "LUNAR ETA",       yearsToMoon,                          "yrs to Moon"),
            FunStat("🌍", "EARTH LAPS",       f2(yearDistKm / 40_075),              "laps / year"),
            FunStat("🏃", "MARATHONS",        f1(yearDistKm * 1000 / 42_195),       "/ year"),
            FunStat("🔥", "CALORIES",         "\(Int((hk.yearAvg ?? 0) * 0.04))",   "cal / day"),
            FunStat("⏱️", "ACTIVE MINS",      "\(Int((hk.yearAvg ?? 0) / 100))",    "min / day"),
            FunStat("🗼", "EMPIRE STATE",     "\(Int(yearStepTotal / 1_860))",       "climbs / yr"),
            FunStat("🌉", "GOLDEN GATES",     f1(yearDistKm * 1000 / 2_737),        "/ year"),
            FunStat("👣", "50-YR FORECAST",   f0M(yearStepTotal * 50 / 1_000_000), "million steps"),
        ]
    }

    private var yearsToMoon: String {
        guard yearStepTotal > 0 else { return "∞" }
        let yrs = (384_400_000.0 / mPerStep) / yearStepTotal
        return yrs > 999 ? String(format: "%.0fk", yrs / 1000) : String(format: "%.0f", yrs)
    }

    // MARK: Heart rate fun stats

    private var rhr: Double { hk.yearAvgHR ?? 0 }
    private var beatsPerDay: Double { rhr * 60 * 24 }

    private var heartRateStats: [FunStat] {
        let tier: String = {
            switch rhr {
            case ..<40:  return "ELITE ATHLETE"
            case 40..<56: return "ATHLETIC"
            case 56..<71: return "GOOD"
            case 71..<86: return "AVERAGE"
            default:      return "ABOVE AVERAGE"
            }
        }()

        let tempo: String = {
            switch rhr {
            case ..<60:  return "SLOW BALLAD"
            case 60..<80: return "HIP-HOP"
            case 80..<100: return "POP"
            default:       return "DANCE/HOUSE"
            }
        }()

        return [
            FunStat("❤️",  "BEATS TODAY",      "\(Int(beatsPerDay).formatted())",       "beats / day"),
            FunStat("📅",  "ANNUAL BEATS",      f0M(beatsPerDay * 365 / 1_000_000),     "million / yr"),
            FunStat("🦅",  "VS HUMMINGBIRD",    f1(1200 / max(rhr, 1)),                 "× slower"),
            FunStat("🐘",  "VS ELEPHANT",       f1(max(rhr, 1) / 28),                   "× faster"),
            FunStat("🏋️", "FITNESS TIER",      tier,                                    ""),
            FunStat("💉",  "CARDIAC OUTPUT",    f1(max(rhr, 1) * 0.07),                 "L / min"),
            FunStat("🎵",  "MUSIC TEMPO",       tempo,                                   "@ \(Int(rhr)) BPM"),
            FunStat("🕰️", "50-YR HEARTBEATS",  f0M(beatsPerDay * 365 * 50 / 1_000_000_000) + " B", "billion beats"),
        ]
    }

    // MARK: - Format helpers

    private func f0M(_ v: Double) -> String { String(format: "%.0f", v) }
    private func f1(_ v: Double)  -> String { String(format: "%.1f", v) }
    private func f2(_ v: Double)  -> String { String(format: "%.2f", v) }
}

// MARK: - Model

struct FunStat: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let unit: String

    init(_ icon: String, _ title: String, _ value: String, _ unit: String) {
        self.icon  = icon
        self.title = title
        self.value = value
        self.unit  = unit
    }
}

// MARK: - Card

struct MiniStatCard: View {
    let stat: FunStat
    let accent: Color
    let dimAccent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(stat.icon).font(.subheadline)
                Text(stat.title)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(dimAccent)
                    .tracking(1)
                    .lineLimit(1)
            }
            Text(stat.value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .tronGlow(color: accent, radius: 5)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if !stat.unit.isEmpty {
                Text(stat.unit)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Tron.text.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Tron.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Tron.rule, lineWidth: 1))
        )
    }
}
