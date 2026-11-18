import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    let selectedIDs: Set<UUID>
    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(WorkoutViewModel.matchingExercises(exercises, search: search)) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name).foregroundStyle(.primary)
                                Text(exercise.primary.rawValue.capitalized)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedIDs.contains(exercise.id) {
                                Label("Added", systemImage: "checkmark.circle.fill").font(.caption)
                            } else {
                                Image(systemName: "plus.circle")
                            }
                        }.padding(.vertical, 4)
                    }.disabled(selectedIDs.contains(exercise.id))
                }
            }
            .overlay {
                if WorkoutViewModel.matchingExercises(exercises, search: search).isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, prompt: "Exercise or muscle group")
            .navigationTitle("Pick Exercise")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    ExercisePickerView(selectedIDs: [], onSelect: { _ in }).modelContainer(SampleData.preview())
}
