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
                    DashboardHeaderView(metrics: viewModel.metrics)
                    GoalSelectorView(activeGoal: $viewModel.activeGoal)
                    GoalProgressSectionView(metrics: viewModel.metrics)
                    HeartRateSectionView(metrics: viewModel.metrics)
                    ActivityTypeSectionView(activityType: viewModel.activityType)
                    InsightsSectionView(insights: viewModel.insights)
                    DiagnosticsSectionView(events: viewModel.diagnostics)
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
}

// MARK: - Formatting Helpers

extension DailyMetrics {
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
