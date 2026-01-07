import Foundation
import SwiftData

// MARK: - Log Size Enum

enum LogSize: String, Codable, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }
    
    var abbreviation: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "leaf.fill"
        case .medium: return "flame.fill"
        case .large: return "tree.fill"
        }
    }
    
    var color: String {
        switch self {
        case .small: return "orange"
        case .medium: return "red"
        case .large: return "brown"
        }
    }
}

// MARK: - Log Entry Model

@Model
final class LogEntry {
    var id: UUID
    var size: String // Store as String for SwiftData compatibility
    var quantity: Int
    var timestamp: Date
    
    @Relationship(inverse: \Fire.logs)
    var fire: Fire?
    
    init(size: LogSize, quantity: Int = 1, timestamp: Date = Date()) {
        self.id = UUID()
        self.size = size.rawValue
        self.quantity = quantity
        self.timestamp = timestamp
    }
    
    var logSize: LogSize {
        get { LogSize(rawValue: size) ?? .medium }
        set { size = newValue.rawValue }
    }
}

// MARK: - Fire Model

@Model
final class Fire {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var notes: String?
    
    @Relationship(deleteRule: .cascade)
    var logs: [LogEntry] = []
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = nil
        self.notes = nil
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "In progress" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func logCount(for size: LogSize) -> Int {
        logs.filter { $0.logSize == size }.reduce(0) { $0 + $1.quantity }
    }
    
    var totalSmall: Int { logCount(for: .small) }
    var totalMedium: Int { logCount(for: .medium) }
    var totalLarge: Int { logCount(for: .large) }
    
    func totalUnits(settings: AppSettings) -> Double {
        let small = Double(totalSmall) * settings.smallRatio
        let medium = Double(totalMedium) * settings.mediumRatio
        let large = Double(totalLarge) * settings.largeRatio
        return small + medium + large
    }
    
    var logSummary: String {
        var parts: [String] = []
        if totalSmall > 0 { parts.append("\(totalSmall)S") }
        if totalMedium > 0 { parts.append("\(totalMedium)M") }
        if totalLarge > 0 { parts.append("\(totalLarge)L") }
        return parts.isEmpty ? "No logs" : parts.joined(separator: " • ")
    }
}

// MARK: - App Settings Model

@Model
final class AppSettings {
    var id: UUID
    var unitsPerCord: Double
    var smallRatio: Double
    var mediumRatio: Double
    var largeRatio: Double
    var seasonGoal: Double?
    var seasonStartMonth: Int // 1-12
    var seasonStartDay: Int
    var hasCompletedOnboarding: Bool

    // Cache for expensive date calculation
    private var cachedSeasonStartDate: Date?
    private var cachedSeasonStartYear: Int?

    init() {
        self.id = UUID()
        self.unitsPerCord = 400.0
        self.smallRatio = 0.25
        self.mediumRatio = 1.0
        self.largeRatio = 2.0
        self.seasonGoal = 3.0
        self.seasonStartMonth = 9 // September
        self.seasonStartDay = 1
        self.hasCompletedOnboarding = false
        self.cachedSeasonStartDate = nil
        self.cachedSeasonStartYear = nil
    }

    var seasonStartDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        // Return cached value if year hasn't changed
        if let cached = cachedSeasonStartDate,
           let cachedYear = cachedSeasonStartYear,
           cachedYear == currentYear {
            return cached
        }

        // Create this year's season start date
        var thisYearComponents = DateComponents()
        thisYearComponents.year = currentYear
        thisYearComponents.month = seasonStartMonth
        thisYearComponents.day = seasonStartDay

        guard let thisYearSeasonStart = calendar.date(from: thisYearComponents) else {
            return now
        }

        // If we're currently before this year's season start, use last year's
        let result: Date
        if now < thisYearSeasonStart {
            var lastYearComponents = DateComponents()
            lastYearComponents.year = currentYear - 1
            lastYearComponents.month = seasonStartMonth
            lastYearComponents.day = seasonStartDay
            result = calendar.date(from: lastYearComponents) ?? thisYearSeasonStart
        } else {
            result = thisYearSeasonStart
        }

        // Cache the result
        cachedSeasonStartDate = result
        cachedSeasonStartYear = currentYear

        return result
    }
    
    var seasonName: String {
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: seasonStartDate)
        let endYear = startYear + 1
        return "\(startYear)-\(String(endYear).suffix(2))"
    }
    
    func cordsBurned(from fires: [Fire]) -> Double {
        let totalUnits = fires.reduce(0.0) { $0 + $1.totalUnits(settings: self) }
        return totalUnits / unitsPerCord
    }
    
    func ratio(for size: LogSize) -> Double {
        switch size {
        case .small: return smallRatio
        case .medium: return mediumRatio
        case .large: return largeRatio
        }
    }
}
