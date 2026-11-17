import SwiftUI
import SwiftData

struct CoachSuggestionView: View {
    let suggestion: Suggestion
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(suggestion.weight, specifier: "%g") lb × \(suggestion.reps) reps").font(.headline)
                Spacer()
                Text(suggestion.status.rawValue.capitalized)
                    .font(.caption.bold()).padding(6).background(.tint.opacity(0.12), in: Capsule())
            }
            Text(suggestion.reason).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CoachSuggestionView(suggestion: LoadCoachEngine.suggestNext(history: []))
        .padding().modelContainer(SampleData.preview())
}
