import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var settings: AppSettings
    
    @Query(sort: \Fire.startTime, order: .reverse) private var allFires: [Fire]

    @State private var selectedFire: Fire?
    @State private var cachedGroupedFires: [(key: Date, month: String, fires: [Fire])] = []

    private var completedFires: [Fire] {
        allFires.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedFires.isEmpty {
                    emptyState
                } else {
                    fireList
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedFire) { fire in
                FireDetailView(fire: fire, settings: settings)
            }
            .onAppear {
                updateGroupedFires()
            }
            .onChange(of: allFires) { _, _ in
                updateGroupedFires()
            }
        }
    }

    // MARK: - Helpers

    private func updateGroupedFires() {
        let calendar = Calendar.current

        // Group fires by month/year using Date as key
        let grouped = Dictionary(grouping: completedFires) { fire -> Date in
            let components = calendar.dateComponents([.year, .month], from: fire.startTime)
            return calendar.date(from: components) ?? fire.startTime
        }

        // Sort by date (most recent first) and format month string
        cachedGroupedFires = grouped.map { (key: $0.key, month: $0.key.formatted(.dateTime.month(.wide).year()), fires: $0.value) }
            .sorted { $0.key > $1.key }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Fires Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your completed fires will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Fire List
    
    private var fireList: some View {
        List {
            ForEach(cachedGroupedFires, id: \.key) { group in
                Section(group.month) {
                    ForEach(group.fires) { fire in
                        FireRowView(fire: fire, settings: settings)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFire = fire
                            }
                    }
                    .onDelete { indexSet in
                        deleteFires(at: indexSet, in: group.fires)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions

    private func deleteFires(at offsets: IndexSet, in fires: [Fire]) {
        for index in offsets {
            let fire = fires[index]
            modelContext.delete(fire)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting fires: \(error)")
        }
    }
}

// MARK: - Fire Row View

struct FireRowView: View {
    let fire: Fire
    let settings: AppSettings
    
    var body: some View {
        HStack(spacing: 12) {
            // Date circle
            VStack(spacing: 2) {
                Text(fire.startTime.formatted(.dateTime.day()))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(fire.startTime.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44)
            
            // Fire details
            VStack(alignment: .leading, spacing: 4) {
                Text(fire.logSummary)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(fire.formattedDuration, systemImage: "clock")
                    
                    Text("•")
                    
                    let units = fire.totalUnits(settings: settings)
                    Text("\(String(format: "%.1f", units)) units")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Fire Detail View

struct FireDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var fire: Fire
    let settings: AppSettings
    
    @State private var showingDeleteConfirmation = false
    @State private var noteText: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Summary section
                Section {
                    HStack {
                        Label("Started", systemImage: "play.circle")
                        Spacer()
                        Text(fire.startTime.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let endTime = fire.endTime {
                        HStack {
                            Label("Ended", systemImage: "stop.circle")
                            Spacer()
                            Text(endTime.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Label("Duration", systemImage: "clock")
                        Spacer()
                        Text(fire.formattedDuration)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Logs section
                Section("Logs Burned") {
                    HStack {
                        SizeDetailRow(size: .small, count: fire.totalSmall, settings: settings)
                        Divider()
                        SizeDetailRow(size: .medium, count: fire.totalMedium, settings: settings)
                        Divider()
                        SizeDetailRow(size: .large, count: fire.totalLarge, settings: settings)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text("Total Units")
                        Spacer()
                        Text(String(format: "%.1f", fire.totalUnits(settings: settings)))
                            .fontWeight(.semibold)
                    }
                    
                    let cordFraction = fire.totalUnits(settings: settings) / settings.unitsPerCord
                    HStack {
                        Text("Cord Equivalent")
                        Spacer()
                        Text(String(format: "%.3f", cordFraction))
                            .fontWeight(.semibold)
                    }
                }
                
                // Notes section
                Section("Notes") {
                    TextField("Add a note...", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                        .onAppear {
                            noteText = fire.notes ?? ""
                        }
                        .onChange(of: noteText) { _, newValue in
                            fire.notes = newValue.isEmpty ? nil : newValue
                        }
                }
                
                // Delete section
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Fire", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Fire Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete this fire?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(fire)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error deleting fire: \(error)")
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

struct SizeDetailRow: View {
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
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(size.rawValue)
                .font(.caption)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView(settings: AppSettings())
        .modelContainer(for: [Fire.self, LogEntry.self, AppSettings.self], inMemory: true)
}
