import SwiftUI

enum Tron {
    static let bg       = Color(red: 0.03, green: 0.05, blue: 0.12)
    static let bgCard   = Color(red: 0.06, green: 0.10, blue: 0.20)
    static let cyan     = Color(red: 0.00, green: 0.88, blue: 1.00)
    static let blue     = Color(red: 0.00, green: 0.45, blue: 1.00)
    static let dimCyan  = Color(red: 0.00, green: 0.55, blue: 0.65)
    static let text     = Color(red: 0.85, green: 0.97, blue: 1.00)
    static let rule     = Color(red: 0.00, green: 0.60, blue: 0.75).opacity(0.35)
}

extension View {
    func tronGlow(color: Color = Tron.cyan, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius)
    }

    func tronBackground() -> some View {
        self.background(Tron.bg.ignoresSafeArea())
    }
}

struct TronDivider: View {
    var body: some View {
        Rectangle()
            .fill(Tron.rule)
            .frame(height: 1)
            .tronGlow(color: Tron.dimCyan, radius: 4)
    }
}
