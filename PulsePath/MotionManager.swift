import Foundation
import CoreMotion

@MainActor
final class MotionManager: ObservableObject {
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()

    @Published private(set) var currentActivityType: String = "Unknown"
    @Published private(set) var stepCount: Double = 0
    @Published private(set) var distance: Double = 0
    @Published private(set) var activeMinutes: Double = 0

    private var lastPedometerTimestamp: Date?
    private var accumulatedActiveSeconds: TimeInterval = 0

    var onDiagnostics: ((SyncEvent) -> Void)?

    func startUpdates() {
        startPedometerUpdates()
        startActivityUpdates()
    }

    func stopUpdates() {
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
    }

    private func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else {
            onDiagnostics?(SyncEvent(type: .motionQuery, message: "Pedometer not available"))
            return
        }

        let startDate = Calendar.current.startOfDay(for: Date())
        pedometer.startUpdates(from: startDate) { [weak self] pedometerData, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in
                    self.onDiagnostics?(SyncEvent(type: .motionQuery, message: "Pedometer error: \(error.localizedDescription)"))
                }
                return
            }
            guard let data = pedometerData else { return }
            Task { @MainActor in
                self.stepCount = data.numberOfSteps.doubleValue
                if let distance = data.distance?.doubleValue {
                    self.distance = distance
                }
                self.updateActiveMinutes(with: data)
            }
        }
    }

    private func updateActiveMinutes(with data: CMPedometerData) {
        let cadence = data.currentCadence?.doubleValue ?? 0
        let isActive = cadence > 0 || data.numberOfSteps.intValue > 0
        let currentTimestamp = data.endDate
        if let previous = lastPedometerTimestamp {
            let delta = currentTimestamp.timeIntervalSince(previous)
            if isActive {
                accumulatedActiveSeconds += delta
            }
        }
        lastPedometerTimestamp = currentTimestamp
        activeMinutes = accumulatedActiveSeconds / 60
    }

    private func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            onDiagnostics?(SyncEvent(type: .motionQuery, message: "Motion activity not available"))
            return
        }

        activityManager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
            guard let self, let activity else { return }
            let type: String
            if activity.walking {
                type = "Walking"
            } else if activity.running {
                type = "Running"
            } else if activity.cycling {
                type = "Cycling"
            } else if activity.automotive {
                type = "Driving"
            } else if activity.stationary {
                type = "Stationary"
            } else {
                type = "Unknown"
            }
            Task { @MainActor in
                self.currentActivityType = type
            }
        }
        onDiagnostics?(SyncEvent(type: .motionQuery, message: "Started motion updates"))
    }
}
