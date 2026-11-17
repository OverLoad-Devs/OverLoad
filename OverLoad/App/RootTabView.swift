import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            WorkoutView().tabItem { Label("Workout", systemImage: "dumbbell") }
            LoadCoachView().tabItem { Label("Load Coach", systemImage: "chart.line.uptrend.xyaxis") }
            TrainingPathView().tabItem { Label("Training Path", systemImage: "point.topleft.down.to.point.bottomright.curvepath") }
            HistoryView().tabItem { Label("History", systemImage: "clock") }
        }
    }
}

#Preview { RootTabView().modelContainer(SampleData.preview()) }
