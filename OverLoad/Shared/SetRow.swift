import SwiftUI
import SwiftData

struct SetRow: View {
    let number: Int
    @Binding var set: DraftSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(number)").foregroundStyle(.secondary).frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps").font(.caption).foregroundStyle(.secondary)
                    TextField(set.targetReps.map(String.init) ?? "8", text: $set.repsText)
                        .keyboardType(.numberPad).accessibilityLabel("Set \(number) reps")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight (lb)").font(.caption).foregroundStyle(.secondary)
                    TextField("0", text: $set.weightText)
                        .keyboardType(.decimalPad).accessibilityLabel("Set \(number) weight in pounds")
                }
            }.textFieldStyle(.roundedBorder)
            if let previous = set.previous {
                Text("Previous: \(previous)").font(.caption).foregroundStyle(.secondary)
            }
            if set.repsText.isEmpty && set.weightText.isEmpty {
                Text("Not logged yet").font(.caption).foregroundStyle(.secondary)
            } else if let message = set.validationMessage {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.red)
            }
        }.padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var set = DraftSet(reps: 10, weight: 95)
    SetRow(number: 1, set: $set).padding().modelContainer(SampleData.preview())
}
