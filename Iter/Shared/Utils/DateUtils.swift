import Foundation
import OSLog

struct DateRange {
    let start: Date
    let end: Date
}

struct DateUtils {
    private static let logger = Logger(subsystem: "com.iter.habits", category: "DateUtils")
    static let calendar = Calendar.current
    
    // MARK: - Date Calculations
    
    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func startOfWeek(for date: Date) -> Date? {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
    }
    
    static func startOfMonth(for date: Date) -> Date? {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
    }
    
    static func startOfYear(for date: Date) -> Date? {
        calendar.date(from: calendar.dateComponents([.year], from: date))
    }
    
    static func endOfDay(for date: Date) -> Date? {
        calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
    }
    
    static func endOfWeek(for date: Date) -> Date? {
        guard let startOfWeek = startOfWeek(for: date) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek)
    }
    
    static func endOfMonth(for date: Date) -> Date? {
        guard let startOfMonth = startOfMonth(for: date),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return nil
        }
        
        let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth)
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth ?? date)
    }
    
    static func endOfYear(for date: Date) -> Date? {
        guard let startOfYear = startOfYear(for: date),
              let nextYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
            return nil
        }
        
        let endOfYear = calendar.date(byAdding: .day, value: -1, to: nextYear)
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfYear ?? date)
    }
    
    // MARK: - Date Formatting
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.Time.Format.date
        return formatter.string(from: date)
    }
    
    static func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.Time.Format.month
        return formatter.string(from: date)
    }
    
    static func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.Time.Format.year
        return formatter.string(from: date)
    }
    
    static func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.Time.Format.weekday
        return formatter.string(from: date)
    }
    
    // MARK: - Date Range Generation
    
    static func datesForWeek(containing date: Date) -> [Date] {
        guard let start = startOfWeek(for: date) else { return [] }
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: start)
        }
    }
    
    static func datesForMonth(containing date: Date) -> [Date] {
        guard let start = startOfMonth(for: date) else { return [] }
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        return (0..<daysInMonth).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: start)
        }
    }
    
    static func datesForYear(containing date: Date) -> [Date] {
        guard let start = startOfYear(for: date) else { return [] }
        return (0..<365).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: start)
        }
    }
    
    // MARK: - Date Range Calculations
    
    static func getDateRange(for timeRange: TimelineZoomLevel, from date: Date) -> DateRange? {
        logger.debug("Calculating date range for \(timeRange.title) from \(date)")
        
        switch timeRange {
        case .day:
            let start = startOfDay(for: date)
            guard let end = endOfDay(for: date) else {
                logger.error("Failed to calculate end of day for \(date)")
                return nil
            }
            return DateRange(start: start, end: end)
            
        case .week:
            guard let start = startOfWeek(for: date),
                  let end = endOfWeek(for: date) else {
                logger.error("Failed to calculate week range for \(date)")
                return nil
            }
            return DateRange(start: start, end: end)
            
        case .month:
            guard let start = startOfMonth(for: date),
                  let end = endOfMonth(for: date) else {
                logger.error("Failed to calculate month range for \(date)")
                return nil
            }
            return DateRange(start: start, end: end)
            
        case .year:
            guard let start = startOfYear(for: date),
                  let end = endOfYear(for: date) else {
                logger.error("Failed to calculate year range for \(date)")
                return nil
            }
            return DateRange(start: start, end: end)
        }
    }
    
    static func getWeekStartAndEnd(for date: Date) -> DateRange? {
        guard let start = startOfWeek(for: date),
              let end = endOfWeek(for: date) else {
            return nil
        }
        return DateRange(start: start, end: end)
    }
    
    static func datesForRange(_ timeRange: TimelineZoomLevel, from date: Date) -> [Date?] {
        switch timeRange {
        case .year:
            return datesForYearWithPadding(containing: date)
        case .month:
            return datesForMonthWithPadding(containing: date)
        case .week:
            return datesForWeek(containing: date).map { Optional($0) }
        case .day:
            return [date].map { Optional($0) }
        }
    }
    
    static func datesForYearWithPadding(containing date: Date) -> [Date?] {
        guard let yearStart = startOfYear(for: date),
              let nextYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: yearStart) + 1, month: 1, day: 1)),
              let yearEnd = calendar.date(byAdding: .day, value: -1, to: nextYear) else {
            return []
        }
        
        var iterationDate = yearStart
        var allDates: [Date] = []
        
        while iterationDate <= yearEnd {
            allDates.append(iterationDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: iterationDate) else { break }
            iterationDate = nextDate
        }
        
        // Pad to fill complete rows (45 cells per row, 8 rows)
        let totalCells = Constants.UI.Grid.yearCellsPerRow * Constants.UI.Grid.yearRows
        let padding = Array(repeating: nil as Date?, count: max(0, totalCells - allDates.count))
        return allDates.map { Optional($0) } + padding
    }
    
    static func datesForMonthWithPadding(containing date: Date) -> [Date?] {
        guard let monthStart = startOfMonth(for: date) else {
            return []
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let monthDates = (0..<daysInMonth).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monthStart)
        }
        
        // Pad to fill complete rows (10 cells per row)
        let numberOfRows = Int(ceil(Double(daysInMonth) / Double(Constants.UI.Grid.monthCellsPerRow)))
        let totalCells = numberOfRows * Constants.UI.Grid.monthCellsPerRow
        let padding = Array(repeating: nil as Date?, count: max(0, totalCells - daysInMonth))
        return monthDates.map { Optional($0) } + padding
    }
    
    // MARK: - Date Comparison
    
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    static func isSameWeek(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .weekOfYear)
    }
    
    static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }
    
    static func isSameYear(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .year)
    }
    
    // MARK: - Completion Calculations
    
    static func calculateCompletion(dates: [Date?], isCompletedFn: (Date) -> Bool) -> String {
        let totalDays = dates.compactMap { $0 }.count
        let completedDays = dates.compactMap { $0 }.filter { isCompletedFn($0) }.count
        let percentage = Double(completedDays) / Double(totalDays) * 100
        return String(format: "%.0f%%", percentage)
    }
    
    static func calculateDateForPage(_ page: Int, zoomLevel: TimelineZoomLevel, maxPages: Int) -> Date? {
        logger.debug("Calculating date for page \(page) with zoom level \(zoomLevel.title)")
        
        let dateComponent: Calendar.Component = switch zoomLevel {
            case .day: .day
            case .week: .weekOfYear
            case .month: .month
            case .year: .year
        }
        
        let offset = -(maxPages - page)
        guard let date = calendar.date(byAdding: dateComponent, value: offset, to: Date()) else {
            logger.error("Failed to calculate date for page \(page)")
            return nil
        }
        
        return date
    }
}

// MARK: - DateFormatter Extensions

extension DateFormatter {
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
} 