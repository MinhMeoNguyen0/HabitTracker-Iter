import Foundation
import SwiftUI

/// Represents different zoom levels for viewing habits.
enum TimelineZoomLevel: Int, CaseIterable, Hashable {
    case day
    case week
    case month
    case year
    
    var title: String {
        switch self {
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        }
    }
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    
    var systemImage: String {
        switch self {
        case .day: return "list.clipboard"
        case .week: return "chart.bar.fill"
        case .month: return "chart.bar.xaxis"
        case .year: return "calendar"
        }
    }
}
