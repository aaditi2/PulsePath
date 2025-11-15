import Foundation

actor ActivityDataStore {
    private let storageURL: URL
    private var cache: [String: DailyMetrics] = [:]

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        storageURL = directory.appendingPathComponent("dailyMetrics.json")
        Task {
            await load()
        }
    }

    func metrics(for date: Date) -> DailyMetrics {
        let key = Self.key(for: date)
        return cache[key] ?? DailyMetrics(date: Calendar.current.startOfDay(for: date), stepCount: 0, distance: 0, activeMinutes: 0, heartRate: nil, heartRateSamples: [])
    }

    func save(metrics: DailyMetrics) async {
        let key = Self.key(for: metrics.date)
        cache[key] = metrics
        await persist()
    }

    func allMetrics() -> [DailyMetrics] {
        cache.values.sorted { $0.date < $1.date }
    }

    func load() async {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([String: DailyMetrics].self, from: data)
            cache = decoded
        } catch {
            print("Failed to load metrics: \(error)")
        }
    }

    private func persist() async {
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to persist metrics: \(error)")
        }
    }

    private static func key(for date: Date) -> String {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return ISO8601DateFormatter().string(from: startOfDay)
    }
}
