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
            await requestPermissions()
            startStreaming()
            await refreshMetrics()
        }
    }

    func requestPermissions() async {
        await healthKitManager.requestAuthorization()
    }

    func startStreaming() {
        healthKitManager.startHeartRateUpdates()
        motionManager.startUpdates()
    }

    func stopStreaming() {
        healthKitManager.stopHeartRateUpdates()
        motionManager.stopUpdates()
    }

    func refreshMetrics() async {
        let todayMetrics = await buildDailyMetrics()
        metrics = todayMetrics
        await dataStore.save(metrics: todayMetrics)
        log(SyncEvent(type: .dataPersistence, message: "Persisted metrics for \(todayMetrics.date.formatted(.dateTime.month().day()))"))
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
