import Foundation
import SwiftUI

struct PageViewState {
    var selectedDate: Date = Date()
    var currentZoomLevel: TimelineZoomLevel = .day
    var isLoading: Bool = false
    var error: Error?
    
    var isError: Bool {
        error != nil
    }
}

enum PageViewError: LocalizedError {
    case invalidDateCalculation
    case databaseError(Error)
    case invalidStateTransition
    
    var errorDescription: String? {
        switch self {
        case .invalidDateCalculation:
            return "Failed to calculate the correct date"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .invalidStateTransition:
            return "Invalid state transition occurred"
        }
    }
} 
