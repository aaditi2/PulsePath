import Foundation
import HealthKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var metrics: DailyMetrics = .empty
    @Published var insights: [Insight] = []
    @Published var diagnostics: [SyncEvent] = []
    @Published var activeGoal: ActivityGoal = .steps
    @Published var activityType: String = "Unknown"

    private let healthKitManager = HealthKitManager()
    private let motionManager = MotionManager()
    private let dataStore = ActivityDataStore()
    private let diagnosticsLogger = DiagnosticsLogger()
    private let insightGenerator = InsightGenerator()

    init() {
        healthKitManager.onDiagnostics = { [weak self] event in
            Task { @MainActor in self?.log(event) }
        }
        motionManager.onDiagnostics = { [weak self] event in
            Task { @MainActor in self?.log(event) }
        }

        Task {
            await dataStore.load()

            /// Request HealthKit permissions FIRST
            let granted = await requestPermissions()

            if granted {
                /// Only start streaming AFTER permissions are granted
                startStreaming()
            } else {
                log(SyncEvent(type: .healthKitAuthorization,
                              message: "User denied HealthKit permissions"))
            }

            await refreshMetrics()
        }
    }


    // MARK: Requests

    func requestPermissions() async -> Bool {
        return await healthKitManager.requestAuthorization()
    }


    // MARK: Streaming

    func startStreaming() {
        healthKitManager.startHeartRateUpdates()
        motionManager.startUpdates()
    }

    func stopStreaming() {
        healthKitManager.stopHeartRateUpdates()
        motionManager.stopUpdates()
    }

    // MARK: Metrics

    func refreshMetrics() async {
        let today = await buildDailyMetrics()
        metrics = today
        await dataStore.save(metrics: today)
        log(SyncEvent(type: .dataPersistence, message: "Persisted metrics for \(today.date.formatted(.dateTime.month().day()))"))

        let history = await dataStore.allMetrics()
        insights = insightGenerator.generateInsights(from: history)
        log(SyncEvent(type: .diagnostics, message: "Generated \(insights.count) insights"))
    }

    private func buildDailyMetrics() async -> DailyMetrics {
        var snapshot = await dataStore.metrics(for: Date())
        snapshot.stepCount = motionManager.stepCount
        snapshot.distance = motionManager.distance
        snapshot.activeMinutes = motionManager.activeMinutes
        snapshot.heartRate = healthKitManager.latestHeartRate
        snapshot.heartRateSamples = healthKitManager.heartRateSamples
        activityType = motionManager.currentActivityType
        return snapshot
    }

    private func log(_ event: SyncEvent) {
        diagnosticsLogger.record(event)
        diagnostics = diagnosticsLogger.events
    }
}
