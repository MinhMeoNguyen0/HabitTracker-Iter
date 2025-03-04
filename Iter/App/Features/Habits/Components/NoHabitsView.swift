import SwiftUI

/// Reusable view for displaying when no habits are available
struct NoHabitsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("No Habits Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tap the + button to create your first habit")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 