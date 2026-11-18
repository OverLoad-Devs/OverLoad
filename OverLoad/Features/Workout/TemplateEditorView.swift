import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var model: TemplateEditorViewModel
    @State private var showPicker = false

    init(template: WorkoutTemplate? = nil) {
        _model = State(initialValue: TemplateEditorViewModel(template: template))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout name") {
                    TextField("e.g. Pull", text: $model.name)
                }
                Section {
                    ForEach($model.exercises) { $entry in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(entry.exercise.name).font(.headline)
                            Stepper("\(entry.setCount) sets", value: $entry.setCount, in: 1...10)
                            Stepper("Target: \(entry.targetReps) reps", value: $entry.targetReps, in: 1...100)
                        }.padding(.vertical, 4)
                    }
                    .onDelete { model.exercises.remove(atOffsets: $0) }
                    .onMove { model.exercises.move(fromOffsets: $0, toOffset: $1) }
                    Button("Add exercise", systemImage: "plus.circle") { showPicker = true }
                } header: {
                    Text("Exercises")
                } footer: {
                    Text("Choose exercises in workout order. Swipe to remove or use Edit to reorder. Reps are a target; log your actual reps and weight when training.")
                }
                if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Workout Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if model.save(context: context) { dismiss() } }.disabled(!model.canSave)
                }
                ToolbarItem(placement: .bottomBar) { EditButton() }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView(selectedIDs: Set(model.exercises.map(\.id))) { model.add($0) }
            }
        }
    }
}

#Preview { TemplateEditorView().modelContainer(SampleData.preview()) }
