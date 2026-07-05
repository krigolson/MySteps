import SwiftUI

struct ContentView: View {
    @StateObject private var hk = HealthKitManager()
    @State private var mode: MetricMode = .steps
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            Tron.bg.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                MainStatsView(mode: mode).tag(0)
                FunStatsView(mode: mode).tag(1)
                StepChartsView(mode: mode).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.3), value: mode)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { val in
                    let v = abs(val.translation.height)
                    let h = abs(val.translation.width)
                    guard v > h, v > 60 else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if val.translation.height < 0 {
                            mode = .heartRate
                        } else {
                            mode = .steps
                        }
                    }
                }
        )
        .environmentObject(hk)
        .task { await hk.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await hk.refresh() }
        }
        .overlay {
            if hk.authDenied { DeniedView() }
        }
        .preferredColorScheme(.dark)
    }
}

private struct DeniedView: View {
    var body: some View {
        ZStack {
            Tron.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "figure.walk.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(Tron.cyan)
                    .tronGlow()
                Text("HEALTH ACCESS REQUIRED")
                    .font(.headline.monospaced())
                    .foregroundStyle(Tron.cyan)
                    .tronGlow()
                Text("Enable Step Count & Resting Heart Rate in\nSettings → Privacy & Security → Health")
                    .font(.callout)
                    .foregroundStyle(Tron.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button("OPEN SETTINGS") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline.monospaced())
                .foregroundStyle(Tron.bg)
                .padding(.horizontal, 28).padding(.vertical, 10)
                .background(Tron.cyan)
                .cornerRadius(4)
                .tronGlow()
            }
            .padding()
        }
    }
}
