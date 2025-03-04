import SwiftUI
import SwiftData

/// Central navigation hub for the habit tracking interface
/// This is the ONLY view that handles date navigation and zoom level selection
struct HabitsContainerView: View {
    // MARK: - Properties
    @StateObject private var viewModel: HabitsViewModel
    @StateObject private var zoomLevelViewModel: ZoomLevelViewModel
    @StateObject private var dailyViewModel: DailyViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // Independent view state for each zoom level
    @State private var dayViewDate: Date = Date()
    @State private var weekViewDate: Date = Date()
    @State private var monthViewDate: Date = Date()
    @State private var yearViewDate: Date = Date()
    
    // Add habit sheet state
    @State private var isAddHabitSheetPresented = false
    @State private var newHabitTitle: String = ""
    @State private var newHabitType: HabitType = .good
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        let habitsVM = HabitsViewModel(modelContext: modelContext)
        
        // Create the refresh callback
        let refreshCallback = {
            await habitsVM.refreshData()
            
            // Also refresh the daily view model if we're in day view
            if habitsVM.viewState.currentZoomLevel == .day {
                // We'll access this via the dailyViewModel property later
            }
        }
        
        _viewModel = StateObject(wrappedValue: habitsVM)
        _zoomLevelViewModel = StateObject(wrappedValue: ZoomLevelViewModel(onRefresh: refreshCallback))
        _dailyViewModel = StateObject(wrappedValue: DailyViewModel(modelContext: modelContext, selectedDate: habitsVM.viewState.selectedDate))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with date navigation
                VStack(spacing: 8) {
                    // Date navigation
                    HStack {
                        Button(action: {
                            navigateToPrevious()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Current date display
                        VStack(spacing: 4) {
                            Text(formattedDate)
                                .font(.headline)
                            
                            PageIndicatorView(
                                zoomLevel: viewModel.viewState.currentZoomLevel,
                                date: currentDateForZoomLevel
                            )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            navigateToNext()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        .disabled(isNextButtonDisabled)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Main content area with gesture support for navigation
                ZStack {
                    // Current view based on zoom level
                    Group {
                        switch viewModel.viewState.currentZoomLevel {
                        case .day:
                            DailyView(viewModel: dailyViewModel)
                        case .week:
                            WeeklyView(
                                viewModel: WeeklyViewModel(
                                    modelContext: viewModel.modelContext,
                                    selectedDate: weekViewDate
                                )
                            )
                        case .month:
                            MonthlyView(
                                viewModel: MonthlyViewModel(
                                    modelContext: viewModel.modelContext,
                                    selectedMonth: monthViewDate
                                )
                            )
                        case .year:
                            YearlyView(
                                viewModel: YearlyViewModel(
                                    modelContext: viewModel.modelContext,
                                    selectedYear: yearViewDate
                                )
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                }
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                withAnimation {
                                    if dragOffset > threshold {
                                        navigateToPrevious()
                                    } else if dragOffset < -threshold && !isNextButtonDisabled {
                                        navigateToNext()
                                    }
                                    dragOffset = 0
                                    isDragging = false
                                }
                            }
                    )
                }
                .onChange(of: viewModel.viewState.currentZoomLevel) { _, newZoomLevel in
                    // Update the view model's selected date based on the current zoom level's date
                    updateViewModelDate()
                }
            }
            
            // Floating add button
            .overlay {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isAddHabitSheetPresented = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 65, height: 65)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Add Habit")
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .withCompactMenu(
            zoomLevelViewModel: zoomLevelViewModel,
            onRefresh: {
                Task {
                    await viewModel.refreshData()
                    
                    // Also refresh the daily view model if we're in day view
                    if viewModel.viewState.currentZoomLevel == .day {
                        await dailyViewModel.refreshData()
                    }
                }
            }
        )
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert(
            item: Binding<ErrorWrapper?>(
                get: {
                    if let errorMessage = viewModel.errorMessage {
                        return ErrorWrapper(error: errorMessage)
                    }
                    return nil
                },
                set: { _ in
                    viewModel.errorMessage = nil
                }
            )
        ) { errorWrapper in
            Alert(
                title: Text("Error"),
                message: Text(errorWrapper.error),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: zoomLevelViewModel.currentZoomLevel) { _, newValue in
            viewModel.updateZoomLevel(to: newValue)
        }
        // Update DailyViewModel when day view date changes
        .onChange(of: dayViewDate) { _, newDate in
            if viewModel.viewState.currentZoomLevel == .day {
                dailyViewModel.updateDate(to: newDate)
            }
        }
        // Add habit sheet
        .sheet(isPresented: $isAddHabitSheetPresented) {
            AddHabitView(
                newHabitTitle: $newHabitTitle,
                newHabitType: $newHabitType,
                onAdd: {
                    Task {
                        // Create habit using the current view model's context
                        let habitService = HabitService(modelContext: viewModel.modelContext)
                        do {
                            _ = try await habitService.createHabit(title: newHabitTitle, type: newHabitType)
                            // Reset form
                            newHabitTitle = ""
                            newHabitType = .good
                            isAddHabitSheetPresented = false
                            
                            // Refresh the current view if needed
                            await viewModel.refreshData()
                            
                            // Also refresh the daily view model
                            await dailyViewModel.refreshData()
                        } catch {
                            viewModel.errorMessage = "Failed to create habit: \(error.localizedDescription)"
                        }
                    }
                },
                onCancel: {
                    isAddHabitSheetPresented = false
                    newHabitTitle = ""
                    newHabitType = .good
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get the current date for the active zoom level
    private var currentDateForZoomLevel: Date {
        switch viewModel.viewState.currentZoomLevel {
        case .day:
        return dayViewDate
        case .week:
            return weekViewDate
        case .month:
            return monthViewDate
        case .year:
            return yearViewDate
        }
    }
    
    /// Formatted date string based on current zoom level
    private var formattedDate: String {
        let date = currentDateForZoomLevel
        let formatter = DateFormatter()
        
        switch viewModel.viewState.currentZoomLevel {
        case .day:
            formatter.dateStyle = .full
            return formatter.string(from: date)
            
        case .week:
            guard let weekRange = DateUtils.getWeekStartAndEnd(for: date) else {
                return "Week of \(DateFormatter.monthDayFormatter.string(from: date))"
            }
            
            let startMonth = Calendar.current.component(.month, from: weekRange.start)
            let endMonth = Calendar.current.component(.month, from: weekRange.end)
            
            if startMonth == endMonth {
                // Same month
                return "\(DateFormatter.monthFormatter.string(from: weekRange.start)) \(Calendar.current.component(.day, from: weekRange.start))-\(Calendar.current.component(.day, from: weekRange.end))"
            } else {
                // Different months
                return "\(DateFormatter.monthDayFormatter.string(from: weekRange.start)) - \(DateFormatter.monthDayFormatter.string(from: weekRange.end))"
            }
            
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
            
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: date)
        }
    }
    
    /// Determines if the next button should be disabled (can't navigate to future)
    private var isNextButtonDisabled: Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        let selectedDate = currentDateForZoomLevel
        
        switch viewModel.viewState.currentZoomLevel {
        case .day:
            return calendar.isDateInToday(selectedDate) || selectedDate > currentDate
            
        case .week:
            guard let weekRange = DateUtils.getWeekStartAndEnd(for: selectedDate) else {
                return false
            }
            return weekRange.end >= currentDate
            
        case .month:
            let selectedMonth = calendar.component(.month, from: selectedDate)
            let selectedYear = calendar.component(.year, from: selectedDate)
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentYear = calendar.component(.year, from: currentDate)
            
            return (selectedYear == currentYear && selectedMonth >= currentMonth) || selectedYear > currentYear
            
        case .year:
            let selectedYear = calendar.component(.year, from: selectedDate)
            let currentYear = calendar.component(.year, from: currentDate)
            return selectedYear >= currentYear
        }
    }
    
    // MARK: - Private Methods
    
    /// Navigate to the previous time period based on current zoom level
    private func navigateToPrevious() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Calculate the maximum allowed date based on zoom level
        let maxAllowedDate: Date
        switch viewModel.viewState.currentZoomLevel {
        case .day:
            maxAllowedDate = calendar.date(byAdding: .day, value: -Constants.Time.maxDaysBack, to: currentDate) ?? currentDate
        case .week:
            maxAllowedDate = calendar.date(byAdding: .weekOfYear, value: -Constants.Time.maxWeeksBack, to: currentDate) ?? currentDate
        case .month:
            maxAllowedDate = calendar.date(byAdding: .month, value: -Constants.Time.maxMonthsBack, to: currentDate) ?? currentDate
        case .year:
            maxAllowedDate = calendar.date(byAdding: .year, value: -Constants.Time.maxYearsBack, to: currentDate) ?? currentDate
        }
        
        // Calculate the new date
        let newDate: Date
        switch viewModel.viewState.currentZoomLevel {
        case .day:
            newDate = calendar.date(byAdding: .day, value: -1, to: dayViewDate) ?? dayViewDate
        case .week:
            newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: weekViewDate) ?? weekViewDate
        case .month:
            newDate = calendar.date(byAdding: .month, value: -1, to: monthViewDate) ?? monthViewDate
        case .year:
            newDate = calendar.date(byAdding: .year, value: -1, to: yearViewDate) ?? yearViewDate
        }
        
        // If new date would go beyond max allowed, jump directly to max allowed
        let dateToUse = newDate < maxAllowedDate ? maxAllowedDate : newDate
        
        switch viewModel.viewState.currentZoomLevel {
        case .day:
            dayViewDate = dateToUse
        case .week:
            weekViewDate = dateToUse
        case .month:
            monthViewDate = dateToUse
        case .year:
            yearViewDate = dateToUse
        }
        
        // Update the view model's selected date
        updateViewModelDate()
    }
    
    /// Navigate to the next time period based on current zoom level
    private func navigateToNext() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Calculate the new date
        let newDate: Date
        switch viewModel.viewState.currentZoomLevel {
        case .day:
            newDate = calendar.date(byAdding: .day, value: 1, to: dayViewDate) ?? dayViewDate
        case .week:
            newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekViewDate) ?? weekViewDate
        case .month:
            newDate = calendar.date(byAdding: .month, value: 1, to: monthViewDate) ?? monthViewDate
        case .year:
            newDate = calendar.date(byAdding: .year, value: 1, to: yearViewDate) ?? yearViewDate
        }
        
        // Only update if the new date is not in the future
        if newDate <= currentDate {
            switch viewModel.viewState.currentZoomLevel {
            case .day:
                dayViewDate = newDate
            case .week:
                weekViewDate = newDate
            case .month:
                monthViewDate = newDate
            case .year:
                yearViewDate = newDate
            }
            
            // Update the view model's selected date
            updateViewModelDate()
        }
    }
    
    /// Update the view model's selected date based on the current zoom level
    private func updateViewModelDate() {
        viewModel.updateDate(to: currentDateForZoomLevel)
        
        // Update the daily view model if we're in day view
        if viewModel.viewState.currentZoomLevel == .day {
            dailyViewModel.updateDate(to: dayViewDate)
        }
    }
}

// MARK: - Helper Views

/// Header view displaying current date and zoom level
struct PageIndicatorView: View {
    let zoomLevel: TimelineZoomLevel
    let date: Date
    
    var body: some View {
        Text(indicatorText)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
    }
    
    private var indicatorText: String {
        let calendar = Calendar.current
        
        switch zoomLevel {
        case .day:
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
            let totalDays = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
            return "Day \(dayOfYear) of \(totalDays)"
            
        case .week:
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let totalWeeks = calendar.range(of: .weekOfYear, in: .year, for: date)?.count ?? 52
            return "Week \(weekOfYear) of \(totalWeeks)"
            
        case .month:
            let month = calendar.component(.month, from: date)
            return "Month \(month) of 12"
            
        case .year:
            return calendar.component(.year, from: date).description
        }
    }
}

/// View for adding a new habit
struct AddHabitView: View {
    // MARK: - Properties
    @Binding var newHabitTitle: String
    @Binding var newHabitType: HabitType
    let onAdd: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTitleFocused: Bool
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit Title", text: $newHabitTitle)
                        .focused($isTitleFocused)
                    
                    Picker("Habit Type", selection: $newHabitType) {
                        Text("Good Habit").tag(HabitType.good)
                        Text("Bad Habit").tag(HabitType.bad)
                        Text("Neutral Habit").tag(HabitType.neutral)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button("Add Habit") {
                        onAdd()
                    }
                    .disabled(newHabitTitle.isEmpty)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(newHabitTitle.isEmpty ? .gray : .accentColor)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

/// Wrapper for error messages
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
} 
