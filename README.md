# FleetOS ERP

FleetOS ERP is an India-first transport and logistics operating system. Coal transport is the first deep vertical, but the architecture is intended for transport companies of any size using owned, hired, attached or third-party vehicles.

The repository contains:

- **Web ERP dashboard:** React + TypeScript + Vite for fleet operations, trips, drivers, finance, maintenance, compliance, billing and audit workflows.
- **Telemetry backend:** Node.js + TypeScript ingestion service for real GPS/telematics/weighment/fuel data. It never labels simulated data as live.
- **Flutter application:** Flutter + Riverpod + GoRouter + Firebase-oriented mobile/client architecture.

The project is not yet production-ready. Browser-local demo state is still present in parts of the web application and production authentication, tenant-scoped persistence, provider credentials, durable telemetry storage and server-enforced authorization still need completion.

## Product direction

FleetOS is designed for Indian transport operators that may run 10, 100, 200 or more vehicles without an artificial fleet-size limit. A company can use its own vehicles, hired vehicles or a mixed fleet, transport its own goods, work for logistics contractors, or specialize in bulk/coal transport.

Core product areas:

- owned / hired / attached / third-party vehicle registry
- driver assignment and separate driver-facing workflows
- coal loading, weighment, gross/tare/net load and rate-per-tonne economics
- trip dispatch, route progress, ETA and proof of delivery
- fuel, toll, FASTag and trip expenses
- maintenance and lifetime vehicle cost
- finance, invoices, receipts, outstanding payments and profitability
- RC, insurance, PUC, fitness, permits, road tax and challan expiry alerts
- government/provider integrations only through official or contractually authorized APIs, otherwise verified official-portal/manual workflows

## Realtime telemetry

`server/` contains the first real telemetry ingestion service. It accepts authorized provider/device readings and normalizes them into one FleetOS vehicle state.

Supported normalized fields include:

- latitude / longitude
- speed
- ignition state
- moving / idling / stopped / offline state
- odometer
- engine RPM when provided
- fuel level and trip fuel used when provided
- gross weight, tare weight and net load
- source/provider/device identity
- freshness classification (`live`, `recent`, `stale`, `offline`)

Different data normally comes from different sources:

- GPS/AIS-140 provider: location, speed, route and stop state
- OBD/CAN/OEM telemetry: supported engine/odometer/fuel fields
- fuel sensor: actual tank level/refill/drain events
- weighbridge/load sensor: coal load weights
- authorized FASTag/provider feed: toll transactions

FleetOS must not fabricate missing sensor values. A field is shown as live only when it came from an authoritative connected source and is fresh enough.

### Telemetry server API

Run locally:

```bash
cd server
npm install
FLEETOS_INGEST_TOKEN='replace-me' npm run build
FLEETOS_INGEST_TOKEN='replace-me' npm start
```

Endpoints:

- `GET /health`
- `POST /api/telemetry/ingest` with `Authorization: Bearer <token>`
- `GET /api/telemetry/live`
- `GET /api/telemetry/live/:vehicleId`

Provider credentials belong on the backend only. The browser must never contain GPS-provider or government-integration secrets.

## Web application

```bash
npm install
npm run dev
```

Quality checks:

```bash
npm run lint
npm run build
```

GitHub Actions validates both the web application and telemetry backend build.

## Flutter application

For environments using the Flutter/Firebase client:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Current completion order

1. Keep web and telemetry-server TypeScript builds green.
2. Replace US-oriented demo fixtures with India/coal fixtures and INR-first business rules.
3. Connect the first authorized GPS/AIS-140 provider to the telemetry adapter.
4. Add durable database/time-series storage instead of in-memory telemetry snapshots.
5. Add authenticated tenant-scoped backend and server-side RBAC.
6. Build dedicated driver and finance workflows.
7. Add fuel/weighbridge/FASTag provider adapters where authorized access exists.
8. Move compliance, dispatch and accounting rules out of browser-only state.
9. Add automated workflow/integration tests and production deployment configuration.

## Repository policy

`Fleet-` is the canonical active FleetOS repository. Do not create another FleetOS copy for incremental work; changes should continue here through branches and PRs.
