import SwiftUI

struct MainStatsView: View {
    let mode: MetricMode
    @EnvironmentObject var hk: HealthKitManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Tron.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    statBlock(label: "LAST 7 DAYS",   value: avg7,  fontSize: 80)
                        .frame(height: geo.size.height * 0.50)

                    TronDivider()

                    statBlock(label: "LAST 30 DAYS",  value: avg30, fontSize: 48)
                        .frame(height: geo.size.height * 0.25)
                        .background(Tron.bgCard)

                    TronDivider()

                    statBlock(label: "LAST 365 DAYS", value: avg365, fontSize: 48)
                        .frame(maxHeight: .infinity)
                        .background(Tron.bgCard)
                }
            }
        }
        .overlay(alignment: .top) { modeTag }
        .overlay(alignment: .bottomTrailing) {
            if let updated = hk.lastUpdated {
                Text("UPDATED \(updated, style: .relative) AGO")
                    .font(.caption2.monospaced())
                    .foregroundStyle(mode.dimAccent.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 40)
            }
        }
    }

    private var avg7:   Double? { mode == .steps ? hk.sevenDayAvg  : hk.sevenDayAvgHR  }
    private var avg30:  Double? { mode == .steps ? hk.thirtyDayAvg : hk.thirtyDayAvgHR }
    private var avg365: Double? { mode == .steps ? hk.yearAvg       : hk.yearAvgHR      }

    private var modeTag: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon).font(.caption)
            Text(mode.label).font(.caption.monospaced()).tracking(3)
            Text("↕").font(.caption2).foregroundStyle(mode.dimAccent)
            Image(systemName: mode == .steps ? "heart.fill" : "figure.walk").font(.caption)
                .foregroundStyle(mode.dimAccent)
        }
        .foregroundStyle(mode.accent)
        .padding(.top, 56)
        .tronGlow(color: mode.accent, radius: 4)
    }

    private func statBlock(label: String, value: Double?, fontSize: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.monospaced())
                .foregroundStyle(mode.dimAccent)
                .tracking(3)
            if let value {
                Text(formatValue(value))
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.accent)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .tronGlow(color: mode.accent)
            } else {
                ProgressView().tint(mode.accent)
            }
            Text(mode.unit)
                .font(.caption.monospaced())
                .foregroundStyle(Tron.text.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatValue(_ v: Double) -> String {
        mode == .steps ? Int(v.rounded()).formatted() : String(format: "%.0f", v)
    }
}
