import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    private var refreshTimer: Timer?

    // Steps averages
    @Published var sevenDayAvg:   Double? = nil
    @Published var thirtyDayAvg:  Double? = nil
    @Published var yearAvg:       Double? = nil

    // Heart rate averages (BPM)
    @Published var sevenDayAvgHR:  Double? = nil
    @Published var thirtyDayAvgHR: Double? = nil
    @Published var yearAvgHR:      Double? = nil

    // Step series for charts
    @Published var weekDailySteps:   [(date: Date, value: Double)] = []
    @Published var monthDailySteps:  [(date: Date, value: Double)] = []
    @Published var yearMonthlySteps: [(date: Date, value: Double)] = []

    // HR series for charts
    @Published var weekDailyHR:   [(date: Date, value: Double)] = []
    @Published var monthDailyHR:  [(date: Date, value: Double)] = []
    @Published var yearMonthlyHR: [(date: Date, value: Double)] = []

    @Published var lastUpdated: Date? = nil
    @Published var authDenied:  Bool  = false

    private let bpmUnit = HKUnit.count().unitDivided(by: .minute())

    init() { requestAuthorization() }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.restingHeartRate)
        ]
        store.requestAuthorization(toShare: nil, read: types) { [weak self] granted, _ in
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
        async let s7    = avgStepsPerDay(days: 7)
        async let s30   = avgStepsPerDay(days: 30)
        async let s365  = avgStepsPerDay(days: 365)
        async let hr7   = avgRestingHR(days: 7)
        async let hr30  = avgRestingHR(days: 30)
        async let hr365 = avgRestingHR(days: 365)
        async let wkS   = dailyStepSeries(days: 7)
        async let moS   = dailyStepSeries(days: 30)
        async let yrS   = monthlyStepSeries(months: 12)
        async let wkH   = dailyHRSeries(days: 7)
        async let moH   = dailyHRSeries(days: 30)
        async let yrH   = monthlyHRSeries(months: 12)

        sevenDayAvg   = await s7
        thirtyDayAvg  = await s30
        yearAvg       = await s365
        sevenDayAvgHR  = await hr7
        thirtyDayAvgHR = await hr30
        yearAvgHR      = await hr365
        weekDailySteps  = await wkS
        monthDailySteps = await moS
        yearMonthlySteps = await yrS
        weekDailyHR  = await wkH
        monthDailyHR = await moH
        yearMonthlyHR = await yrH
        lastUpdated = Date()
    }

    // MARK: - Step Queries

    private func avgStepsPerDay(days: Int) async -> Double? {
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let pred  = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(
                quantityType: HKQuantityType(.stepCount),
                quantitySamplePredicate: pred,
                options: .cumulativeSum
            ) { _, stats, _ in
                guard let sum = stats?.sumQuantity() else { cont.resume(returning: nil); return }
                cont.resume(returning: sum.doubleValue(for: .count()) / Double(days))
            }
            store.execute(q)
        }
    }

    private func dailyStepSeries(days: Int) async -> [(date: Date, value: Double)] {
        await dailySeries(type: HKQuantityType(.stepCount), option: .cumulativeSum, days: days) {
            $0.sumQuantity()?.doubleValue(for: .count()) ?? 0
        }
    }

    private func monthlyStepSeries(months: Int) async -> [(date: Date, value: Double)] {
        await monthlySeries(type: HKQuantityType(.stepCount), option: .cumulativeSum, months: months) {
            $0.sumQuantity()?.doubleValue(for: .count()) ?? 0
        }
    }

    // MARK: - Heart Rate Queries

    private func avgRestingHR(days: Int) async -> Double? {
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let pred  = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { [bpmUnit] cont in
            let q = HKStatisticsQuery(
                quantityType: HKQuantityType(.restingHeartRate),
                quantitySamplePredicate: pred,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let avg = stats?.averageQuantity() else { cont.resume(returning: nil); return }
                cont.resume(returning: avg.doubleValue(for: bpmUnit))
            }
            store.execute(q)
        }
    }

    private func dailyHRSeries(days: Int) async -> [(date: Date, value: Double)] {
        await dailySeries(type: HKQuantityType(.restingHeartRate), option: .discreteAverage, days: days) { [self] stat in
            stat.averageQuantity()?.doubleValue(for: bpmUnit) ?? 0
        }
    }

    private func monthlyHRSeries(months: Int) async -> [(date: Date, value: Double)] {
        await monthlySeries(type: HKQuantityType(.restingHeartRate), option: .discreteAverage, months: months) { [self] stat in
            stat.averageQuantity()?.doubleValue(for: bpmUnit) ?? 0
        }
    }

    // MARK: - Generic Collection Helpers

    private func dailySeries(
        type: HKQuantityType,
        option: HKStatisticsOptions,
        days: Int,
        extract: @escaping (HKStatistics) -> Double
    ) async -> [(date: Date, value: Double)] {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -days + 1, to: today)!
        let end   = cal.date(byAdding: .day, value: 1, to: today)!
        var interval = DateComponents(); interval.day = 1
        return await collectionQuery(type: type, option: option, start: start, end: end, interval: interval, extract: extract)
    }

    private func monthlySeries(
        type: HKQuantityType,
        option: HKStatisticsOptions,
        months: Int,
        extract: @escaping (HKStatistics) -> Double
    ) async -> [(date: Date, value: Double)] {
        let cal  = Calendar.current
        let now  = Date()
        let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let start = cal.date(byAdding: .month, value: -months + 1, to: thisMonth)!
        let end   = cal.date(byAdding: .month, value: 1, to: thisMonth)!
        var interval = DateComponents(); interval.month = 1
        return await collectionQuery(type: type, option: option, start: start, end: end, interval: interval, extract: extract)
    }

    private func collectionQuery(
        type: HKQuantityType,
        option: HKStatisticsOptions,
        start: Date, end: Date,
        interval: DateComponents,
        extract: @escaping (HKStatistics) -> Double
    ) async -> [(date: Date, value: Double)] {
        await withCheckedContinuation { cont in
            let q = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: nil,
                options: option,
                anchorDate: start,
                intervalComponents: interval
            )
            q.initialResultsHandler = { _, collection, _ in
                guard let collection else { cont.resume(returning: []); return }
                var out: [(date: Date, value: Double)] = []
                collection.enumerateStatistics(from: start, to: end) { stat, _ in
                    out.append((date: stat.startDate, value: extract(stat)))
                }
                cont.resume(returning: out)
            }
            self.store.execute(q)
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
