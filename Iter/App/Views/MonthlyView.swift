import SwiftUI

/// View for displaying and managing monthly habits
struct MonthlyView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: MonthlyViewModel
    
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
                        VStack(spacing: Constants.UI.Spacing.list) {
                            ForEach(viewModel.habitsToDisplay) { habit in
                                MonthlyHabitRow(
                                    habit: habit,
                                    dates: calendarDays().compactMap { $0 },
                                    completionStatus: viewModel.completionStatus[habit.id] ?? [:],
                                    onToggle: { date in
                                        Task {
                                            await viewModel.toggleHabitCompletion(habit, for: date)
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
    
    // MARK: - Helper Methods
    
    /// Generates calendar days including padding for the month view
    private func calendarDays() -> [Date?] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.getSelectedMonth())) else {
            return []
        }
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: viewModel.getSelectedMonth())?.count ?? 0
        
        // Add the actual days of the month
        var days: [Date?] = []
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Pad to fill complete rows (10 cells per row)
        let numberOfRows = Int(ceil(Double(daysInMonth) / Double(Constants.UI.Grid.monthCellsPerRow)))
        let totalCells = numberOfRows * Constants.UI.Grid.monthCellsPerRow
        let padding = Array(repeating: nil as Date?, count: max(0, totalCells - daysInMonth))
        
        return days + padding
    }
}

/// Row displaying a habit's monthly completion status
struct MonthlyHabitRow: View {
    // MARK: - Properties
    let habit: Habit
    let dates: [Date]
    let completionStatus: [Date: Bool]
    let onToggle: (Date) -> Void
    
    // Calculate completion percentage
    private var completionPercentage: Int {
        let completedDays = dates.filter { date in
            date <= Date() && (completionStatus[date] ?? false)
        }.count
        
        let totalDays = dates.filter { $0 <= Date() }.count
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Constants.UI.Spacing.month), count: Constants.UI.Grid.monthCellsPerRow), spacing: Constants.UI.Spacing.month) {
                ForEach(dates, id: \.self) { date in
                    Button(action: {
                        // Only allow toggling dates up to today
                        if date <= Date() {
                            onToggle(date)
                        }
                    }) {
                        RoundedRectangle(cornerRadius: Constants.UI.Corner.small)
                            .fill(completionStatus[date] ?? false ? habit.type.color : Color.gray.opacity(0.2))
                            .frame(width: Constants.UI.BoxSize.month, height: Constants.UI.BoxSize.month)
                            .opacity(date > Date() ? 0.3 : 1.0) // Dim future dates
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(date > Date()) // Disable future dates
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.Corner.large)
    }
}

// Preview removed as requested 
