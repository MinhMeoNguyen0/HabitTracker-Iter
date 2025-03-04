import SwiftData
import Foundation
import SwiftUI

extension ModelContext: @unchecked @retroactive Sendable {}

actor HabitService {
    let modelContext: ModelContext
    private let calendar = Calendar.current
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createHabit(title: String, type: HabitType) async throws -> Habit {
        let habit = Habit(title: title, type: type)
        modelContext.insert(habit)
        try modelContext.save()
        return habit
    }
    
    func completeHabit(_ habit: Habit, on date: Date) async throws {
        let completion = HabitCompletion(habit: habit, date: date, isCompleted: true)
        modelContext.insert(completion)
        try modelContext.save()
    }
    
    func uncompleteHabit(_ habit: Habit, on date: Date) async throws {
        let startOfDay = DateUtils.startOfDay(for: date)
        guard let endOfDay = DateUtils.endOfDay(for: date) else {
            throw PageViewError.invalidDateCalculation
        }
        
        // Extract the habit ID to avoid nested property access
        let habitId = habit.id
        
        do {
            // Use simple predicate compatible with SwiftData
            let descriptor = FetchDescriptor<HabitCompletion>(
                predicate: #Predicate<HabitCompletion> { completion in
                    // Access habit.id directly rather than through a nested path
                    completion.habit.id == habitId &&
                    completion.date >= startOfDay &&
                    completion.date < endOfDay
                }
            )
            
            let completionsToDelete = try modelContext.fetch(descriptor)
            completionsToDelete.forEach { modelContext.delete($0) }
        } catch {
            print("Error in uncompleteHabit: \(error)")
            // Fall back to fetching all and filtering
            let allCompletions = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
            let completionsToDelete = allCompletions.filter {
                $0.habit.id == habitId &&
                $0.date >= startOfDay &&
                $0.date < endOfDay
            }
            completionsToDelete.forEach { modelContext.delete($0) }
        }
        
        try modelContext.save()
    }
    
    func isHabitCompleted(_ habit: Habit, on date: Date) async throws -> Bool {
        let startOfDay = DateUtils.startOfDay(for: date)
        guard let endOfDay = DateUtils.endOfDay(for: date) else {
            throw PageViewError.invalidDateCalculation
        }
        
        // Extract the habit ID to avoid nested property access
        let habitId = habit.id
        
        do {
            // Use a simplified predicate format compatible with SwiftData
            var descriptor = FetchDescriptor<HabitCompletion>(
                predicate: #Predicate<HabitCompletion> { completion in
                    // Access habit.id directly rather than through a nested path
                    completion.habit.id == habitId &&
                    completion.date >= startOfDay &&
                    completion.date < endOfDay
                }
            )
            descriptor.fetchLimit = 1
            
            let matchingCompletions = try modelContext.fetch(descriptor)
            return !matchingCompletions.isEmpty
        } catch {
            print("Error in isHabitCompleted: \(error)")
            // Fall back to a manual check if predicate fails
            let allCompletions = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
            return allCompletions.contains {
                $0.habit.id == habitId &&
                $0.date >= startOfDay &&
                $0.date < endOfDay
            }
        }
    }
    
    func toggleHabitCompletion(_ habit: Habit, on date: Date) async throws {
        if try await isHabitCompleted(habit, on: date) {
            try await uncompleteHabit(habit, on: date)
        } else {
            try await completeHabit(habit, on: date)
        }
    }
    
    func fetchHabits() async throws -> [Habit] {
        let descriptor = FetchDescriptor<Habit>()
        return try modelContext.fetch(descriptor)
    }
    
    func fetchHabitsForDate(_ date: Date) async throws -> [Habit] {
        guard let dateRange = DateUtils.getDateRange(for: TimelineZoomLevel.day, from: date) else {
            return []
        }
        return try await fetchHabitsForTimeRange(start: dateRange.start, end: dateRange.end)
    }
    
    func fetchHabitsForTimeRange(start: Date, end: Date) async throws -> [Habit] {
        // Extract date variables to use directly in the predicate
        let startDate = start
        let endDate = end
        
        var filteredCompletions: [HabitCompletion] = []
        
        do {
            // Use simple predicate compatible with SwiftData
            let descriptor = FetchDescriptor<HabitCompletion>(
                predicate: #Predicate<HabitCompletion> { completion in
                    completion.date >= startDate && completion.date <= endDate
                }
            )
            
            filteredCompletions = try modelContext.fetch(descriptor)
        } catch {
            print("Error in fetchHabitsForTimeRange: \(error)")
            // Fall back to fetching all and filtering
            let allCompletions = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
            filteredCompletions = allCompletions.filter {
                $0.date >= startDate && $0.date <= endDate
            }
        }
        
        let completedHabitIds = Dictionary(grouping: filteredCompletions) { completion in
            completion.habit.id
        }
        
        let habits = try modelContext.fetch(FetchDescriptor<Habit>())
        
        return habits.map { habit in
            let habitCopy = habit
            habitCopy.completions = completedHabitIds[habit.id] ?? []
            return habitCopy
        }
    }
    
    func fetchCompletionStats(for habit: Habit, in timeRange: TimelineZoomLevel, from date: Date) async throws -> [Date: Bool] {
        guard let dateRange = DateUtils.getDateRange(for: timeRange, from: date) else {
            return [:]
        }
        
        // Extract the habit ID to avoid nested property access
        let habitId = habit.id
        
        // Extract date range boundaries into standalone variables
        let rangeStart = dateRange.start
        let rangeEnd = dateRange.end
        
        var filteredCompletions: [HabitCompletion] = []
        
        do {
            // Use simple predicate compatible with SwiftData
            let descriptor = FetchDescriptor<HabitCompletion>(
                predicate: #Predicate<HabitCompletion> { completion in
                    // Access habit.id directly rather than through a nested path
                    completion.habit.id == habitId && 
                    completion.date >= rangeStart && 
                    completion.date <= rangeEnd
                }
            )
            
            filteredCompletions = try modelContext.fetch(descriptor)
        } catch {
            print("Error in fetchCompletionStats: \(error)")
            // Fall back to fetching all and filtering
            let allCompletions = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
            filteredCompletions = allCompletions.filter {
                $0.habit.id == habitId &&
                $0.date >= rangeStart &&
                $0.date <= rangeEnd
            }
        }
        
        let completedDates = Set(filteredCompletions.map { DateUtils.startOfDay(for: $0.date) })
        
        var stats: [Date: Bool] = [:]
        var currentDate = rangeStart
        
        while currentDate <= rangeEnd {
            stats[currentDate] = completedDates.contains(DateUtils.startOfDay(for: currentDate))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return stats
    }
    
    func deleteHabit(_ habit: Habit) async throws {
        modelContext.delete(habit)
        try modelContext.save()
    }
    
    func updateHabit(_ habit: Habit) async throws {
        try modelContext.save()
    }
}
