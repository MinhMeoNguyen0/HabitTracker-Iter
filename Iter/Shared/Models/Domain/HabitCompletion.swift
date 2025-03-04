import Foundation
import SwiftData

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var date: Date  // Normalized to start of day
    var isCompleted: Bool
    @Relationship var habit: Habit

    init(habit: Habit, date: Date, isCompleted: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.habit = habit
    }
} 
