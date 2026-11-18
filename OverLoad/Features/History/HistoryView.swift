import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    var body: some View {
        NavigationStack {
            List(sessions) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.name).font(.headline)
                        if let duration = session.duration {
                            Label(WorkoutDuration.formatted(duration), systemImage: "timer")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(session.date, format: .dateTime.month().day().year().hour().minute())
                        Text("\(session.sets.count) sets · \(HistoryViewModel.volume(session), specifier: "%g") lb·reps")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.overlay {
                if sessions.isEmpty {
                    ContentUnavailableView("No workouts yet", systemImage: "clock",
                                           description: Text("Finish a session to see it here."))
                }
            }.navigationTitle("History")
        }
    }
}

#Preview { HistoryView().modelContainer(SampleData.preview()) }
