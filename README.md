# Iter - Habit Tracking App

A modern habit tracking application built with SwiftUI and SwiftData, following MVVM architecture.

## Architecture Overview

### 1. App Entry Point
- **IterApp.swift**: Initializes SwiftData container and loads RootView
- **RootView.swift**: Manages main navigation between HabitsView and SocialsView

### 2. Core Architecture
- **Framework**: SwiftUI & SwiftData
- **Pattern**: MVVM (Model-View-ViewModel)
- **State Management**: ObservableObject & EnvironmentObject
- **Persistence**: SwiftData
- **Navigation**: Centralized in HabitsContainerView.swift

### 3. Key Components

#### Navigation & State Management
- **HabitsContainerView.swift** (Central Navigation Hub)
  - Manages date navigation (swipe gestures)
  - Controls zoom level selection
  - Prevents future date navigation
  - Houses HeaderView and PageIndicatorView

#### Views
- **HeaderView**: Displays current date and zoom level
- **PageIndicatorView**: Shows timeline position
- **HabitsView**: Main habit tracking interface
- **ZoomLevelSelectorView**: Zoom level selection dropdown
- **HabitListView**: Displays habit entries
- **HabitRowView**: Individual habit display

#### Zoom Level Views
- **DailyView**: Single day habit tracking
- **WeeklyView**: 7-day grid layout
- **MonthlyView**: Calendar-style tracking
- **YearlyView**: Read-only yearly heatmap

#### ViewModels
- **HabitsViewModel**: Global habit state management
- **ZoomLevelViewModel**: Zoom level state
- **DailyViewModel**: Daily habit management
- **WeeklyViewModel**: Weekly data processing
- **MonthlyViewModel**: Monthly calendar data
- **YearlyViewModel**: Yearly statistics (read-only)

## Project Structure

The project follows the MVVM architecture with clear separation of concerns:

### Core Modules

- **App**: Main application entry point and configuration


### Shared Components

- **Models**: Data models
  - **Domain**: Core domain models (Habit, HabitCompletion, etc.)
- **Services**: Business logic and data access
- **Utils**: Utility classes and extensions
  - **Constants**: Application-wide constants
  - **DateUtils**: Date manipulation utilities

### Resources

- Static resources like images, fonts, and localization files

## Architecture

The application follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: SwiftData models for persistence
- **Views**: SwiftUI views for UI representation
- **ViewModels**: Manage state and business logic

## Key Features

- Track daily, weekly, monthly, and yearly habits
- Different visualization modes (day, week, month, year)
- Persistent storage with SwiftData
- Modern SwiftUI interface

## Development Guidelines

### Core Principles
1. **Navigation Handling**
   - All navigation MUST be handled in HabitsContainerView.swift
   - Child views should not manage navigation

2. **Gesture Support**
   - Swipe left/right for date navigation
   - Cannot navigate beyond current date

3. **Interaction Rules**
   - Daily/Weekly/Monthly: Allow habit completion toggle
   - Yearly View: Read-only, no toggles allowed

4. **UI Components**
   - Must be reusable and modular
   - Follow SwiftUI best practices

### View Responsibilities
- Views should only handle display and user input
- All state management through ViewModels
- No direct model manipulation in views

### ViewModel Guidelines
- Focus on data transformation and business logic
- Handle all SwiftData operations
- Maintain view state using ObservableObject

## Getting Started

1. Clone the repository
2. Open Iter.xcodeproj in Xcode
3. Build and run the project

## Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Testing
- Unit tests in IterTests/
- UI tests in IterUITests/ 