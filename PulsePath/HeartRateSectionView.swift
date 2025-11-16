import SwiftUI
import Charts

struct HeartRateSectionView: View {
    let metrics: DailyMetrics

    var body: some View {
        SectionCard(title: "Heart Rate", subtitle: "A calm, cardiology-inspired view.", icon: "waveform.path.ecg") {
            if metrics.heartRateSamples.isEmpty {
                EmptyStateView()
            } else {
                HeartRateChart(samples: metrics.heartRateSamples)
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("We're standing by for Apple Watch data.")
                .font(.headline)
            Text("PulsePath mirrors the Health app, but heart rate requires an Apple Watch sensor suite. Using only your iPhone means we can't capture BPM readings yet—connect a watch whenever you're ready.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HeartRateChart: View {
    let samples: [HeartRateSample]

    var body: some View {
        Chart(samples) { sample in
            LineMark(
                x: .value("Time", sample.date),
                y: .value("BPM", sample.bpm)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
            )
            AreaMark(
                x: .value("Time", sample.date),
                y: .value("BPM", sample.bpm)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.red.opacity(0.15))
        }
        .chartXAxis(.hidden)
        .chartYAxis { AxisMarks(position: .leading) }
        .frame(height: 200)
    }
}
