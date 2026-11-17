import SwiftUI
import SwiftData

struct LoadCoachView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    var body: some View {
        NavigationStack {
            List(exercises) { exercise in
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name).font(.headline)
                    CoachSuggestionView(suggestion: LoadCoachViewModel.suggestion(for: exercise, sessions: sessions))
                }.padding(.vertical, 4)
            }
            .navigationTitle("Load Coach")
        }
    }
}

#Preview { LoadCoachView().modelContainer(SampleData.preview()) }
