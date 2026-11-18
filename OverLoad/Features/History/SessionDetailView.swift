import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    var body: some View {
        List {
            Text(session.date, format: .dateTime.month().day().year().hour().minute())
            StatCard(title: "Duration", value: session.duration.map(WorkoutDuration.formatted) ?? "Not recorded")
            StatCard(title: "Total volume", value: "\(HistoryViewModel.volume(session).formatted()) lb·reps")
            ForEach(HistoryViewModel.groups(session)) { group in
                Section(group.exercise.name) {
                    ForEach(group.sets) { set in
                        Text("\(set.reps) reps × \(set.weight, specifier: "%g") lb")
                    }
                }
            }
        }.navigationTitle(session.name)
    }
}

#Preview {
    let container = SampleData.preview()
    let session = try! container.mainContext.fetch(FetchDescriptor<WorkoutSession>())[0]
    NavigationStack { SessionDetailView(session: session) }.modelContainer(container)
}
