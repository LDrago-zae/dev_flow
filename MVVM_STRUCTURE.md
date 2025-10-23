# MVVM Folder Structure

This project follows the MVVM (Model-View-ViewModel) architecture pattern with Clean Architecture principles.

## Directory Structure

```
lib/
├── core/                          # Core utilities and shared resources
│   ├── constants/                 # App-wide constants (API endpoints, strings, etc.)
│   ├── errors/                    # Custom exceptions and failures
│   ├── network/                   # Network client setup (Dio, interceptors)
│   ├── utils/                     # Helper functions and utilities
│   ├── theme/                     # App theme configuration
│   └── extensions/                # Dart extensions
│
├── data/                          # Data Layer
│   ├── models/                    # Data models (JSON serialization)
│   ├── repositories/              # Repository implementations
│   └── data_sources/              # Data source implementations
│       ├── local/                 # Local data sources (SharedPreferences, SQLite, Hive)
│       └── remote/                # Remote data sources (API calls)
│
├── domain/                        # Domain Layer (Business Logic)
│   ├── entities/                  # Business entities (pure Dart classes)
│   ├── repositories/              # Repository interfaces (contracts)
│   └── use_cases/                 # Business use cases
│
├── presentation/                  # Presentation Layer (UI)
│   ├── views/                     # UI screens
│   │   ├── home/                  # Home screen and related views
│   │   ├── auth/                  # Authentication screens
│   │   └── ...                    # Other feature screens
│   ├── view_models/               # ViewModels (state management)
│   └── widgets/                   # Reusable widgets
│       ├── common/                # Common widgets used across the app
│       └── custom/                # Custom specialized widgets
│
├── routes/                        # Navigation and routing
├── services/                      # App services (notifications, analytics, etc.)
├── di/                           # Dependency Injection setup
└── main.dart                      # App entry point
```

## Layer Responsibilities

### Core Layer
- **constants/**: Store all constant values (API URLs, app strings, colors, sizes)
- **errors/**: Define custom exceptions and failure classes
- **network/**: Configure HTTP client, interceptors, and network utilities
- **utils/**: Helper functions, validators, formatters
- **theme/**: Theme data, colors, text styles
- **extensions/**: Dart extensions for built-in types

### Data Layer
- **models/**: Data transfer objects with JSON serialization
- **repositories/**: Implement repository interfaces from domain layer
- **data_sources/local/**: Handle local storage (SharedPreferences, databases)
- **data_sources/remote/**: Handle API calls and remote data fetching

### Domain Layer
- **entities/**: Pure business objects without any framework dependencies
- **repositories/**: Abstract repository interfaces
- **use_cases/**: Business logic operations (one use case per file)

### Presentation Layer
- **views/**: UI screens organized by feature
- **view_models/**: State management and business logic for views
- **widgets/**: Reusable UI components

### Other Directories
- **routes/**: Route definitions and navigation logic
- **services/**: Third-party services and app-level services
- **di/**: Dependency injection configuration (GetIt, Provider, etc.)

## Best Practices

1. **Separation of Concerns**: Each layer has a specific responsibility
2. **Dependency Rule**: Dependencies point inward (Presentation → Domain ← Data)
3. **Single Responsibility**: Each class should have one reason to change
4. **Testability**: Easy to write unit tests for each layer independently
5. **Scalability**: Easy to add new features without affecting existing code
