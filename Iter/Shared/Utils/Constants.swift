import SwiftUI

enum Constants {
    enum UI {
        enum BoxSize {
            static let year: CGFloat = 8     // YearHeatmapView
            static let month: CGFloat = 32   // MonthHeatmapView
            static let week: CGFloat = 44    // WeekHeatmapView
            static let checkbox: CGFloat = 40 // HabitRow checkbox
        }
        
        enum Spacing {
            static let year: CGFloat = 2     // YearHeatmapView
            static let month: CGFloat = 3    // MonthHeatmapView
            static let week: CGFloat = 4     // WeekHeatmapView
            static let list: CGFloat = 16    // General list spacing
        }
        
        enum Grid {
            static let yearCellsPerRow = 45  // YearHeatmapView
            static let yearRows = 10          // YearHeatmapView
            static let monthCellsPerRow = 10 // MonthHeatmapView
            static let weekCellsPerRow = 7   // WeekHeatmapView
        }
        
        enum Corner {
            static let small: CGFloat = 4    // Small rounded corners
            static let medium: CGFloat = 8   // Medium rounded corners
            static let large: CGFloat = 12   // Large rounded corners
        }
        
        enum Animation {
            static let defaultDuration: Double = 0.3
            static let defaultSpringDamping: Double = 0.8
            static let defaultSpringResponse: Double = 0.3
            
            enum Transition {
                static let scale: Double = 0.95
                static let opacity: Double = 0.5
            }
        }
        
        enum Layout {
            static let listPadding: CGFloat = 20
            static let buttonSize: CGFloat = 64
            static let headerHeight: CGFloat = 100
            static let tabBarHeight: CGFloat = 49
            static let navigationBarHeight: CGFloat = 44
            static let pageWidth = UIScreen.main.bounds.width
            static let pageHeight = UIScreen.main.bounds.height
            
            enum Timeline {
                static let dayWidth = pageWidth
                static let weekWidth = pageWidth * 1.5
                static let monthWidth = pageWidth * 2
                static let yearWidth = pageWidth * 3
            }
        }
    }
    
    enum Time {
        static let maxDaysBack = 7
        static let maxWeeksBack = 4
        static let maxMonthsBack = 12
        static let maxYearsBack = 1
        
        enum Format {
            static let date = "MMM d, yyyy"
            static let month = "MMMM yyyy"
            static let year = "yyyy"
            static let weekday = "E"
            static let time = "h:mm a"
            static let dateTime = "MMM d, yyyy h:mm a"
        }
    }
} 
