import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    private var refreshTimer: Timer?

    @Published var sevenDayAvg:   Double? = nil
    @Published var thirtyDayAvg:  Double? = nil
    @Published var yearAvg:       Double? = nil
    @Published var lastUpdated:   Date?   = nil
    @Published var authDenied:    Bool    = false

    init() {
        requestAuthorization()
    }

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
        sevenDayAvg  = await s7
        thirtyDayAvg = await s30
        yearAvg      = await s365
        lastUpdated  = Date()
    }

    private func avgStepsPerDay(days: Int) async -> Double? {
        let stepType = HKQuantityType(.stepCount)
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!

        return await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                guard let sum = stats?.sumQuantity() else {
                    cont.resume(returning: nil)
                    return
                }
                cont.resume(returning: sum.doubleValue(for: .count()) / Double(days))
            }
            store.execute(query)
        }
    }

    private func scheduleHourlyRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }

    deinit { refreshTimer?.invalidate() }
}
