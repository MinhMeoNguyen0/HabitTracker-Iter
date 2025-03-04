import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel for managing weekly habit view
@MainActor
class WeeklyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var habits: [Habit] = []
    @Published var weekDays: [Date] = []
    @Published var completionStatus: [UUID: [Date: Bool]] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let habitService: HabitService
    private var cancellables = Set<AnyCancellable>()
    private var selectedDate: Date
    private var previousHabits: [Habit] = [] // Store previous habits to prevent flashing
    
    // MARK: - Initialization
    nonisolated init(modelContext: ModelContext, selectedDate: Date = Date()) {
        self.habitService = HabitService(modelContext: modelContext)
        self.selectedDate = selectedDate
        
        // Load initial data
        Task { @MainActor in
            await loadWeekData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Updates the selected date and reloads habits
    func updateDate(to newDate: Date) {
        selectedDate = newDate
        Task {
            await loadWeekData()
        }
    }
    
    /// Toggles the completion status of a habit for a specific date
    func toggleHabitCompletion(_ habit: Habit, for date: Date) async {
        do {
            let isCompleted = try await habitService.isHabitCompleted(habit, on: date)
            
            if isCompleted {
                try await habitService.uncompleteHabit(habit, on: date)
            } else {
                try await habitService.completeHabit(habit, on: date)
            }
            
            // Update local completion status
            if var habitCompletions = completionStatus[habit.id] {
                habitCompletions[date] = !isCompleted
                completionStatus[habit.id] = habitCompletions
            }
        } catch {
            self.errorMessage = "Failed to toggle habit: \(error.localizedDescription)"
        }
    }
    
    /// Refreshes the week data
    func refreshData() async {
        await loadWeekData()
    }
    
    // MARK: - Private Methods
    
    /// Loads week data including habits and their completion status
    private func loadWeekData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        // Store current habits as previous habits before loading new data
        if !habits.isEmpty {
            previousHabits = habits
        }
        
        do {
            // Calculate week days
            let weekDays = calculateWeekDays(from: selectedDate)
            
            // Fetch habits
            let fetchedHabits = try await habitService.fetchHabits()
            var newCompletionMap: [UUID: [Date: Bool]] = [:]
            
            // Check completion status for each habit on each day of the week
            for habit in fetchedHabits {
                var habitCompletions: [Date: Bool] = [:]
                
                for day in weekDays {
                    let isCompleted = try await habitService.isHabitCompleted(habit, on: day)
                    habitCompletions[day] = isCompleted
                }
                
                newCompletionMap[habit.id] = habitCompletions
            }
            
            self.weekDays = weekDays
            self.habits = fetchedHabits
            self.completionStatus = newCompletionMap
            self.previousHabits = [] // Clear previous habits after successful load
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load week data: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Calculates the days of the week containing the selected date
    private func calculateWeekDays(from date: Date) -> [Date] {
        let calendar = Calendar.current
        
        // Find the start of the week (Sunday or Monday depending on locale)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return []
        }
        
        // Generate dates for each day of the week
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    /// Returns habits to display (either current or previous if loading)
    var habitsToDisplay: [Habit] {
        return isLoading && habits.isEmpty && !previousHabits.isEmpty ? previousHabits : habits
    }
} 