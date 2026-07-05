import SwiftUI
import Charts

struct StepChartsView: View {
    let mode: MetricMode
    @EnvironmentObject var hk: HealthKitManager

    private var weekData:  [(date: Date, value: Double)] { mode == .steps ? hk.weekDailySteps  : hk.weekDailyHR  }
    private var monthData: [(date: Date, value: Double)] { mode == .steps ? hk.monthDailySteps : hk.monthDailyHR }
    private var yearData:  [(date: Date, value: Double)] { mode == .steps ? hk.yearMonthlySteps : hk.yearMonthlyHR }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Tron.bg.ignoresSafeArea()

                if weekData.isEmpty && monthData.isEmpty {
                    ProgressView().tint(mode.accent)
                } else {
                    let available = geo.size.height - 56 - 40 // top tag + bottom dots
                    let chartH    = available / 3 - 24        // minus label

                    VStack(spacing: 0) {
                        modeTag.padding(.top, 56).padding(.bottom, 4)

                        chartPanel(title: "LAST 7 DAYS",    data: weekData,  chartH: chartH, xFmt: shortDay)
                        TronDivider()
                        chartPanel(title: "LAST 30 DAYS",   data: monthData, chartH: chartH, xFmt: shortDate)
                        TronDivider()
                        chartPanel(title: "LAST 12 MONTHS", data: yearData,  chartH: chartH, xFmt: shortMonth)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }

    private var modeTag: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon).font(.caption)
            Text("CHARTS  ·  \(mode.label)").font(.caption.monospaced()).tracking(2)
        }
        .foregroundStyle(mode.accent)
        .tronGlow(color: mode.accent, radius: 4)
    }

    private func chartPanel(
        title: String,
        data: [(date: Date, value: Double)],
        chartH: CGFloat,
        xFmt: @escaping (Date) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(mode.dimAccent)
                .tracking(3)
                .padding(.horizontal, 16)

            let maxVal = max(data.map(\.value).max() ?? 1, 1)

            Chart(data, id: \.date) { item in
                BarMark(
                    x: .value("Date", xFmt(item.date)),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(colors: [mode.dimAccent, mode.accent], startPoint: .bottom, endPoint: .top)
                )
                .cornerRadius(2)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: maxVal / 3)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Tron.rule)
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(compact(v))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(mode.dimAccent.opacity(0.9))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let s = val.as(String.self) {
                            Text(s)
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(mode.dimAccent.opacity(0.9))
                        }
                    }
                }
            }
            .chartPlotStyle { $0.background(Tron.bgCard) }
            .frame(height: chartH)
            .padding(.horizontal, 12)
        }
        .padding(.top, 8)
    }

    private func shortDay(_ d: Date) -> String   { DateFormatter().then { $0.dateFormat = "EEE" }.string(from: d) }
    private func shortDate(_ d: Date) -> String  { DateFormatter().then { $0.dateFormat = "M/d"  }.string(from: d) }
    private func shortMonth(_ d: Date) -> String { DateFormatter().then { $0.dateFormat = "MMM"  }.string(from: d) }
    private func compact(_ v: Double) -> String  { v >= 1000 ? String(format: "%.0fk", v/1000) : String(format: "%.0f", v) }
}

private extension DateFormatter {
    func then(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self); return self
    }
}
