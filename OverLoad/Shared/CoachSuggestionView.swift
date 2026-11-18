import SwiftUI
import SwiftData

struct CoachSuggestionView: View {
    let suggestion: Suggestion
    private var badgeColor: Color {
        switch suggestion.status {
        case .progress: return .green
        case .hold: return .gray
        case .plateau: return .orange
        case .deload: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(suggestion.weight, specifier: "%g") lb × \(suggestion.reps) reps").font(.headline)
                Spacer()
                Text(suggestion.status.rawValue.capitalized)
                    .font(.caption.bold())
                    .padding(6)
                    .background(badgeColor.opacity(0.12), in: Capsule())
            }
            Text(suggestion.reason).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Coach statuses") {
    VStack(spacing: 24) {
        CoachSuggestionView(suggestion: Suggestion(weight: 105, reps: 8, status: .progress,
                                                  reason: "Every set reached 12 reps; add 5 lb."))
        CoachSuggestionView(suggestion: Suggestion(weight: 185, reps: 12, status: .hold,
                                                  reason: "Keep the load and aim for one more rep."))
        CoachSuggestionView(suggestion: Suggestion(weight: 135, reps: 11, status: .plateau,
                                                  reason: "Best set volume has not increased over three sessions."))
        CoachSuggestionView(suggestion: Suggestion(weight: 205, reps: 8, status: .deload,
                                                  reason: "Top set below 8 reps twice; reduce load 10%."))
    }.padding().modelContainer(SampleData.preview())
}
