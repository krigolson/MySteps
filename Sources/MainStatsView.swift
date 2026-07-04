import SwiftUI

struct MainStatsView: View {
    @EnvironmentObject var hk: HealthKitManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Tron.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top 50% — 7-day
                    statBlock(
                        label: "LAST 7 DAYS",
                        value: hk.sevenDayAvg,
                        fontSize: 80
                    )
                    .frame(height: geo.size.height * 0.50)

                    TronDivider()

                    // Middle 25% — 30-day
                    statBlock(
                        label: "LAST 30 DAYS",
                        value: hk.thirtyDayAvg,
                        fontSize: 48
                    )
                    .frame(height: geo.size.height * 0.25)
                    .background(Tron.bgCard)

                    TronDivider()

                    // Bottom 25% — 365-day
                    statBlock(
                        label: "LAST 365 DAYS",
                        value: hk.yearAvg,
                        fontSize: 48
                    )
                    .frame(maxHeight: .infinity)
                    .background(Tron.bgCard)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let updated = hk.lastUpdated {
                Text("UPDATED \(updated, style: .relative) AGO")
                    .font(.caption2.monospaced())
                    .foregroundStyle(Tron.dimCyan.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 40)
            }
        }
    }

    private func statBlock(label: String, value: Double?, fontSize: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.monospaced())
                .foregroundStyle(Tron.dimCyan)
                .tracking(3)
            if let value {
                Text(Int(value.rounded()).formatted())
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(Tron.cyan)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .tronGlow()
            } else {
                ProgressView().tint(Tron.cyan)
            }
            Text("avg steps / day")
                .font(.caption.monospaced())
                .foregroundStyle(Tron.text.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
