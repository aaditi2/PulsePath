import Foundation

struct InsightGenerator {
    func generateInsights(from metrics: [DailyMetrics]) -> [Insight] {
        guard !metrics.isEmpty else { return [] }
        var insights: [Insight] = []
        if let cadenceInsight = mostActivePeriodInsight(from: metrics) {
            insights.append(cadenceInsight)
        }
        if let consistencyInsight = consistencyInsight(from: metrics) {
            insights.append(consistencyInsight)
        }
        if let heartRateInsight = restingHeartRateInsight(from: metrics) {
            insights.append(heartRateInsight)
        }
        return insights
    }

    private func mostActivePeriodInsight(from metrics: [DailyMetrics]) -> Insight? {
        var hourlyTotals: [Int: Double] = [:]
        for metric in metrics {
            for sample in metric.heartRateSamples {
                let hour = Calendar.current.component(.hour, from: sample.date)
                hourlyTotals[hour, default: 0] += sample.bpm
            }
        }
        guard let topHour = hourlyTotals.max(by: { $0.value < $1.value })?.key else { return nil }
        let hourRange = String(format: "%02d:00-%02d:00", topHour, (topHour + 1) % 24)
        return Insight(title: "Peak Heart Rate", message: "Your heart rate peaks around \(hourRange).", date: Date())
    }

    private func consistencyInsight(from metrics: [DailyMetrics]) -> Insight? {
        let stepCounts = metrics.map { $0.stepCount }
        guard let average = stepCounts.average else { return nil }
        let deviation = stepCounts.standardDeviation
        let message = deviation < average * 0.1 ? "Your activity is very consistent day to day." : "Your activity varies significantly; consider setting reminders."
        return Insight(title: "Activity Consistency", message: message, date: Date())
    }

    private func restingHeartRateInsight(from metrics: [DailyMetrics]) -> Insight? {
        let recentHeartRates = metrics.compactMap { $0.heartRate }
        guard let average = recentHeartRates.average else { return nil }
        let message = String(format: "Your average heart rate today is %.0f bpm.", average)
        return Insight(title: "Heart Rate Overview", message: message, date: Date())
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        let total = reduce(0, +)
        return total / Double(count)
    }

    var standardDeviation: Double {
        guard let mean = average, count > 1 else { return 0 }
        let variance = reduce(0) { $0 + pow($1 - mean, 2) } / Double(count - 1)
        return sqrt(variance)
    }
}
