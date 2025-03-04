import Foundation
import SwiftData
import SwiftUI

enum HabitType: String, Codable {
    case good
    case bad
    case neutral
    
    var color: Color {
        switch self {
        case .good: return .green
        case .bad: return .red
        case .neutral: return .gray
        }
    }
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: HabitType
    var createdDate: Date
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit ) var completions: [HabitCompletion]
    
    init(title: String, type: HabitType = .neutral) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.createdDate = Date()
        self.completions = []
    }
} 
