import SwiftUI

/// View for displaying and managing weekly habits
struct WeeklyView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: WeeklyViewModel
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
         
                } else {
                    ScrollView {
                        VStack(spacing: Constants.UI.Spacing.week) {
                            ForEach(viewModel.habitsToDisplay) { habit in
                                WeeklyHabitRow(
                                    habit: habit,
                                    days: viewModel.weekDays,
                                    completionStatus: viewModel.completionStatus[habit.id] ?? [:],
                                    onToggle: { day in
                                        Task {
                                            await viewModel.toggleHabitCompletion(habit, for: day)
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
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { errorWrapper in
            Alert(
                title: Text("Error"),
                message: Text(errorWrapper.error),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(Color(.systemBackground))
    }
}

/// Row displaying a habit's completion status for each day of the week
struct WeeklyHabitRow: View {
    // MARK: - Properties
    let habit: Habit
    let days: [Date]
    let completionStatus: [Date: Bool]
    let onToggle: (Date) -> Void
    
    // Calculate completion percentage
    private var completionPercentage: Int {
        let completedDays = days.filter { day in
            day <= Date() && (completionStatus[day] ?? false)
        }.count
        
        let totalDays = days.filter { $0 <= Date() }.count
        return totalDays > 0 ? Int(Double(completedDays) / Double(totalDays) * 100) : 0
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Habit title and completion percentage
            HStack {
                Circle()
                    .fill(habit.type.color)
                    .frame(width: 12, height: 12)
                
                Text(habit.title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(completionPercentage)%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Heatmap grid
            HStack(spacing: Constants.UI.Spacing.week) {
                ForEach(days, id: \.self) { day in
                    Button(action: {
                        // Only allow toggling dates up to today
                        if day <= Date() {
                            onToggle(day)
                        }
                    }) {
                        RoundedRectangle(cornerRadius: Constants.UI.Corner.small)
                            .fill(completionStatus[day] ?? false ? habit.type.color : Color.gray.opacity(0.2))
                            .frame(width: Constants.UI.BoxSize.week, height: Constants.UI.BoxSize.week)
                            .opacity(day > Date() ? 0.3 : 1.0) // Dim future dates
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(day > Date()) // Disable future dates
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.Corner.large)
    }
}

// Preview removed as requested 