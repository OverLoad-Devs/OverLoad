import SwiftUI
import SwiftData

@main struct OverLoadApp: App {
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        do {
            container = try AppPersistence.makeContainer()
            startupError = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootTabView().modelContainer(container)
            } else {
                ContentUnavailableView("Unable to open workouts", systemImage: "externaldrive.badge.exclamationmark",
                                       description: Text(startupError ?? "Please restart the app."))
            }
        }
    }
}
