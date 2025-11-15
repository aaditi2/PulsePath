import Foundation
import HealthKit

enum ActivityGoal: String, CaseIterable, Identifiable, Codable {
    case steps
    case activeMinutes
    case distance

    var id: String { rawValue }

    var targetValue: Double {
        switch self {
        case .steps:
            return 10_000
        case .activeMinutes:
            return 30
        case .distance:
            return 5_000 // meters (5 km)
        }
    }

    var displayName: String {
        switch self {
        case .steps:
            return "Steps"
        case .activeMinutes:
            return "Active Minutes"
        case .distance:
            return "Distance"
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .steps:
            return "\(Int(value)) steps"
        case .activeMinutes:
            return String(format: "%.0f min", value)
        case .distance:
            let kilometers = value / 1000
            return String(format: "%.2f km", kilometers)
        }
    }
}

struct HeartRateSample: Codable, Identifiable {
    var id = UUID()
    let bpm: Double
    let date: Date
}

struct DailyMetrics: Codable {
    var date: Date
    var stepCount: Double
    var distance: Double
    var activeMinutes: Double
    var heartRate: Double?
    var heartRateSamples: [HeartRateSample]

    static var empty: DailyMetrics {
        DailyMetrics(date: Date(), stepCount: 0, distance: 0, activeMinutes: 0, heartRate: nil, heartRateSamples: [])
    }

    func progress(for goal: ActivityGoal) -> Double {
        let value: Double
        switch goal {
        case .steps:
            value = stepCount
        case .activeMinutes:
            value = activeMinutes
        case .distance:
            value = distance
        }
        guard goal.targetValue > 0 else { return 0 }
        return min(1, value / goal.targetValue)
    }

    func value(for goal: ActivityGoal) -> Double {
        switch goal {
        case .steps:
            return stepCount
        case .activeMinutes:
            return activeMinutes
        case .distance:
            return distance
        }
    }
}

struct SyncEvent: Codable, Identifiable {
    enum EventType: String, Codable {
        case healthKitAuthorization
        case healthKitQuery
        case motionQuery
        case dataPersistence
        case diagnostics
    }

    let id: UUID
    let type: EventType
    let message: String
    let timestamp: Date

    init(type: EventType, message: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.message = message
        self.timestamp = timestamp
    }
}

struct Insight: Identifiable, Codable {
    let id: UUID
    let title: String
    let message: String
    let date: Date

    init(id: UUID = UUID(), title: String, message: String, date: Date = Date()) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
    }
}
