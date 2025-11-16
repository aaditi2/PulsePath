import SwiftUI

struct ActivityTypeSectionView: View {
    let activityType: String

    var body: some View {
        SectionCard(title: "Current Activity", subtitle: "Automatically detected by Motion", icon: "figure.run") {
            VStack(alignment: .leading, spacing: 12) {
                Text(activityType)
                    .font(.title2.bold())
                Text("Streaming live from your iPhone's motion sensors. Connect an Apple Watch anytime for richer context.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
