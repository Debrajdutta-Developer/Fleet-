# FleetOS ERP

FleetOS ERP is a fleet and logistics management project with two application surfaces in the same repository:

- **Web ERP dashboard:** React 18 + TypeScript + Vite + Tailwind CSS. It includes dashboard, vehicles, drivers, trips, HR, maintenance/fuel, compliance, billing and audit-log views. The current web build persists demo/business state in browser `localStorage` and starts from seeded data.
- **Flutter application:** Flutter + Riverpod + GoRouter + Firebase-oriented feature architecture for the mobile/client application.

The repository should not currently be described as a fully production-ready multi-tenant backend product. The web application is a substantial functional prototype, but production authentication, server-side persistence/sync, authorization enforcement and deployment configuration still need to be completed before real business use.

## Web application

### Run locally

```bash
npm install
npm run dev
```

### Quality checks

```bash
npm run lint
npm run build
```

GitHub Actions runs the same TypeScript validation and production build for web changes.

### Main web modules

```text
src/
├── App.tsx
├── components/
├── context/FleetContext.tsx
├── data/
├── views/
│   ├── DashboardView.tsx
│   ├── VehiclesView.tsx
│   ├── DriversView.tsx
│   ├── TripsView.tsx
│   ├── HRView.tsx
│   ├── MaintenanceFuelView.tsx
│   ├── ComplianceVaultView.tsx
│   ├── BillingView.tsx
│   └── AuditLogsView.tsx
└── types.ts
```

## Flutter application

The Flutter side uses a feature-first structure under `lib/` with shared core services and business modules.

```text
lib/
├── app.dart
├── main.dart
├── core/
│   ├── errors/
│   ├── router/
│   ├── services/
│   ├── theme/
│   └── widgets/
└── features/
    ├── auth/
    ├── company_setup/
    └── dashboard/
```

### Flutter setup

Add Firebase platform configuration only for environments where the Firebase-backed Flutter app is being used:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Then run:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Current completion priorities

1. Keep web TypeScript/build CI green.
2. Replace browser-only demo persistence with a real authenticated backend and tenant-scoped data model.
3. Enforce authorization and business rules server-side, not only in React state.
4. Add automated tests for dispatch, driver assignment, compliance, billing and HR workflows.
5. Decide whether Flutter and web share one backend contract or whether one client becomes the canonical product surface.
6. Add production deployment/environment documentation only after those pieces exist.

## Repository policy

`Fleet-` is the canonical active FleetOS repository. Avoid creating another FleetOS copy for incremental changes. New work should land here through reviewed branches/PRs so the product evolves in one place.
