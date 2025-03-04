import SwiftUI
import SwiftData

// MARK: - PageViewModel
class PageViewModel: ObservableObject {
    @Published var currentZoomLevel: TimelineZoomLevel
    
    init(initialZoomLevel: TimelineZoomLevel = .day) {
        self.currentZoomLevel = initialZoomLevel
    }
    
    func updateZoomLevel(to newZoomLevel: TimelineZoomLevel) {
        currentZoomLevel = newZoomLevel
    }
}

// MARK: - ZoomLevelMenu
struct ZoomLevelMenu: View {
    @EnvironmentObject private var pageViewModel: PageViewModel
    @State private var isMenuOpen = false
    
    var body: some View {
        Menu {
            ForEach(TimelineZoomLevel.allCases, id: \.self) { level in
                Button(action: {
                    pageViewModel.updateZoomLevel(to: level)
                }) {
                    HStack {
                        Text(level.title)
                        if level == pageViewModel.currentZoomLevel {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(pageViewModel.currentZoomLevel.title)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct DynamicHeaderView: View {
    // MARK: - Properties
    let date: Date
    @EnvironmentObject private var pageViewModel: PageViewModel
    
    // MARK: - Private Properties
    private var headerText: String {
        let zoomLevel = pageViewModel.currentZoomLevel
        
        switch zoomLevel {
        case .day:
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            }
            // Use Constants for weekday format
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.Time.Format.weekday
            return formatter.string(from: date)
            
        case .week:
            let weekNumber = Calendar.current.component(.weekOfYear, from: date)
            return "Week \(weekNumber)"
            
        case .month:
            // Use Constants for month format
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.Time.Format.month
            return formatter.string(from: date)
            
        case .year:
            // Use Constants for year format
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.Time.Format.year
            return formatter.string(from: date)
        }
    }
    
    private var subheaderText: String {
        let zoomLevel = pageViewModel.currentZoomLevel
        
        switch zoomLevel {
        case .day:
            // Use Constants for date format
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.Time.Format.date
            return formatter.string(from: date)
            
        case .week:
            guard let startOfWeek = DateUtils.startOfWeek(for: date),
                  let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) else {
                return ""
            }
            
            if !DateUtils.isSameMonth(startOfWeek, endOfWeek) {
                // Use Constants for month format
                let formatter = DateFormatter()
                formatter.dateFormat = Constants.Time.Format.month
                return "\(formatter.string(from: startOfWeek))/\(formatter.string(from: endOfWeek))"
            }
            // Use Constants for month format
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.Time.Format.month
            return formatter.string(from: startOfWeek)
            
        case .month:
            // Use Constants for year format
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.Time.Format.year
            return formatter.string(from: date)
            
        case .year:
            return ""
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Edge Borders
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
            }
            .allowsHitTesting(false)
            
            // Header Content
            VStack(spacing: 8) {
                Text(headerText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .id(date) // Force refresh when date changes
                
                if !subheaderText.isEmpty {
                    Text(subheaderText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .id("\(date)-sub") // Force refresh when date changes
                }
            }
            .frame(height: Constants.UI.Layout.headerHeight)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            
            // Menu Button
            VStack {
                HStack {
                    Spacer()
                    ZoomLevelMenu()
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
}
