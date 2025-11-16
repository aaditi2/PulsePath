import SwiftUI

struct DashboardHeaderView: View {
    let metrics: DailyMetrics

    var body: some View {
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

                if let heartRate = metrics.heartRate {
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
                HeroStatView(icon: "flame.fill", title: "Steps", value: metrics.formattedSteps)
                HeroStatView(icon: "figure.run.circle.fill", title: "Active", value: metrics.formattedActiveMinutes)
                HeroStatView(icon: "arrow.triangle.branch", title: "Distance", value: metrics.formattedDistance)
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
}
