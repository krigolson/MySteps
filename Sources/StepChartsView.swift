import SwiftUI
import Charts

struct StepChartsView: View {
    @EnvironmentObject var hk: HealthKitManager

    var body: some View {
        ZStack {
            Tron.bg.ignoresSafeArea()

            if hk.weekDailySteps.isEmpty && hk.monthDailySteps.isEmpty {
                ProgressView().tint(Tron.cyan)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        chartSection(
                            title: "LAST 7 DAYS",
                            data: hk.weekDailySteps,
                            xLabel: { d in shortDay(d) },
                            isTop: true
                        )
                        TronDivider()
                        chartSection(
                            title: "LAST 30 DAYS",
                            data: hk.monthDailySteps,
                            xLabel: { d in shortDate(d) },
                            isTop: false
                        )
                        TronDivider()
                        chartSection(
                            title: "LAST 12 MONTHS",
                            data: hk.yearMonthlySteps,
                            xLabel: { d in shortMonth(d) },
                            isTop: false
                        )
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }

    // MARK: - Section Builder

    private func chartSection(
        title: String,
        data: [(date: Date, steps: Double)],
        xLabel: @escaping (Date) -> String,
        isTop: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.monospaced())
                .tracking(4)
                .foregroundStyle(Tron.dimCyan)

            let maxVal = data.map(\.steps).max() ?? 1

            Chart(data, id: \.date) { item in
                BarMark(
                    x: .value("Date", xLabel(item.date)),
                    y: .value("Steps", item.steps)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Tron.blue, Tron.cyan],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(2)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: maxVal / 3)) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Tron.rule)
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text(compactSteps(v))
                                .font(.caption2.monospaced())
                                .foregroundStyle(Tron.dimCyan.opacity(0.8))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { val in
                    AxisValueLabel {
                        if let s = val.as(String.self) {
                            Text(s)
                                .font(.caption2.monospaced())
                                .foregroundStyle(Tron.dimCyan.opacity(0.8))
                        }
                    }
                }
            }
            .chartPlotStyle { plot in
                plot.background(Tron.bgCard)
            }
            .frame(height: 140)
        }
        .padding(.horizontal, 16)
        .padding(.top, isTop ? 56 : 20)
        .padding(.bottom, 16)
    }

    // MARK: - Formatters

    private func shortDay(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date)
    }
    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "M/d"; return f.string(from: date)
    }
    private func shortMonth(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: date)
    }
    private func compactSteps(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.0fk", v / 1000) : String(format: "%.0f", v)
    }
}
