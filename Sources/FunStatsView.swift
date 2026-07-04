import SwiftUI

struct FunStatsView: View {
    @EnvironmentObject var hk: HealthKitManager

    private let mPerStep: Double = 0.762  // avg stride ~2.5 ft
    private let stepsPerMin: Double = 100

    private var yearTotal: Double { (hk.yearAvg ?? 0) * 365 }
    private var yearDistM: Double  { yearTotal * mPerStep }
    private var yearDistKm: Double { yearDistM / 1000 }

    private var stats: [FunStat] {
        let daily = hk.yearAvg ?? 0

        return [
            FunStat(
                icon: "🌙",
                title: "LUNAR ETA",
                value: yearsToMoon,
                unit: "years to walk to the Moon",
                flavor: "Distance: 384,400 km"
            ),
            FunStat(
                icon: "🌍",
                title: "EARTH LAPS",
                value: String(format: "%.2f", yearDistKm / 40_075),
                unit: "laps around Earth / year",
                flavor: "Circumference: 40,075 km"
            ),
            FunStat(
                icon: "🏃",
                title: "MARATHON PACE",
                value: String(format: "%.1f", yearDistM / 42_195),
                unit: "marathons / year",
                flavor: "42.195 km each"
            ),
            FunStat(
                icon: "🔥",
                title: "CALORIC BURN",
                value: Int(daily * 0.04).formatted(),
                unit: "cal / day from walking",
                flavor: "~0.04 kcal per step"
            ),
            FunStat(
                icon: "⏱️",
                title: "TIME ON FEET",
                value: String(format: "%.0f", daily / stepsPerMin),
                unit: "minutes walking / day",
                flavor: "At \(Int(stepsPerMin)) steps/min"
            ),
            FunStat(
                icon: "🗼",
                title: "EMPIRE STATE",
                value: Int(yearTotal / 1_860).formatted(),
                unit: "stair climbs / year",
                flavor: "1,860 steps to the top"
            ),
            FunStat(
                icon: "🌉",
                title: "GOLDEN GATES",
                value: String(format: "%.1f", yearDistM / 2_737),
                unit: "Golden Gate Bridges / year",
                flavor: "Span: 2,737 m"
            ),
            FunStat(
                icon: "👣",
                title: "LIFETIME FORECAST",
                value: String(format: "%.0f M", yearTotal * 50 / 1_000_000),
                unit: "steps in 50 years at this rate",
                flavor: "Average human: ~100 M lifetime"
            ),
        ]
    }

    private var yearsToMoon: String {
        guard yearTotal > 0 else { return "∞" }
        let stepsToMoon = 384_400_000.0 / mPerStep
        let years = stepsToMoon / yearTotal
        return years > 999 ? String(format: "%.0f k", years / 1000) : String(format: "%.0f", years)
    }

    var body: some View {
        ZStack {
            Tron.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("STEP ANALYSIS")
                        .font(.caption.monospaced())
                        .tracking(6)
                        .foregroundStyle(Tron.dimCyan)
                        .padding(.top, 56)
                        .padding(.bottom, 16)

                    if hk.yearAvg == nil {
                        ProgressView().tint(Tron.cyan).padding(.top, 60)
                    } else {
                        ForEach(stats) { stat in
                            StatCard(stat: stat)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Model

struct FunStat: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let unit: String
    let flavor: String
}

// MARK: - Card

private struct StatCard: View {
    let stat: FunStat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(stat.icon).font(.title2)
                Text(stat.title)
                    .font(.caption.monospaced())
                    .tracking(3)
                    .foregroundStyle(Tron.dimCyan)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(stat.value)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundStyle(Tron.cyan)
                    .tronGlow(radius: 6)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(stat.unit)
                    .font(.caption)
                    .foregroundStyle(Tron.text.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(stat.flavor)
                .font(.caption2.monospaced())
                .foregroundStyle(Tron.dimCyan.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Tron.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Tron.rule, lineWidth: 1)
                )
        )
        .padding(.bottom, 10)
    }
}
