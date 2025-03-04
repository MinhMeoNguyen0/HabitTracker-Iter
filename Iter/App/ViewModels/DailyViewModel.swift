import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel for managing daily habit view
@MainActor
class DailyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var habits: [Habit] = []
    @Published var completionStatus: [UUID: Bool] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let habitService: HabitService
    private var cancellables = Set<AnyCancellable>()
    private var selectedDate: Date
    
    // MARK: - Initialization
    nonisolated init(modelContext: ModelContext, selectedDate: Date = Date()) {
        self.habitService = HabitService(modelContext: modelContext)
        self.selectedDate = selectedDate
        
        // Load initial data
        Task { @MainActor in
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
        selectedDate = newDate
        Task {
            await loadHabits()
        }
    }
    
    /// Toggles the completion status of a habit
    func toggleHabitCompletion(_ habit: Habit) async {
        do {
            let isCompleted = try await habitService.isHabitCompleted(habit, on: selectedDate)
            
            // Update local completion status immediately for better UI responsiveness
            completionStatus[habit.id] = !isCompleted
            
            // Then perform the actual toggle operation
            if isCompleted {
                try await habitService.uncompleteHabit(habit, on: selectedDate)
            } else {
                try await habitService.completeHabit(habit, on: selectedDate)
            }
        } catch {
            // If there was an error, revert the local change
            if let currentStatus = completionStatus[habit.id] {
                completionStatus[habit.id] = !currentStatus
            }
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
    
    // MARK: - Private Methods
    
    /// Loads habits and their completion status for the selected date
    private func loadHabits() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Fetch all habits
            let fetchedHabits = try await habitService.fetchHabits()
            
            var newCompletionMap: [UUID: Bool] = [:]
            
            // Check completion status for each habit
            for habit in fetchedHabits {
                let isCompleted = try await habitService.isHabitCompleted(habit, on: selectedDate)
                newCompletionMap[habit.id] = isCompleted
            }
            
            // Update published properties on the main thread
            self.habits = fetchedHabits
            self.completionStatus = newCompletionMap
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load habits: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
} 