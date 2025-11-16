import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color(red: 0.11, green: 0.14, blue: 0.32),
                                    Color(red: 0.07, green: 0.07, blue: 0.15)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

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
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("PulsePath")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await viewModel.refreshMetrics() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            // App launch work moved OUT of ViewModel.init()
            await viewModel.requestPermissions()
            await viewModel.refreshMetrics()
        }
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

    // MARK: UI Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PulsePath")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Your daily rhythm, reimagined like Apple's Health experience.")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Mindful Readiness")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))

                if let heartRate = viewModel.metrics.heartRate {
                    Text("Current heart rate: \(Int(heartRate)) bpm")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("Heart rate requires Apple Watch sensors. With just your iPhone, live BPM isn't available yet.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.3))

            HStack(spacing: 16) {
                heroStat(icon: "flame.fill", title: "Steps", value: viewModel.metrics.formattedSteps)
                heroStat(icon: "figure.run.circle.fill", title: "Active", value: viewModel.metrics.formattedActiveMinutes)
                heroStat(icon: "arrow.triangle.branch", title: "Distance", value: viewModel.metrics.formattedDistance)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(colors: [Color(red: 0.87, green: 0.22, blue: 0.45),
                                    Color(red: 0.47, green: 0.19, blue: 0.57)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 12)
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
                            .background(
                                goal == viewModel.activeGoal ?
                                    LinearGradient(colors: [.pink.opacity(0.8), .orange.opacity(0.8)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing) :
                                    Color.white.opacity(0.08)
                            )
                            .foregroundStyle(goal == viewModel.activeGoal ?
                                             Color.white : Color.white.opacity(0.8))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var goalProgressSection: some View {
        SectionCard(title: "Daily Goals", subtitle: "Track progress on every pillar of your day.", icon: "target") {
            ForEach(ActivityGoal.allCases) { goal in
                GoalProgressRow(goal: goal, metrics: viewModel.metrics)
                    .padding(.vertical, 4)
            }
        }
    }

    private var heartRateSection: some View {
        SectionCard(title: "Heart Rate", subtitle: "A calm, cardiology-inspired view.", icon: "waveform.path.ecg") {
            if viewModel.metrics.heartRateSamples.isEmpty {
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
            } else {
                Chart(viewModel.metrics.heartRateSamples) { sample in
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
    }

    private var activityTypeSection: some View {
        SectionCard(title: "Current Activity", subtitle: "Automatically detected by Motion", icon: "figure.run") {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.activityType)
                    .font(.title2.bold())
                Text("Streaming live from your iPhone's motion sensors. Connect an Apple Watch anytime for richer context.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var insightsSection: some View {
        SectionCard(title: "Insights", subtitle: "Thoughtful nudges curated from your metrics.", icon: "sparkles") {
            if viewModel.insights.isEmpty {
                Text("We'll surface trends once we have more data.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.insights) { insight in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.title)
                                .font(.headline)
                            Text(insight.message)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var diagnosticsSection: some View {
        SectionCard(title: "Diagnostics", subtitle: "Live system awareness for peace of mind.", icon: "waveform") {
            if viewModel.diagnostics.isEmpty {
                Text("No diagnostics to report. Everything looks healthy.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.diagnostics) { event in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(Color.pink)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.type.rawValue.capitalized)
                                    .font(.headline)
                                Text(event.message)
                                    .foregroundStyle(.secondary)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
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
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: metrics.progress(for: goal))
                .tint(.pink)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            Text(String(format: "%.0f%% of goal", metrics.progress(for: goal) * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private extension DailyMetrics {
    var formattedSteps: String {
        ActivityGoal.steps.formattedValue(stepCount)
    }

    var formattedActiveMinutes: String {
        ActivityGoal.activeMinutes.formattedValue(activeMinutes)
    }

    var formattedDistance: String {
        ActivityGoal.distance.formattedValue(distance)
    }
}

private extension ContentView {
    func heroStat(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    struct SectionCard<Content: View>: View {
        let title: String
        var subtitle: String?
        var icon: String?
        let content: Content

        init(title: String, subtitle: String? = nil, icon: String? = nil, @ViewBuilder content: () -> Content) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.headline)
                            .foregroundStyle(.pink)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3.bold())
                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }

                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
