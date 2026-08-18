# FleetOS ERP - Enterprise Fleet and Logistics Management System

FleetOS ERP is a production-ready multi-tenant, offline-first fleet management platform built using Flutter, Riverpod, GoRouter, and Firebase.

## 🏗️ Folder Structure (Feature-First Clean Architecture)
```
lib/
├── app.dart                   # Root MaterialApp config
├── main.dart                  # Entry point & service initialization
├── core/                      # Shared common codebase
│   ├── errors/                # Domain failures & exception translations
│   ├── router/                # Declarative routing with GoRouter
│   ├── services/              # Common framework wrappers (Firebase, Cache)
│   ├── theme/                 # Material 3 typography and dark/light systems
│   └── widgets/               # Design system reusable atoms (buttons, inputs)
└── features/                  # Domain/Business units (modular partitions)
    ├── auth/                  # Authentication Module
    │   ├── data/              # DB serialization & repository implementation
    │   ├── domain/            # Entities, repository definitions, use cases
    │   └── presentation/      # Notifiers (controllers) & responsive screens
    ├── company_setup/         # Tenant Onboarding Module
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── dashboard/             # Command Center Module
        └── presentation/
```

## 🚀 Setting Up the Project Locally

### 1. Add Platform Config Files (Firebase)
Download your project configuration settings from the Firebase Console and place them:
*   **Android:** `android/app/google-services.json`
*   **iOS:** `ios/Runner/GoogleService-Info.plist`

### 2. Install Packages & Generate Code
Run the following commands inside this directory:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run Application
Run the local dev target:
```bash
flutter run
```
