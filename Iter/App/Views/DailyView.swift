import SwiftUI

/// View for displaying and managing daily habits
struct DailyView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: DailyViewModel
    
    // MARK: - Body
    var body: some View {
        // Using a NavigationStack to provide proper structure
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.habits.isEmpty {
                    NoHabitsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Show habits list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.habits) { habit in
                                HabitRowItem(
                                    habit: habit,
                                    isCompleted: viewModel.completionStatus[habit.id] ?? false,
                                    onToggle: {
                                        Task {
                                            await viewModel.toggleHabitCompletion(habit)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Daily Habits")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Refresh data when view appears
                Task {
                    await viewModel.refreshData()
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

/// Custom habit row item with improved tap handling
struct HabitRowItem: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Habit type indicator
                Circle()
                    .fill(habit.type.color)
                    .frame(width: 12, height: 12)
                
                // Habit title
                Text(habit.title)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                Spacer()
                
                // Completion indicator
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

