import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    private var refreshTimer: Timer?

    // Averages (screens 1 & 2)
    @Published var sevenDayAvg:   Double? = nil
    @Published var thirtyDayAvg:  Double? = nil
    @Published var yearAvg:       Double? = nil

    // Daily/monthly series for charts (screen 3)
    @Published var weekDailySteps:   [(date: Date, steps: Double)] = []
    @Published var monthDailySteps:  [(date: Date, steps: Double)] = []
    @Published var yearMonthlySteps: [(date: Date, steps: Double)] = []

    @Published var lastUpdated: Date? = nil
    @Published var authDenied:  Bool  = false

    init() { requestAuthorization() }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stepType = HKQuantityType(.stepCount)
        store.requestAuthorization(toShare: nil, read: [stepType]) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if granted {
                    await self.refresh()
                    self.scheduleHourlyRefresh()
                } else {
                    self.authDenied = true
                }
            }
        }
    }

    func refresh() async {
        async let s7   = avgStepsPerDay(days: 7)
        async let s30  = avgStepsPerDay(days: 30)
        async let s365 = avgStepsPerDay(days: 365)
        async let wk   = dailySeries(days: 7)
        async let mo   = dailySeries(days: 30)
        async let yr   = monthlySeries(months: 12)

        sevenDayAvg  = await s7
        thirtyDayAvg = await s30
        yearAvg      = await s365
        weekDailySteps   = await wk
        monthDailySteps  = await mo
        yearMonthlySteps = await yr
        lastUpdated  = Date()
    }

    // MARK: - Averages

    private func avgStepsPerDay(days: Int) async -> Double? {
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                guard let sum = stats?.sumQuantity() else { cont.resume(returning: nil); return }
                cont.resume(returning: sum.doubleValue(for: .count()) / Double(days))
            }
            store.execute(query)
        }
    }

    // MARK: - Daily Series

    private func dailySeries(days: Int) async -> [(date: Date, steps: Double)] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -days + 1, to: today)!
        let end   = cal.date(byAdding: .day, value: 1, to: today)!
        var interval = DateComponents(); interval.day = 1

        return await withCheckedContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, _ in
                guard let collection else { cont.resume(returning: []); return }
                var out: [(date: Date, steps: Double)] = []
                collection.enumerateStatistics(from: start, to: end) { stat, _ in
                    out.append((date: stat.startDate, steps: stat.sumQuantity()?.doubleValue(for: .count()) ?? 0))
                }
                cont.resume(returning: out)
            }
            store.execute(query)
        }
    }

    // MARK: - Monthly Series (last N months)

    private func monthlySeries(months: Int) async -> [(date: Date, steps: Double)] {
        let cal   = Calendar.current
        let now   = Date()
        let start = cal.date(byAdding: .month, value: -months + 1,
                             to: cal.date(from: cal.dateComponents([.year, .month], from: now))!)!
        let end   = cal.date(byAdding: .month, value: 1, to: cal.date(from: cal.dateComponents([.year, .month], from: now))!)!
        var interval = DateComponents(); interval.month = 1

        return await withCheckedContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, _ in
                guard let collection else { cont.resume(returning: []); return }
                var out: [(date: Date, steps: Double)] = []
                collection.enumerateStatistics(from: start, to: end) { stat, _ in
                    out.append((date: stat.startDate, steps: stat.sumQuantity()?.doubleValue(for: .count()) ?? 0))
                }
                cont.resume(returning: out)
            }
            store.execute(query)
        }
    }

    // MARK: - Timer

    private func scheduleHourlyRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }

    deinit { refreshTimer?.invalidate() }
}
