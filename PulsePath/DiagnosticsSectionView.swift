import SwiftUI

struct DiagnosticsSectionView: View {
    let events: [SyncEvent]

    var body: some View {
        SectionCard(title: "Diagnostics", subtitle: "Live system awareness for peace of mind.", icon: "waveform") {
            if events.isEmpty {
                Text("No diagnostics to report. Everything looks healthy.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(events) { event in
                        DiagnosticsRow(event: event)
                    }
                }
            }
        }
    }
}

private struct DiagnosticsRow: View {
    let event: SyncEvent

    var body: some View {
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
