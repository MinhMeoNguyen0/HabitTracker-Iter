import Foundation
import SwiftUI
import Combine

/// ViewModel for managing zoom level selection
class ZoomLevelViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentZoomLevel: TimelineZoomLevel = .day
    @Published var isDropdownOpen: Bool = false
    
    // MARK: - Callbacks
    var onRefresh: (() async -> Void)?
    
    // MARK: - Initialization
    init(initialZoomLevel: TimelineZoomLevel = .day, onRefresh: (() async -> Void)? = nil) {
        self.currentZoomLevel = initialZoomLevel
        self.onRefresh = onRefresh
    }
    
    // MARK: - Public Methods
    
    /// Sets the current zoom level
    func setZoomLevel(_ level: TimelineZoomLevel) {
        withAnimation {
            self.currentZoomLevel = level
        }
    }
    
    /// Performs the refresh operation
    func refresh() {
        Task {
            await onRefresh?()
        }
    }
    
    /// Toggles the dropdown menu
    func toggleDropdown() {
        isDropdownOpen.toggle()
    }
    
    /// Closes the dropdown menu
    func closeDropdown() {
        isDropdownOpen = false
    }
} 