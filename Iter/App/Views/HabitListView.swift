import SwiftUI

/// View for displaying a list of habits
struct HabitListView: View {
    // MARK: - Properties
    let habits: [Habit]
    let completionStatus: [UUID: Bool]
    let onToggle: (Habit) -> Void
    let isReadOnly: Bool
    
    // MARK: - Initialization
    init(
        habits: [Habit],
        completionStatus: [UUID: Bool],
        onToggle: @escaping (Habit) -> Void,
        isReadOnly: Bool = false
    ) {
        self.habits = habits
        self.completionStatus = completionStatus
        self.onToggle = onToggle
        self.isReadOnly = isReadOnly
    }
    
    // MARK: - Body
    var body: some View {
        if habits.isEmpty {
            NoHabitsPlaceholderView()
        } else {
            List {
                ForEach(habits) { habit in
                    HabitRowView(
                        habit: habit,
                        isCompleted: completionStatus[habit.id] ?? false,
                        onToggle: { onToggle(habit) },
                        isReadOnly: isReadOnly
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// View for displaying an individual habit row
struct HabitRowView: View {
    // MARK: - Properties
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () -> Void
    let isReadOnly: Bool
    
    // MARK: - Body
    var body: some View {
        HStack {
            // Habit type indicator
            Circle()
                .fill(habit.type.color)
                .frame(width: 12, height: 12)
            
            // Habit title
            Text(habit.title)
                .font(.body)
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .secondary : .primary)
            
            Spacer()
            
            // Completion toggle
            if !isReadOnly {
                Button(action: onToggle) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Read-only indicator
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isReadOnly {
                onToggle()
            }
        }
    }
}

/// Placeholder view when no habits exist
struct NoHabitsPlaceholderView: View {
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
