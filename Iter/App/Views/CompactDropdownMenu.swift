import SwiftUI

/// A compact iOS-style dropdown menu
struct CompactDropdownMenu: View {
    @ObservedObject var viewModel: ZoomLevelViewModel
    var onRefresh: () async -> Void
    
    var body: some View {
        Menu {
            ForEach(TimelineZoomLevel.allCases, id: \.self) { level in
                Button(action: {
                    viewModel.setZoomLevel(level)
                }) {
                    HStack {
                        Text(level.title)
                        Spacer()
                        Image(systemName: level.systemImage)
                    }
                }
                .disabled(viewModel.currentZoomLevel == level)
            }
            
            Divider()
            
            Button(action: {
                Task {
                    await onRefresh()
                }
            }) {
                HStack {
                    Text("Refresh Data")
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundColor(.primary)
                .padding(8)
        }
    }
} 