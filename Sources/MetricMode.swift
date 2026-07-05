import SwiftUI

enum MetricMode: String, CaseIterable {
    case steps
    case heartRate

    var label: String {
        switch self {
        case .steps:     return "STEPS"
        case .heartRate: return "HEART RATE"
        }
    }

    var unit: String {
        switch self {
        case .steps:     return "avg steps / day"
        case .heartRate: return "avg BPM"
        }
    }

    var icon: String {
        switch self {
        case .steps:     return "figure.walk"
        case .heartRate: return "heart.fill"
        }
    }

    var accent: Color {
        switch self {
        case .steps:     return Color(red: 0.00, green: 0.88, blue: 1.00)  // cyan
        case .heartRate: return Color(red: 0.95, green: 0.12, blue: 0.40)  // neon magenta
        }
    }

    var dimAccent: Color {
        switch self {
        case .steps:     return Color(red: 0.00, green: 0.55, blue: 0.65)
        case .heartRate: return Color(red: 0.60, green: 0.10, blue: 0.28)
        }
    }
}
