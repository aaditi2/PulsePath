import Foundation

@MainActor
final class DiagnosticsLogger: ObservableObject {
    @Published private(set) var events: [SyncEvent] = []

    func record(_ event: SyncEvent) {
        events.append(event)
        events.sort { $0.timestamp > $1.timestamp }
    }
}
