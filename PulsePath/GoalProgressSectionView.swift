import SwiftUI

struct GoalProgressSectionView: View {
    let metrics: DailyMetrics

    var body: some View {
        SectionCard(title: "Daily Goals", subtitle: "Track progress on every pillar of your day.", icon: "target") {
            ForEach(ActivityGoal.allCases) { goal in
                GoalProgressRow(goal: goal, metrics: metrics)
                    .padding(.vertical, 4)
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
