import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    
    @Query(sort: \Fire.startTime, order: .reverse) private var allFires: [Fire]

    @State private var showingActiveFireSheet = false
    @State private var currentFire: Fire?

    // Cached statistics - computed on data changes
    @State private var cachedSeasonFires: [Fire] = []
    @State private var cachedActiveFire: Fire?
    @State private var cachedCordsBurned: Double = 0
    @State private var cachedTotalLogs: Int = 0
    @State private var cachedSmallCount: Int = 0
    @State private var cachedMediumCount: Int = 0
    @State private var cachedLargeCount: Int = 0

    private var progress: Double {
        guard let goal = settings.seasonGoal, goal > 0 else { return 0 }
        return min(cachedCordsBurned / goal, 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Season header card
                    seasonCard
                    
                    // Quick stats
                    statsRow
                    
                    // Breakdown by size
                    sizeBreakdownCard
                    
                    // Start/View Fire button
                    fireButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cordkeeper")
            .sheet(isPresented: $showingActiveFireSheet, onDismiss: {
                // Refresh statistics when sheet is dismissed (fire ended or closed)
                updateCachedStatistics()
            }) {
                if let fire = currentFire {
                    ActiveFireView(fire: fire, settings: settings)
                }
            }
            .onAppear {
                updateCachedStatistics()
                if let active = cachedActiveFire {
                    currentFire = active
                }
            }
            .onChange(of: allFires) { _, _ in
                updateCachedStatistics()
            }
            .onChange(of: settings.seasonStartDate) { _, _ in
                updateCachedStatistics()
            }
            .onChange(of: cachedActiveFire) { _, newValue in
                currentFire = newValue
            }
        }
    }
    
    // MARK: - Season Card

    private var seasonCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Season \(settings.seasonName)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)

                Text(String(format: "%.2f", cachedCordsBurned))
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                Text("cords burned")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Season \(settings.seasonName): \(String(format: "%.2f", cachedCordsBurned)) cords burned")

            if let goal = settings.seasonGoal {
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(.orange.gradient)
                                .frame(width: geometry.size.width * progress, height: 16)
                        }
                    }
                    .frame(height: 16)
                    .accessibilityLabel("Progress bar")
                    .accessibilityValue("\(Int(progress * 100)) percent")

                    HStack {
                        Text("\(Int(progress * 100))% of \(String(format: "%.1f", goal)) cord goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "flame",
                value: "\(cachedSeasonFires.count)",
                label: "fires"
            )

            StatCard(
                icon: "square.stack.3d.up.fill",
                value: "\(cachedTotalLogs)",
                label: "logs"
            )
        }
    }
    
    // MARK: - Size Breakdown
    
    private var sizeBreakdownCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("By Size")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                SizeStatView(
                    size: .small,
                    count: cachedSmallCount,
                    settings: settings
                )

                SizeStatView(
                    size: .medium,
                    count: cachedMediumCount,
                    settings: settings
                )

                SizeStatView(
                    size: .large,
                    count: cachedLargeCount,
                    settings: settings
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Fire Button
    
    private var fireButton: some View {
        Group {
            if let fire = cachedActiveFire {
                Button(action: {
                    currentFire = fire
                    showingActiveFireSheet = true
                }) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Fire in Progress")
                                .font(.headline)
                            Text(fire.logSummary)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityLabel("View active fire: \(fire.logSummary)")
                .accessibilityHint("Opens the active fire tracking screen")
            } else {
                Button(action: startNewFire) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                        Text("Start a Fire")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityLabel("Start a new fire")
                .accessibilityHint("Creates a new fire tracking session")
            }
        }
    }
    
    // MARK: - Helpers

    private func updateCachedStatistics() {
        // Filter season fires once
        let seasonStartDate = settings.seasonStartDate
        cachedSeasonFires = allFires.filter { $0.startTime >= seasonStartDate }

        // Find active fire
        cachedActiveFire = cachedSeasonFires.first { $0.isActive }

        // Calculate all statistics in a single pass through the data
        var smallTotal = 0
        var mediumTotal = 0
        var largeTotal = 0
        var totalUnits = 0.0

        for fire in cachedSeasonFires {
            smallTotal += fire.totalSmall
            mediumTotal += fire.totalMedium
            largeTotal += fire.totalLarge
            totalUnits += fire.totalUnits(settings: settings)
        }

        cachedSmallCount = smallTotal
        cachedMediumCount = mediumTotal
        cachedLargeCount = largeTotal
        cachedTotalLogs = smallTotal + mediumTotal + largeTotal
        cachedCordsBurned = totalUnits / settings.unitsPerCord
    }

    // MARK: - Actions

    private func startNewFire() {
        let fire = Fire()
        modelContext.insert(fire)

        // Explicitly save to ensure fire is persisted before opening sheet
        do {
            try modelContext.save()
        } catch {
            print("Error saving new fire: \(error)")
        }

        currentFire = fire
        showingActiveFireSheet = true
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SizeStatView: View {
    let size: LogSize
    let count: Int
    let settings: AppSettings
    
    private var color: Color {
        switch size {
        case .small: return .orange
        case .medium: return .red
        case .large: return .brown
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(size.abbreviation)
                .font(.headline)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text("\(String(format: "%.2f", settings.ratio(for: size)))x")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardView(settings: AppSettings())
        .modelContainer(for: [Fire.self, LogEntry.self, AppSettings.self], inMemory: true)
}
