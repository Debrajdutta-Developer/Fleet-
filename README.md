# FleetOS ERP

FleetOS is an **India-first transport-company operating system** for fleets of any practical size. The first deep vertical is **coal transport**, while the core model is intended to support general freight and contract logistics too.

A FleetOS company can operate owned trucks, hire outside trucks, attach third-party vehicles, transport its own material, or work under another logistics company. The target is not a fixed 10/50/100 vehicle product ceiling; the production architecture must scale through tenant-scoped storage, indexed queries and pagination.

## Product direction

FleetOS is being completed around these first-class subsystems:

- **Operations:** vehicles, owned/hired/attached fleet, drivers, dispatch, trips and proof of delivery.
- **Coal transport:** mine/loading point, weighment, gross/tare/net weight, rate per tonne, challan/royalty references, shortage, detention and settlement.
- **Driver portal:** assigned vehicle/trip, authorized documents, advances, toll/FASTag information, expense and receipt submission.
- **Finance:** freight revenue, invoices, receipts, outstanding, expenses, hired-vehicle payables, payroll and trip/vehicle/client profitability.
- **Compliance:** RC, insurance, PUC, fitness, permits, road tax, licence, FASTag and challan tracking with 30/15/7/1-day expiry alerts.
- **Maintenance:** preventive service, breakdowns, parts, tyres/battery, labour, workshop cost, downtime and lifetime vehicle cost.
- **External integrations:** only official APIs, contractually authorized partners, official-portal deep links or manual verified proof. FleetOS must never fake a government/payment integration or hard-code a transaction as successful.

The detailed source of truth is [`docs/PRODUCT_VISION_INDIA.md`](docs/PRODUCT_VISION_INDIA.md).

## Current application surfaces

- **Web ERP dashboard:** React 18 + TypeScript + Vite + Tailwind CSS. It currently includes dashboard, vehicles, drivers, trips, HR, maintenance/fuel, compliance, billing and audit-log views.
- **Flutter client:** Flutter + Riverpod + GoRouter + Firebase-oriented feature architecture.

The current web build is still a functional prototype that persists state in browser `localStorage` and starts from seeded data. It must not be described as production-ready until authenticated server persistence, tenant authorization, tests and real integration contracts are complete.

## India transport domain foundation

`src/domain/indiaTransport.ts` introduces the migration-safe domain layer for:

- vehicle ownership: owned / hired / attached / third-party;
- coal load and weighment records;
- trip expense and profitability calculation;
- compliance expiry alert calculation;
- explicit government/provider integration modes;
- safe rules that require authoritative confirmation before external actions are marked successful.

The old US-oriented demo fields/data remain temporarily for UI compatibility and will be migrated instead of breaking the existing product in one unsafe rewrite.

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

GitHub Actions runs TypeScript validation and the production Vite build for relevant web changes.

### Main web modules

```text
src/
├── App.tsx
├── components/
├── context/FleetContext.tsx
├── data/
├── domain/
│   └── indiaTransport.ts
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

## Completion order

1. Keep TypeScript/build CI green while migrating the domain.
2. Replace US demo assumptions with India transport + coal fixtures and business rules.
3. Add authenticated backend tenancy and server-side role enforcement.
4. Build the dedicated driver workflow and finance/accounting backend.
5. Move compliance, dispatch and accounting rules out of browser-only state.
6. Add automated tests for coal dispatch, weighment, driver assignment, compliance, billing, expenses and hired-vehicle settlement.
7. Add external services only when an official/authorized integration contract exists.
8. Deploy only after environment/security/backup/runbook documentation is complete.

## Repository policy

`Fleet-` is the canonical active FleetOS repository. Do not create another FleetOS copy for incremental updates. Changes should continue here through branches/PRs so the product has one history and one source of truth.
