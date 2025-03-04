import Foundation
import SwiftUI
import SwiftData
import Combine

/// Main ViewModel for habit tracking functionality
/// Manages global habit state and provides data to all habit-related views
@MainActor
class HabitsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var viewState: PageViewState
    @Published var habits: [Habit] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Public Properties
    /// Provides access to the model context for child view models
    var modelContext: ModelContext {
        habitService.modelContext
    }
    
    // MARK: - Private Properties
    private let habitService: HabitService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(modelContext: ModelContext, initialDate: Date = Date(), initialZoomLevel: TimelineZoomLevel = .day) {
        self.habitService = HabitService(modelContext: modelContext)
        self.viewState = PageViewState(
            selectedDate: initialDate,
            currentZoomLevel: initialZoomLevel
        )
        
        // Load initial data
        Task {
            await loadHabits()
        }
    }
    
    // MARK: - Public Methods
    
    /// Refreshes data by reloading habits
    func refreshData() async {
        await loadHabits()
    }
    
    /// Updates the selected date and reloads habits
    func updateDate(to newDate: Date) {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Calculate the maximum allowed date based on zoom level
        let maxAllowedDate: Date
        switch viewState.currentZoomLevel {
        case .day:
            maxAllowedDate = calendar.date(byAdding: .day, value: -Constants.Time.maxDaysBack, to: currentDate) ?? currentDate
        case .week:
            maxAllowedDate = calendar.date(byAdding: .weekOfYear, value: -Constants.Time.maxWeeksBack, to: currentDate) ?? currentDate
        case .month:
            maxAllowedDate = calendar.date(byAdding: .month, value: -Constants.Time.maxMonthsBack, to: currentDate) ?? currentDate
        case .year:
            maxAllowedDate = calendar.date(byAdding: .year, value: -Constants.Time.maxYearsBack, to: currentDate) ?? currentDate
        }
        
        // If date would go beyond max allowed, use max allowed date
        // If date is in future, use current date
        let dateToUse: Date
        if newDate > currentDate {
            dateToUse = currentDate
        } else if newDate < maxAllowedDate {
            dateToUse = maxAllowedDate
        } else {
            dateToUse = newDate
        }
        
        viewState.selectedDate = dateToUse
        Task {
            await loadHabits()
        }
    }
    
    /// Updates the zoom level and reloads habits
    func updateZoomLevel(to newZoomLevel: TimelineZoomLevel) {
        viewState.currentZoomLevel = newZoomLevel
        Task {
            await loadHabits()
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
            
            // Reload habits to reflect changes
            await loadHabits()
        } catch {
            self.errorMessage = "Failed to toggle habit: \(error.localizedDescription)"
        }
    }
    
    /// Creates a new habit
    func createHabit(title: String, type: HabitType) async {
        do {
            _ = try await habitService.createHabit(title: title, type: type)
            await loadHabits()
        } catch {
            self.errorMessage = "Failed to create habit: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to the previous time period based on current zoom level
    func navigateToPrevious() {
        let newDate: Date
        
        switch viewState.currentZoomLevel {
        case .day:
            newDate = Calendar.current.date(byAdding: .day, value: -1, to: viewState.selectedDate) ?? viewState.selectedDate
        case .week:
            newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: viewState.selectedDate) ?? viewState.selectedDate
        case .month:
            newDate = Calendar.current.date(byAdding: .month, value: -1, to: viewState.selectedDate) ?? viewState.selectedDate
        case .year:
            newDate = Calendar.current.date(byAdding: .year, value: -1, to: viewState.selectedDate) ?? viewState.selectedDate
        }
        
        updateDate(to: newDate)
    }
    
    /// Navigate to the next time period based on current zoom level
    func navigateToNext() {
        let newDate: Date
        
        switch viewState.currentZoomLevel {
        case .day:
            newDate = Calendar.current.date(byAdding: .day, value: 1, to: viewState.selectedDate) ?? viewState.selectedDate
        case .week:
            newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: viewState.selectedDate) ?? viewState.selectedDate
        case .month:
            newDate = Calendar.current.date(byAdding: .month, value: 1, to: viewState.selectedDate) ?? viewState.selectedDate
        case .year:
            newDate = Calendar.current.date(byAdding: .year, value: 1, to: viewState.selectedDate) ?? viewState.selectedDate
        }
        
        // Prevent navigation to future dates
        if newDate <= Date() {
            updateDate(to: newDate)
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads habits based on current date and zoom level
    private func loadHabits() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let fetchedHabits = try await habitService.fetchHabits()
            self.habits = fetchedHabits
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load habits: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
} 