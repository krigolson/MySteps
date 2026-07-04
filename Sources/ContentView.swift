import SwiftUI

struct ContentView: View {
    @StateObject private var hk = HealthKitManager()

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top half — 7-day average
                statPanel(
                    period: "Last 7 Days",
                    value: hk.sevenDayAvg,
                    valueFontSize: 72
                )
                .frame(height: geo.size.height * 0.50)
                .background(Color(.systemBackground))

                Divider()

                // Second quarter — 30-day average
                statPanel(
                    period: "Last 30 Days",
                    value: hk.thirtyDayAvg,
                    valueFontSize: 44
                )
                .frame(height: geo.size.height * 0.25)
                .background(Color(.secondarySystemBackground))

                Divider()

                // Third quarter — 365-day average
                statPanel(
                    period: "Last 365 Days",
                    value: hk.yearAvg,
                    valueFontSize: 44
                )
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .topTrailing) {
            if let updated = hk.lastUpdated {
                Text("Updated \(updated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
        }
        .overlay {
            if hk.authDenied {
                deniedOverlay
            }
        }
        .task { await hk.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await hk.refresh() }
        }
    }

    private func statPanel(period: String, value: Double?, valueFontSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(period)
                .font(.headline)
                .foregroundStyle(.secondary)
            if let value {
                Text(Int(value.rounded()).formatted())
                    .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            } else {
                ProgressView().scaleEffect(1.2)
            }
            Text("avg steps / day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedOverlay: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "figure.walk.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Health Access Required")
                    .font(.title3.bold())
                Text("Allow MySteps to read Step Count in Settings → Privacy & Security → Health.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
