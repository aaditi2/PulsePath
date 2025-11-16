import SwiftUI

struct GoalSelectorView: View {
    @Binding var activeGoal: ActivityGoal

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityGoal.allCases) { goal in
                    Button {
                        withAnimation { activeGoal = goal }
                    } label: {
                        Text(goal.displayName)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                goal == activeGoal ?
                                    LinearGradient(colors: [.pink.opacity(0.8), .orange.opacity(0.8)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing) :
                                    Color.white.opacity(0.08)
                            )
                            .foregroundStyle(goal == activeGoal ?
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
}
