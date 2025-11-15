import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    goalSelector
                    goalProgressSection
                    heartRateSection
                    activityTypeSection
                    insightsSection
                    diagnosticsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PulsePath")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.refreshMetrics() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh metrics")
                }
            }
        }
        .task { await viewModel.refreshMetrics() }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.startStreaming()
            case .background, .inactive:
                viewModel.stopStreaming()
            @unknown default:
                break
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.largeTitle.bold())
            if let heartRate = viewModel.metrics.heartRate {
                Text("Current heart rate: \(Int(heartRate)) bpm")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Waiting for heart rate data…")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var goalSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityGoal.allCases) { goal in
                    Button {
                        withAnimation { viewModel.activeGoal = goal }
                    } label: {
                        Text(goal.displayName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(goal == viewModel.activeGoal ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                            .foregroundStyle(goal == viewModel.activeGoal ? Color.accentColor : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Goals")
                .font(.title3.bold())

            ForEach(ActivityGoal.allCases) { goal in
                GoalProgressRow(goal: goal, metrics: viewModel.metrics)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Rate")
                .font(.title3.bold())
            if viewModel.metrics.heartRateSamples.isEmpty {
                Text("No heart rate data yet. Grant Health permissions to begin tracking.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            } else {
                Chart(viewModel.metrics.heartRateSamples) { sample in
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value("BPM", sample.bpm)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.red)
                }
                .frame(height: 180)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var activityTypeSection: some View {
        HStack {
            Image(systemName: "figure.walk")
                .font(.system(size: 28))
                .foregroundStyle(.accent)
            VStack(alignment: .leading) {
                Text("Current Activity")
                    .font(.headline)
                Text(viewModel.activityType)
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.title3.bold())
            if viewModel.insights.isEmpty {
                Text("We'll surface trends once we have more data.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.headline)
                        Text(insight.message)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostics")
                .font(.title3.bold())
            if viewModel.diagnostics.isEmpty {
                Text("No sync events yet. We'll record HealthKit and CoreMotion activity here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.diagnostics) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.type.rawValue.capitalized)
                                .font(.headline)
                            Text(event.message)
                                .foregroundStyle(.secondary)
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct GoalProgressRow: View {
    let goal: ActivityGoal
    let metrics: DailyMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.displayName)
                    .font(.headline)
                Spacer()
                Text(goal.formattedValue(metrics.value(for: goal)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: metrics.progress(for: goal))
                .tint(.accentColor)
            Text(String(format: "%.0f%% of goal", metrics.progress(for: goal) * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
