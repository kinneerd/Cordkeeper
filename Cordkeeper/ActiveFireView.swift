import SwiftUI
import SwiftData

struct ActiveFireView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var fire: Fire
    let settings: AppSettings
    
    @State private var showingEndConfirmation = false
    @State private var selectedSize: LogSize?
    @State private var quantityToAdd: Int = 1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Fire status header
                fireHeader
                
                Spacer()
                
                // Log entry buttons
                logEntrySection
                
                Spacer()
                
                // Current fire tally
                currentTally
                
                // End fire button
                endFireButton
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Active Fire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "End this fire?",
                isPresented: $showingEndConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Fire", role: .destructive) {
                    endFire()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will save the fire to your history.")
            }
            .sheet(item: $selectedSize) { size in
                QuantityPickerView(
                    size: size,
                    quantity: $quantityToAdd,
                    onAdd: {
                        addLogs(size: size, quantity: quantityToAdd)
                        selectedSize = nil
                    }
                )
                .presentationDetents([.height(300)])
            }
        }
    }
    
    // MARK: - Fire Header
    
    private var fireHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse)
                
                Text("Fire in Progress")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text("Started \(fire.startTime.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Log Entry Section
    
    private var logEntrySection: some View {
        VStack(spacing: 16) {
            Text("Tap to add logs")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                LogButton(size: .small) {
                    addLogs(size: .small, quantity: 1)
                } onLongPress: {
                    quantityToAdd = 1
                    selectedSize = .small
                }
                .accessibilityLabel("Add small log")
                .accessibilityHint("Tap to add one, long press for multiple")

                LogButton(size: .medium) {
                    addLogs(size: .medium, quantity: 1)
                } onLongPress: {
                    quantityToAdd = 1
                    selectedSize = .medium
                }
                .accessibilityLabel("Add medium log")
                .accessibilityHint("Tap to add one, long press for multiple")

                LogButton(size: .large) {
                    addLogs(size: .large, quantity: 1)
                } onLongPress: {
                    quantityToAdd = 1
                    selectedSize = .large
                }
                .accessibilityLabel("Add large log")
                .accessibilityHint("Tap to add one, long press for multiple")
            }
            
            Text("Hold for multiple")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Current Tally
    
    private var currentTally: some View {
        VStack(spacing: 12) {
            Text("This Fire")
                .font(.headline)
            
            HStack(spacing: 24) {
                TallyItem(label: "S", count: fire.totalSmall, color: .orange)
                TallyItem(label: "M", count: fire.totalMedium, color: .red)
                TallyItem(label: "L", count: fire.totalLarge, color: .brown)
            }
            
            let units = fire.totalUnits(settings: settings)
            Text("\(String(format: "%.1f", units)) units")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - End Fire Button
    
    private var endFireButton: some View {
        Button(action: { showingEndConfirmation = true }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("End Fire")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Actions
    
    private func addLogs(size: LogSize, quantity: Int) {
        let entry = LogEntry(size: size, quantity: quantity)
        entry.fire = fire
        fire.logs.append(entry)
        modelContext.insert(entry)

        // SwiftData will autosave - no need to save on every tap
        // Only save on critical operations (ending fire, backgrounding)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func endFire() {
        // If no logs were added, delete the fire instead of ending it
        if fire.logs.isEmpty {
            modelContext.delete(fire)
            do {
                try modelContext.save()
            } catch {
                print("Error deleting empty fire: \(error)")
            }
            dismiss()
            return
        }

        fire.endTime = Date()

        // Save before dismissing
        do {
            try modelContext.save()
        } catch {
            print("Error saving fire end time: \(error)")
        }

        dismiss()
    }
}

// MARK: - Log Button

struct LogButton: View {
    let size: LogSize
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false
    @State private var pressStartTime: Date?
    @State private var longPressTriggered = false
    @State private var timer: Timer?

    private var color: Color {
        switch size {
        case .small: return .orange
        case .medium: return .red
        case .large: return .brown
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(size.abbreviation)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text(size.rawValue)
                .font(.caption)
        }
        .frame(width: 90, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(isPressed ? 0.3 : 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color, lineWidth: 3)
        )
        .foregroundStyle(color)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        pressStartTime = Date()
                        longPressTriggered = false

                        // Start timer for long press
                        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            if isPressed {
                                longPressTriggered = true
                                onLongPress()
                                // Keep button in pressed state visually
                            }
                        }
                    }
                }
                .onEnded { _ in
                    timer?.invalidate()
                    timer = nil
                    isPressed = false

                    // Only trigger tap if long press didn't fire
                    if !longPressTriggered {
                        onTap()
                    }

                    longPressTriggered = false
                    pressStartTime = nil
                }
        )
    }
}

// MARK: - Tally Item

struct TallyItem: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text(label)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Quantity Picker

struct QuantityPickerView: View {
    let size: LogSize
    @Binding var quantity: Int
    let onAdd: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var color: Color {
        switch size {
        case .small: return .orange
        case .medium: return .red
        case .large: return .brown
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Add \(size.rawValue) Logs")
                    .font(.headline)
                
                HStack(spacing: 24) {
                    Button(action: { if quantity > 1 { quantity -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(quantity > 1 ? color : .gray)
                    }
                    .disabled(quantity <= 1)
                    
                    Text("\(quantity)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .frame(width: 100)
                    
                    Button(action: { if quantity < 99 { quantity += 1 } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(color)
                    }
                }
                
                Button(action: onAdd) {
                    Text("Add \(quantity) \(size.rawValue)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let fire = Fire()
    return ActiveFireView(fire: fire, settings: AppSettings())
        .modelContainer(for: [Fire.self, LogEntry.self, AppSettings.self], inMemory: true)
}
