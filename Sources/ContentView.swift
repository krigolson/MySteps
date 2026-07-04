import SwiftUI

struct ContentView: View {
    @StateObject private var hk = HealthKitManager()

    var body: some View {
        ZStack {
            Tron.bg.ignoresSafeArea()

            TabView {
                MainStatsView()
                FunStatsView()
                StepChartsView()
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
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
                Text("Enable Step Count in\nSettings → Privacy & Security → Health")
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
