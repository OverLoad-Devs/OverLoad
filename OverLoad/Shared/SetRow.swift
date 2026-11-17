import SwiftUI
import SwiftData

struct SetRow: View {
    let number: Int
    @Binding var set: DraftSet
    var body: some View {
        HStack {
            Text("\(number)").foregroundStyle(.secondary).frame(width: 24)
            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad).accessibilityLabel("Set \(number) reps")
            Text("reps").foregroundStyle(.secondary)
            TextField("Weight", value: $set.weight, format: .number)
                .keyboardType(.decimalPad).accessibilityLabel("Set \(number) weight in pounds")
            Text("lb").foregroundStyle(.secondary)
        }.textFieldStyle(.roundedBorder)
    }
}

#Preview {
    @Previewable @State var set = DraftSet(reps: 10, weight: 95)
    SetRow(number: 1, set: $set).padding().modelContainer(SampleData.preview())
}
