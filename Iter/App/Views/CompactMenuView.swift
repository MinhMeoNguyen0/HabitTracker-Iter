import SwiftUI

/// A toolbar item that adds a compact dropdown menu
struct CompactMenuToolbarItem: ToolbarContent {
    @ObservedObject var zoomLevelViewModel: ZoomLevelViewModel
    var onRefresh: () async -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            CompactDropdownMenu(
                viewModel: zoomLevelViewModel,
                onRefresh: onRefresh
            )
        }
    }
}

// Extension to make it easier to add the menu to a toolbar
extension View {
    func withCompactMenu(
        zoomLevelViewModel: ZoomLevelViewModel,
        onRefresh: @escaping () async -> Void
    ) -> some View {
        toolbar {
            CompactMenuToolbarItem(
                zoomLevelViewModel: zoomLevelViewModel,
                onRefresh: onRefresh
            )
        }
    }
} 