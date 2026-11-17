import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    var body: some View {
        List {
            StatCard(title: "Total volume", value: "\(HistoryViewModel.volume(session).formatted()) lb·reps")
            ForEach(HistoryViewModel.groups(session)) { group in
                Section(group.exercise.name) {
                    ForEach(group.sets) { set in
                        Text("\(set.reps) reps × \(set.weight, specifier: "%g") lb")
                    }
                }
            }
        }.navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
    }
}

#Preview {
    let container = SampleData.preview()
    let session = try! container.mainContext.fetch(FetchDescriptor<WorkoutSession>())[0]
    NavigationStack { SessionDetailView(session: session) }.modelContainer(container)
}
