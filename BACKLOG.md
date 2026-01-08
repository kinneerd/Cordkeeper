# Cordkeeper - Feature Backlog & Technical Debt

## Version 1.1 - High Priority Enhancements

### Mini Trend Chart (High Value)
- **Description**: Add a weekly breakdown chart showing cords burned over the season
- **Location**: Below progress bar on dashboard
- **Implementation**: Use Swift Charts framework
- **Tap Action**: Expands to full history view
- **Effort**: 3-4 hours
- **Value**: Transforms app from tracker to insights tool

### Light Mode Theme
- **Description**: Earthy browns/greens color palette for light mode
- **Why**: Accessibility and user preference
- **Testing Required**: All views need verification
- **Effort**: 2-3 hours
- **Value**: Broader user appeal

## Version 1.2 - Nice-to-Have Features

### Animated Flame Flicker
- **Description**: Subtle animation on flame icons throughout app
- **Why**: Adds delight and polish
- **Effort**: 1 hour
- **Value**: Medium - wait for user feedback first

### Pulse Animation on "Start a Fire" Button
- **Description**: Gentle pulse to draw attention to primary action
- **Why**: Encourages engagement
- **Concern**: Might feel gimmicky - test with users
- **Effort**: 30 minutes
- **Value**: Low priority

### Landscape/Tablet Optimization
- **Description**: Horizontal layout for wider screens
- **Why**: Better use of iPad screen real estate
- **Priority**: Low - primarily a phone app for woodstove users
- **Effort**: 2-3 hours
- **Value**: Nice-to-have for tablet users

## Future Feature Ideas

### Export & Sharing
- [ ] Export season data as CSV
- [ ] Share season statistics image to social media
- [ ] Email season summary report

### Analytics & Insights
- [ ] Average logs per fire
- [ ] Most active burning day of week
- [ ] Projected date to reach season goal
- [ ] Coldest days correlation (if weather API integrated)

### Fire Management
- [ ] Add notes to individual fires (weather, wood type, etc.)
- [ ] Fire templates for common burn patterns
- [ ] "Quick add" widget for iOS home screen

### Data Management
- [ ] iCloud sync across devices
- [ ] Backup/restore to file
- [ ] Archive old seasons

### Advanced Settings
- [ ] Multiple wood types with different ratios
- [ ] Cost tracking (price per cord)
- [ ] Inventory management (cords remaining in woodshed)

### Notifications
- [ ] Reminder to log fire before backgrounding app
- [ ] Weekly progress summary
- [ ] Goal milestone celebrations

## Technical Debt & Optimizations

### Code Quality
- [ ] Extract reusable color constants to prevent duplication
- [ ] Create a centralized theme manager
- [ ] Add unit tests for calculation logic
- [ ] Add UI tests for critical flows (start fire, add logs, end fire)

### Performance
- [ ] Profile app with Instruments to identify bottlenecks
- [ ] Consider pagination for history if user has 100+ fires
- [ ] Optimize image/icon rendering

### Accessibility
- [ ] Full VoiceOver audit
- [ ] Dynamic Type support verification
- [ ] High contrast mode testing
- [ ] Haptic feedback patterns review

### Error Handling
- [ ] User-facing error messages instead of console prints
- [ ] Retry logic for failed saves
- [ ] Data corruption recovery

### Documentation
- [ ] Add inline code documentation
- [ ] Create architecture decision records (ADRs)
- [ ] Document data migration strategy for future schema changes

## Deferred / Won't Do

### Complex Season Management
- **Description**: Multiple overlapping seasons, custom date ranges
- **Reason**: Adds complexity without clear user value
- **Decision**: Keep simple - one season at a time

### Social Features
- **Description**: Compare stats with friends, leaderboards
- **Reason**: Out of scope for MVP, privacy concerns
- **Decision**: Focus on individual tracking

---

**Last Updated**: 2026-01-07
**Next Review**: After v1.0 user feedback
