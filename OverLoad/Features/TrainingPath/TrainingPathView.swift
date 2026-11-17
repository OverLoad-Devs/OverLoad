import SwiftUI
import SwiftData

struct TrainingPathView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Workout progression system, built by the Training Path team")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                ContentUnavailableView("TODO", systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                                       description: Text("The Training Path team will build this feature."))
            }.padding().navigationTitle("Training Path")
        }
    }
}

#Preview { TrainingPathView().modelContainer(SampleData.preview()) }
