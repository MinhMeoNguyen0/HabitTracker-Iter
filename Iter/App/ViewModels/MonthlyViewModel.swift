import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel for managing monthly habit view
@MainActor
class MonthlyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var habits: [Habit] = []
    @Published var monthDays: [Date] = []
    @Published var completionStatus: [UUID: [Date: Bool]] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedDay: Date?
    
    // MARK: - Private Properties
    private let habitService: HabitService
    private var cancellables = Set<AnyCancellable>()
    private var selectedMonth: Date
    private var previousHabits: [Habit] = [] // Store previous habits to prevent flashing
    
    // MARK: - Initialization
    init(modelContext: ModelContext, selectedMonth: Date = Date()) {
        self.habitService = HabitService(modelContext: modelContext)
        self.selectedMonth = selectedMonth
        
        // Load initial data
        Task {
            await loadMonthData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Gets the currently selected month
    func getSelectedMonth() -> Date {
        return selectedMonth
    }
    
    /// Updates the selected month and reloads habits
    func updateMonth(to newMonth: Date) {
        selectedMonth = newMonth
        selectedDay = nil
        Task {
            await loadMonthData()
        }
    }
    
    /// Selects a specific day in the month
    func selectDay(_ day: Date) {
        selectedDay = day
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
    
    /// Refreshes the month data
    func refreshData() async {
        await loadMonthData()
    }
    
    // MARK: - Private Methods
    
    /// Loads month data including habits and their completion status
    private func loadMonthData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        // Store current habits as previous habits before loading new data
        if !habits.isEmpty {
            previousHabits = habits
        }
        
        do {
            // Calculate month days
            let monthDays = calculateMonthDays(from: selectedMonth)
            
            // Fetch habits
            let fetchedHabits = try await habitService.fetchHabits()
            var newCompletionMap: [UUID: [Date: Bool]] = [:]
            
            // Check completion status for each habit on each day of the month
            for habit in fetchedHabits {
                var habitCompletions: [Date: Bool] = [:]
                
                for day in monthDays {
                    let isCompleted = try await habitService.isHabitCompleted(habit, on: day)
                    habitCompletions[day] = isCompleted
                }
                
                newCompletionMap[habit.id] = habitCompletions
            }
            
            self.monthDays = monthDays
            self.habits = fetchedHabits
            self.completionStatus = newCompletionMap
            self.previousHabits = [] // Clear previous habits after successful load
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load month data: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Calculates all days in the month containing the selected date
    private func calculateMonthDays(from date: Date) -> [Date] {
        let calendar = Calendar.current
        
        // Get the range of days in the month
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        // Generate dates for each day of the month
        return (1...monthRange.count).compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)
        }
    }
    
    /// Gets the completion rate for a habit in the current month
    func completionRate(for habit: UUID) -> Double {
        guard let habitCompletions = completionStatus[habit], !habitCompletions.isEmpty else {
            return 0.0
        }
        
        let completedCount = habitCompletions.values.filter { $0 }.count
        return Double(completedCount) / Double(habitCompletions.count)
    }
    
    /// Returns habits to display (either current or previous if loading)
    var habitsToDisplay: [Habit] {
        return isLoading && habits.isEmpty && !previousHabits.isEmpty ? previousHabits : habits
    }
} 