import SwiftUI
import SwiftData

/// Root view that manages navigation between the main habit tracking view and social features
struct RootView: View {
    let modelContext: ModelContext
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HabitsContainerView(modelContext: modelContext)
                    .navigationTitle("Habits")
            }
            .tabItem {
                Label("Habits", systemImage: "list.bullet.clipboard")
            }
            .tag(0)
            
            NavigationStack {
                SocialsView()
                    .navigationTitle("Social")
            }
            .tabItem {
                Label("Social", systemImage: "person.2")
            }
            .tag(1)
        }
    }
}

/// Placeholder view for the upcoming social features
struct SocialsView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.2.circle")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("Coming Soon")
                .font(.title)
                .padding()
            
            Text("Social features are under development")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

