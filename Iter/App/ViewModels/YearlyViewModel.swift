import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel for managing yearly habit view (read-only)
@MainActor
class YearlyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var habits: [Habit] = []
    @Published var yearDays: [Date] = []
    @Published var completionStatus: [UUID: [Date: Bool]] = [:]
    @Published var streaks: [UUID: Int] = [:]
    @Published var completionRates: [UUID: Double] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let habitService: HabitService
    private var cancellables = Set<AnyCancellable>()
    private var selectedYear: Date
    
    // MARK: - Initialization
    init(modelContext: ModelContext, selectedYear: Date = Date()) {
        self.habitService = HabitService(modelContext: modelContext)
        self.selectedYear = selectedYear
        
        // Load initial data
        Task {
            await loadYearData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Updates the selected year and reloads habits
    func updateYear(to newYear: Date) {
        selectedYear = newYear
        Task {
            await loadYearData()
        }
    }
    
    /// Refreshes the year data
    func refreshData() async {
        await loadYearData()
    }
    
    // MARK: - Private Methods
    
    /// Loads year data including habits and their completion status
    private func loadYearData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Calculate year days
            let yearDays = calculateYearDays(from: selectedYear)
            let today = Date()
            
            // Fetch habits
            let fetchedHabits = try await habitService.fetchHabits()
            var newCompletionMap: [UUID: [Date: Bool]] = [:]
            var newStreakMap: [UUID: Int] = [:]
            var newRateMap: [UUID: Double] = [:]
            
            // Process each habit's completion status for the year
            for habit in fetchedHabits {
                var habitCompletions: [Date: Bool] = [:]
                
                // Only check completion status for days up to today
                for day in yearDays where day <= today {
                    let isCompleted = try await habitService.isHabitCompleted(habit, on: day)
                    habitCompletions[day] = isCompleted
                }
                
                // For future dates, mark as not completed without checking
                for day in yearDays where day > today {
                    habitCompletions[day] = false
                }
                
                newCompletionMap[habit.id] = habitCompletions
                
                // Calculate streak and completion rate
                newStreakMap[habit.id] = calculateCurrentStreak(completions: habitCompletions)
                newRateMap[habit.id] = calculateCompletionRate(completions: habitCompletions)
            }
            
            self.yearDays = yearDays
            self.habits = fetchedHabits
            self.completionStatus = newCompletionMap
            self.streaks = newStreakMap
            self.completionRates = newRateMap
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load year data: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Calculates all days in the year containing the selected date
    private func calculateYearDays(from date: Date) -> [Date] {
        let calendar = Calendar.current
        
        // Get the first day of the year
        guard let firstDayOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)) else {
            return []
        }
        
        // Determine if it's a leap year
        let year = calendar.component(.year, from: date)
        let isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        let daysInYear = isLeapYear ? 366 : 365
        
        // Generate dates for each day of the year
        return (0..<daysInYear).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: firstDayOfYear)
        }
    }
    
    /// Calculates the current streak for a habit
    private func calculateCurrentStreak(completions: [Date: Bool]) -> Int {
        let today = Date()
        let sortedDates = completions.keys.sorted(by: >)
        var streak = 0
        
        for date in sortedDates where date <= today {
            if let isCompleted = completions[date], isCompleted {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Calculates the completion rate for a habit
    private func calculateCompletionRate(completions: [Date: Bool]) -> Double {
        let today = Date()
        let pastCompletions = completions.filter { $0.key <= today }
        
        guard !pastCompletions.isEmpty else { return 0.0 }
        
        let completedCount = pastCompletions.values.filter { $0 }.count
        return Double(completedCount) / Double(pastCompletions.count)
    }
    
    /// Gets the color for a completion rate
    func colorForCompletionRate(_ rate: Double) -> Color {
        switch rate {
        case 0..<0.25:
            return .red
        case 0.25..<0.5:
            return .orange
        case 0.5..<0.75:
            return .yellow
        case 0.75...1.0:
            return .green
        default:
            return .gray
        }
    }
} 