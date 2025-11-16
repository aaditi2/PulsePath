import SwiftUI

struct InsightsSectionView: View {
    let insights: [Insight]

    var body: some View {
        SectionCard(title: "Insights", subtitle: "Thoughtful nudges curated from your metrics.", icon: "sparkles") {
            if insights.isEmpty {
                Text("We'll surface trends once we have more data.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
    }
}

private struct InsightRow: View {
    let insight: Insight

    var body: some View {
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
