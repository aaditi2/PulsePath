import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?

    @Published private(set) var heartRateSamples: [HeartRateSample] = []
    @Published private(set) var latestHeartRate: Double?

    var onDiagnostics: ((SyncEvent) -> Void)?

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            onDiagnostics?(SyncEvent(type: .healthKitAuthorization, message: "Health data not available"))
            return
        }

        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .appleStandTime),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .stepCount)
        ].compactMap { $0 }

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            onDiagnostics?(SyncEvent(type: .healthKitAuthorization, message: "Authorization successful"))
        } catch {
            onDiagnostics?(SyncEvent(type: .healthKitAuthorization, message: "Authorization failed: \(error.localizedDescription)"))
        }
    }

    func startHeartRateUpdates() {
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)

        let query = HKAnchoredObjectQuery(type: heartRateType,
                                          predicate: predicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in
                    self.onDiagnostics?(SyncEvent(type: .healthKitQuery, message: "Query error: \(error.localizedDescription)"))
                }
                return
            }
            self.handle(samples: samples)
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in
                    self.onDiagnostics?(SyncEvent(type: .healthKitQuery, message: "Update error: \(error.localizedDescription)"))
                }
                return
            }
            self.handle(samples: samples)
        }

        healthStore.execute(query)
        heartRateQuery = query
        onDiagnostics?(SyncEvent(type: .healthKitQuery, message: "Started heart rate updates"))
    }

    func stopHeartRateUpdates() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
    }

    private func handle(samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }
        let heartRateUnit = HKUnit(from: "count/min")

        let newSamples = quantitySamples.map { sample in
            HeartRateSample(bpm: sample.quantity.doubleValue(for: heartRateUnit), date: sample.startDate)
        }

        Task { @MainActor in
            heartRateSamples.append(contentsOf: newSamples)
            heartRateSamples.sort { $0.date < $1.date }
            latestHeartRate = heartRateSamples.last?.bpm
        }
    }
}
