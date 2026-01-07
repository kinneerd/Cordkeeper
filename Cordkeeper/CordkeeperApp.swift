import SwiftUI
import SwiftData

@main
struct CordkeeperApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Fire.self,
            LogEntry.self,
            AppSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                saveContext()
            }
        }
    }

    private func saveContext() {
        let context = sharedModelContainer.mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context on background: \(error)")
            }
        }
    }
}
