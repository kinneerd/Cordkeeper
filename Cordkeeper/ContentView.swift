import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    @State private var loadedSettings: AppSettings?

    var currentSettings: AppSettings {
        // Return cached if already loaded
        if let loaded = loadedSettings {
            return loaded
        }

        // Check for existing settings
        if let existing = settings.first {
            loadedSettings = existing
            return existing
        }

        // Create new settings only once
        let newSettings = AppSettings()
        modelContext.insert(newSettings)

        do {
            try modelContext.save()
        } catch {
            print("Error saving initial settings: \(error)")
        }

        loadedSettings = newSettings
        return newSettings
    }

    var body: some View {
        Group {
            if !currentSettings.hasCompletedOnboarding {
                OnboardingView(settings: currentSettings)
            } else {
                MainTabView(settings: currentSettings)
            }
        }
    }
}

struct MainTabView: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        TabView {
            DashboardView(settings: settings)
                .tabItem {
                    Label("Home", systemImage: "flame.fill")
                }
            
            HistoryView(settings: settings)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            
            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Fire.self, LogEntry.self, AppSettings.self], inMemory: true)
}
