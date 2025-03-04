import SwiftUI

/// View for displaying yearly habit statistics (read-only)
struct YearlyView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: YearlyViewModel
    
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
                            ForEach(viewModel.habits) { habit in
                                YearlyHabitRow(
                                    habit: habit,
                                    weeks: getWeeksFromYearDays(viewModel.yearDays),
                                    completionStatus: viewModel.completionStatus[habit.id] ?? [:]
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
    
    /// Group days into weeks for the yearly view
    private func getWeeksFromYearDays(_ days: [Date]) -> [[Date]] {
        let calendar = Calendar.current
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        var currentWeekNumber: Int?
        
        for day in days {
            let weekNumber = calendar.component(.weekOfYear, from: day)
            
            if currentWeekNumber != weekNumber {
                if !currentWeek.isEmpty {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
                currentWeekNumber = weekNumber
            }
            
            currentWeek.append(day)
        }
        
        // Add the last week
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }
        
        return weeks
    }
}

/// Row displaying a habit's yearly completion status (read-only)
struct YearlyHabitRow: View {
    // MARK: - Properties
    let habit: Habit
    let weeks: [[Date]]
    let completionStatus: [Date: Bool]
    
    // Calculate completion percentage
    private var completionPercentage: Int {
        let today = Date()
        let allDays = weeks.flatMap { $0 }
        
        // Only consider days up to today
        let pastDays = allDays.filter { $0 <= today }
        guard !pastDays.isEmpty else { return 0 }
        
        // Calculate completed days
        let completedDays = pastDays.filter { day in
            completionStatus[day] ?? false
        }
        
        // Calculate percentage
        let totalDays = pastDays.count
        let completedCount = completedDays.count
        let percentage = Int(Double(completedCount) / Double(totalDays) * 100)
        
        return percentage
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
            
            // Yearly heatmap using a simplified approach
            YearlyHeatmap(
                weeks: weeks,
                completionStatus: completionStatus,
                habitColor: habit.type.color
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.Corner.large)
    }
}

/// A simplified yearly heatmap view
struct YearlyHeatmap: View {
    // MARK: - Properties
    let weeks: [[Date]]
    let completionStatus: [Date: Bool]
    let habitColor: Color
    
    // Precomputed cell data
    private var cells: [YearlyCellModel]
    
    // MARK: - Initialization
    init(weeks: [[Date]], completionStatus: [Date: Bool], habitColor: Color) {
        self.weeks = weeks
        self.completionStatus = completionStatus
        self.habitColor = habitColor
        
        // Precompute all cell data
        let allDays = weeks.flatMap { $0 }
        let today = Date()
        var cellsData: [YearlyCellModel] = []
        
        // Create a fixed grid of 8x46 cells
        for row in 0..<8 {
            for col in 0..<46 {
                let index = row * 46 + col
                let id = UUID() // Unique ID for each cell
                
                if index < allDays.count {
                    let day = allDays[index]
                    let isCompleted = completionStatus[day] ?? false
                    let isInFuture = day > today
                    cellsData.append(YearlyCellModel(id: id, day: day, isCompleted: isCompleted, isInFuture: isInFuture))
                } else {
                    cellsData.append(YearlyCellModel(id: id, day: nil, isCompleted: false, isInFuture: false))
                }
            }
        }
        
        self.cells = cellsData
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: Constants.UI.Spacing.year) {
                // Create 8 rows
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: Constants.UI.Spacing.year) {
                        // Create 46 columns in each row
                        ForEach(0..<46, id: \.self) { col in
                            let index = row * 46 + col
                            if index < cells.count {
                                let cell = cells[index]
                                SimpleDayCell(cell: cell, habitColor: habitColor)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// Model for a yearly cell
struct YearlyCellModel: Identifiable {
    let id: UUID
    let day: Date?
    let isCompleted: Bool
    let isInFuture: Bool
}

/// A simplified day cell view
struct SimpleDayCell: View {
    let cell: YearlyCellModel
    let habitColor: Color
    
    var body: some View {
        if cell.day != nil {
            RoundedRectangle(cornerRadius: Constants.UI.Corner.large)
                .fill(cell.isCompleted ? habitColor : Color.gray.opacity(0.2))
                .frame(width: Constants.UI.BoxSize.year, height: Constants.UI.BoxSize.year)
                .opacity(cell.isInFuture ? 0.3 : 1.0)
        } else {
            RoundedRectangle(cornerRadius: Constants.UI.Corner.large)
                .fill(Color.clear)
                .frame(width: Constants.UI.BoxSize.year, height: Constants.UI.BoxSize.year)
        }
    }
}

// Preview removed as requested 
