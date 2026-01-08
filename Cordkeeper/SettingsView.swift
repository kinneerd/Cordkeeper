import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    
    @Query(sort: \Fire.startTime, order: .reverse) private var allFires: [Fire]
    
    @State private var showingResetConfirmation = false
    @State private var showingResetOnboardingConfirmation = false
    
    private var seasonFires: [Fire] {
        allFires.filter { $0.startTime >= settings.seasonStartDate }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Calibration section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Medium pieces per cord")
                            Spacer()
                            Text("\(Int(settings.unitsPerCord))")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.unitsPerCord, in: 100...800, step: 10)
                            .tint(.orange)
                            .accessibilityLabel("Medium pieces per cord")
                            .accessibilityValue("\(Int(settings.unitsPerCord)) pieces")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Cord Calibration")
                } footer: {
                    Text("How many medium-sized splits make up one cord of your wood.")
                }
                
                // Size ratios section
                Section {
                    RatioRow(label: "Small", value: $settings.smallRatio, color: .orange)
                    RatioRow(label: "Medium", value: $settings.mediumRatio, color: .red)
                    RatioRow(label: "Large", value: $settings.largeRatio, color: .brown)
                } header: {
                    Text("Size Ratios")
                } footer: {
                    Text("Relative weight of each size compared to your baseline. Medium is typically 1.0.")
                }
                
                // Season goal section
                Section {
                    Toggle("Track against a goal", isOn: Binding(
                        get: { settings.seasonGoal != nil },
                        set: { enabled in
                            if enabled {
                                settings.seasonGoal = 3.0
                            } else {
                                settings.seasonGoal = nil
                            }
                        }
                    ))
                    .tint(.orange)
                    
                    if let goal = settings.seasonGoal {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Season goal")
                                Spacer()
                                Text("\(String(format: "%.1f", goal)) cords")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { settings.seasonGoal ?? 3.0 },
                                    set: { settings.seasonGoal = $0 }
                                ),
                                in: 0.5...10,
                                step: 0.5
                            )
                            .tint(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Season Goal")
                }
                
                // Season dates section
                Section {
                    HStack {
                        Text("Season starts")
                        Spacer()
                        Menu {
                            ForEach(1...12, id: \.self) { month in
                                Button(monthName(month)) {
                                    settings.seasonStartMonth = month
                                }
                            }
                        } label: {
                            Text(monthName(settings.seasonStartMonth))
                                .foregroundStyle(.orange)
                        }
                        
                        Menu {
                            ForEach(1...31, id: \.self) { day in
                                Button("\(day)") {
                                    settings.seasonStartDay = day
                                }
                            }
                        } label: {
                            Text("\(settings.seasonStartDay)")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Current season")
                        Spacer()
                        Text(settings.seasonName)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Season")
                } footer: {
                    Text("The heating season typically starts in September or October.")
                }
                
                // Stats section
                Section("This Season") {
                    HStack {
                        Text("Total fires")
                        Spacer()
                        Text("\(seasonFires.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total logs")
                        Spacer()
                        let total = seasonFires.reduce(0) { $0 + $1.totalSmall + $1.totalMedium + $1.totalLarge }
                        Text("\(total)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Cords burned")
                        Spacer()
                        Text(String(format: "%.2f", settings.cordsBurned(from: seasonFires)))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Reset section
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset Season Data")
                        }
                    }
                    
                    Button {
                        showingResetOnboardingConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Re-run Setup")
                        }
                    }
                } footer: {
                    Text("Reset will delete all fires from this season. Re-run setup will show the welcome screens again.")
                }
                
                // About section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Cordkeeper")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset Season Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Fires", role: .destructive) {
                    resetSeasonData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all \(seasonFires.count) fires from this season. This cannot be undone.")
            }
            .confirmationDialog(
                "Re-run Setup?",
                isPresented: $showingResetOnboardingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Re-run Setup") {
                    settings.hasCompletedOnboarding = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will show the welcome and calibration screens again.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
    
    private func resetSeasonData() {
        for fire in seasonFires {
            modelContext.delete(fire)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error resetting season data: \(error)")
        }
    }
}

// MARK: - Ratio Row

struct RatioRow: View {
    let label: String
    @Binding var value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { if value > 0.25 { value -= 0.25 } }) {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(value > 0.25 ? .orange : .gray)
                }
                .buttonStyle(.plain)
                .disabled(value <= 0.25)
                
                Text(String(format: "%.2f", value))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 50)
                
                Button(action: { if value < 5.0 { value += 0.25 } }) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .disabled(value >= 5.0)
            }
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
        .modelContainer(for: [Fire.self, LogEntry.self, AppSettings.self], inMemory: true)
}
