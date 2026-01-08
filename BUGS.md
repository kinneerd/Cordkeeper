# Cordkeeper - Bug Report & Technical Issues

**Last Updated**: 2026-01-07
**Status**: Pre-launch critical bugs identified

---

## 🔴 CRITICAL - Must Fix Before Launch

### 1. Division by Zero in Cord Calculations
**Severity**: CRITICAL - App Crash
**Locations**:
- `Models.swift:208` - `cordsBurned()` function
- `DashboardView.swift:256` - `updateCachedStatistics()`
- `HistoryView.swift` - Fire detail calculations

**Issue**: If `unitsPerCord` is ever 0, division will crash the app.

**Current Code**:
```swift
return totalUnits / unitsPerCord  // No validation!
```

**Fix**:
```swift
guard unitsPerCord > 0 else { return 0 }
return totalUnits / unitsPerCord
```

**Impact**: Complete app crash when viewing statistics
**Priority**: P0 - Fix immediately

---

### 2. SwiftData Cache Not Marked as Transient
**Severity**: CRITICAL - Data Corruption
**Location**: `Models.swift:139-140`

**Issue**: Cache properties in AppSettings are persisted to disk and never properly invalidated.

**Current Code**:
```swift
private var cachedSeasonStartDate: Date?
private var cachedSeasonStartYear: Int?
```

**Problems**:
1. Cache persists across app restarts with stale data
2. Not invalidated when `seasonStartMonth` or `seasonStartDay` changes
3. Causes incorrect season boundary calculations

**Fix**: Mark as `@Transient` or remove from model:
```swift
@Transient private var cachedSeasonStartDate: Date?
@Transient private var cachedSeasonStartYear: Int?
```

**Impact**: Users see wrong season stats, fires attributed to wrong season
**Priority**: P0 - Fix immediately

---

### 3. Race Condition in Settings Creation
**Severity**: HIGH - Data Duplication
**Location**: `ContentView.swift:8-22`

**Issue**: Computed property creates new AppSettings on every call if none exist, causing potential duplicates.

**Current Code**:
```swift
var currentSettings: AppSettings {
    if let existing = settings.first {
        return existing
    }
    let newSettings = AppSettings()
    modelContext.insert(newSettings)
    // Creates new object every time this property is accessed!
    try? modelContext.save()
    return newSettings
}
```

**Fix**: Use `@State` initialization or proper lifecycle hook:
```swift
@State private var loadedSettings: AppSettings?

var currentSettings: AppSettings {
    if let loaded = loadedSettings {
        return loaded
    }
    if let existing = settings.first {
        loadedSettings = existing
        return existing
    }
    let newSettings = AppSettings()
    modelContext.insert(newSettings)
    try? modelContext.save()
    loadedSettings = newSettings
    return newSettings
}
```

**Impact**: Multiple AppSettings records, unpredictable app behavior
**Priority**: P0 - Fix immediately

---

### 4. Memory Leak - Timer Not Invalidated on View Disappear
**Severity**: HIGH - Memory Leak
**Location**: `ActiveFireView.swift:261-267` (LogButton)

**Issue**: Timer scheduled but not invalidated if view disappears before firing.

**Current Code**:
```swift
timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
    if isPressed {
        longPressTriggered = true
        onLongPress()
    }
}
// Only invalidated in onEnded, not onDisappear
```

**Fix**: Add cleanup:
```swift
var body: some View {
    // ... existing view code ...
    .onDisappear {
        timer?.invalidate()
        timer = nil
    }
}
```

**Impact**: Memory leak, possible crashes on older devices
**Priority**: P1 - Fix before launch

---

### 5. Invalid Season Date Handling
**Severity**: HIGH - Logic Error
**Location**: `Models.swift:176-178`

**Issue**: Setting season start to invalid date (e.g., Sept 31) causes fallback to current date, breaking season tracking.

**Current Code**:
```swift
guard let thisYearSeasonStart = calendar.date(from: thisYearComponents) else {
    return now  // WRONG! Should validate input
}
```

**Fix**: Validate and clamp day to valid range:
```swift
// In init() or setter
let maxDaysInMonth = calendar.range(of: .day, in: .month, for: /* date */)?.count ?? 31
seasonStartDay = min(seasonStartDay, maxDaysInMonth)
```

**Impact**: Season tracking breaks completely for certain configurations
**Priority**: P1 - Fix before launch

---

## 🟡 HIGH PRIORITY - Should Fix Soon

### 6. Performance: Expensive Computed Property on Every Render
**Severity**: MEDIUM - Performance
**Location**: `HistoryView.swift:16-28`

**Issue**: `groupedFires` computed property does dictionary grouping, date formatting, and sorting on every view update.

**Fix**: Cache with `@State`:
```swift
@State private var cachedGroupedFires: [(key: Date, month: String, fires: [Fire])] = []

private func updateGroupedFires() {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: completedFires) { fire -> Date in
        let components = calendar.dateComponents([.year, .month], from: fire.startTime)
        return calendar.date(from: components) ?? fire.startTime
    }
    cachedGroupedFires = grouped.map { ... }.sorted { ... }
}
```

**Impact**: UI lag with many fires
**Priority**: P2 - Fix in v1.1

---

### 7. Day Picker Limited to 28 Days
**Severity**: MEDIUM - Feature Gap
**Location**: `SettingsView.swift:107-116`

**Issue**: User can only select days 1-28, but some months have 29-31 days.

**Fix**: Extend range:
```swift
ForEach(1...31, id: \.self) { day in
```

**Impact**: Users cannot set season start to days 29-31
**Priority**: P2 - Fix in v1.0 or v1.1

---

### 8. Notes Not Explicitly Saved
**Severity**: MEDIUM - Data Loss
**Location**: `HistoryView.swift:224-226`

**Issue**: Notes are updated in model but not saved until autosave triggers.

**Fix**: Add explicit save on notes change with debouncing:
```swift
.onChange(of: noteText) { _, newValue in
    fire.notes = newValue.isEmpty ? nil : newValue
    try? modelContext.save()
}
```

**Impact**: Notes lost if user dismisses quickly
**Priority**: P2 - Fix in v1.1

---

### 9. Negative Duration Not Handled
**Severity**: LOW - Edge Case
**Location**: `Models.swift:86-100`

**Issue**: If `endTime < startTime`, duration shows negative or incorrect values.

**Fix**: Add validation:
```swift
var duration: TimeInterval? {
    guard let endTime = endTime else { return nil }
    let dur = endTime.timeIntervalSince(startTime)
    guard dur >= 0 else { return 0 }  // Clamp to 0
    return dur
}
```

**Impact**: Confusing display in edge cases
**Priority**: P3 - Fix eventually

---

### 10. Quantity State Not Reset on Sheet Dismiss
**Severity**: LOW - UX Issue
**Location**: `ActiveFireView.swift:13`

**Issue**: `quantityToAdd` persists across sheet presentations.

**Fix**: Reset on sheet dismiss:
```swift
.sheet(item: $selectedSize) { size in
    QuantityPickerView(...)
}
.onChange(of: selectedSize) { oldValue, newValue in
    if newValue == nil {
        quantityToAdd = 1  // Reset when sheet closes
    }
}
```

**Impact**: Minor UX annoyance
**Priority**: P3 - Nice to have

---

## 🔵 MEDIUM PRIORITY - Technical Debt

### 11. No User-Facing Error Messages
**Severity**: LOW - UX Issue
**Locations**: Throughout codebase

**Issue**: All errors are printed to console; users see nothing when saves fail.

**Fix**: Add error alert state:
```swift
@State private var errorMessage: String?
@State private var showError = false

// In catch blocks:
errorMessage = "Failed to save: \(error.localizedDescription)"
showError = true

// In view:
.alert("Error", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage ?? "Unknown error")
}
```

**Impact**: Users don't know when saves fail
**Priority**: P2 - Fix in v1.1

---

### 12. Missing Accessibility Labels
**Severity**: MEDIUM - Accessibility
**Locations**: Multiple

**Missing on**:
- Delete buttons in HistoryView
- Ratio adjustment +/- buttons in SettingsView
- Month/day pickers in SettingsView
- Quantity stepper in QuantityPickerView

**Fix**: Add labels systematically:
```swift
Button(action: deleteAction) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete fire")
.accessibilityHint("Removes this fire from your history")
```

**Impact**: Poor VoiceOver experience
**Priority**: P2 - Fix before launch if targeting accessibility

---

### 13. SwiftData Relationship Manual Management
**Severity**: LOW - Code Quality
**Location**: `ActiveFireView.swift:182-186`

**Issue**: Both sides of bidirectional relationship set manually.

**Current**:
```swift
entry.fire = fire
fire.logs.append(entry)
```

**Better**:
```swift
fire.logs.append(entry)
// SwiftData handles inverse automatically
```

**Impact**: Potential relationship inconsistencies
**Priority**: P3 - Cleanup in v1.1

---

### 14. No Input Validation on LogEntry Quantity
**Severity**: LOW - Data Integrity
**Location**: `Models.swift:40-60`

**Issue**: No validation prevents quantity = -1 or 1,000,000

**Fix**: Add validation:
```swift
@Model
final class LogEntry {
    var quantity: Int {
        didSet {
            quantity = max(1, min(quantity, 999))
        }
    }
}
```

**Impact**: Corrupted data from bugs or exploits
**Priority**: P3 - Nice to have

---

## 📊 Summary

| Severity | Count | Action Required |
|----------|-------|-----------------|
| 🔴 Critical | 5 | **Must fix before launch** |
| 🟡 High | 5 | Fix in v1.0 or v1.1 |
| 🔵 Medium | 4 | Technical debt for v1.1+ |

---

## Recommended Action Plan

### Phase 1: Pre-Launch (Critical)
1. Fix division by zero (all locations)
2. Mark cache as `@Transient` in AppSettings
3. Fix settings creation race condition
4. Add timer cleanup on view disappear
5. Validate season date configuration

**Estimated Effort**: 2-3 hours

### Phase 2: Post-Launch v1.0.1 (High Priority)
1. Cache `groupedFires` for performance
2. Extend day picker to 31
3. Add explicit save for notes
4. Add user-facing error alerts

**Estimated Effort**: 3-4 hours

### Phase 3: v1.1 (Medium Priority)
1. Complete accessibility audit
2. Add input validation
3. Clean up relationship management
4. Handle negative duration edge case

**Estimated Effort**: 4-5 hours

---

**Next Steps**: Address Phase 1 critical bugs immediately before any production release.
