# FleetOS Live Telematics Architecture

FleetOS live tracking must use real provider/device telemetry. The product must never label simulated browser movement as live fleet data.

## Target live data

Per vehicle/trip, FleetOS should support:

- current latitude/longitude and map position
- speed and heading
- ignition/engine state
- moving, idling, stopped, offline state
- stop/idle duration
- odometer and engine hours where the device exposes them
- fuel level, refill/drain events, trip consumption and mileage where supported
- load/weighment: gross, tare, net and axle readings where supported
- trip distance, remaining distance and ETA
- geofence entry/exit events
- FASTag/toll transaction reconciliation through an authorized data source
- driver-reported evidence as a fallback, clearly marked as driver/manual rather than sensor telemetry

## Data sources

FleetOS is provider-agnostic. A company may connect one or several sources:

1. AIS-140 / GPS VLT provider
2. OEM telematics provider
3. OBD/CAN/ECU gateway
4. calibrated fuel-level sensor
5. onboard load/axle sensor
6. mine/plant weighbridge API or signed weighment feed
7. authorized FASTag/toll provider feed
8. FleetOS Driver app

ARAI/ICAT-approved AIS-140 devices are suitable candidates for India vehicle-location ingestion, but FleetOS still needs an authorized provider/API contract for the actual data feed.

## Important limitation

GPS alone cannot reliably tell exact fuel consumed or exact coal load weight.

- GPS: location, speed, route, stops, movement.
- Ignition/engine telemetry: ignition and engine state.
- OBD/CAN/OEM telemetry: fuel/odometer/engine data when the vehicle exposes it.
- Fuel probe/sensor: tank level and refill/drain detection.
- Weighbridge/load sensor: gross/tare/net/axle weight.

FleetOS should merge these feeds into one vehicle timeline rather than invent missing readings.

## Ingestion flow

```text
GPS / AIS-140 provider ─┐
OEM / CAN / OBD ────────┤
Fuel sensor ────────────┤
Weighbridge ────────────┼─> Provider adapters
FASTag provider ────────┤        │
Driver app ─────────────┘        v
                           Normalize + verify
                                  │
                                  v
                         Tenant/vehicle identity
                                  │
                                  v
                            Telemetry event log
                                  │
                 ┌────────────────┼───────────────┐
                 v                v               v
             Live state        Alerts         Trip ledger
                 │                │               │
                 └────────────────┼───────────────┘
                                  v
                       Owner / dispatcher / driver
```

## Point-to-point trip timeline

Each trip should have a timeline from loading to unloading:

```text
assigned
  -> vehicle reaches loading point
  -> loading starts
  -> weighment captured
  -> departure
  -> live transit
  -> stops/idling/tolls/fuel events
  -> destination geofence
  -> unloading
  -> final weighment / POD
  -> trip complete
  -> finance reconciliation
```

Coal trips should be able to compare loading weighment and destination weighment to flag shortage/excess without automatically accusing a driver or operator.

## Freshness contract

Suggested presentation semantics:

- LIVE: last telemetry <= 60 seconds
- RECENT: <= 5 minutes
- STALE: <= 30 minutes
- OFFLINE: > 30 minutes

The UI must always show last update time and source/provider.

## Truth and evidence rules

1. Every sensor value stores source, device/provider, measurement time and receive time.
2. Provider webhook signatures should be verified when supported.
3. Duplicate/retried events use idempotency keys.
4. Manual/driver values are never silently upgraded to sensor-verified values.
5. Fuel theft/drain, route deviation or shortage are risk flags, not proof of misconduct.
6. External payment/recharge/renewal/toll actions require authoritative confirmation before FleetOS records success.
7. Provider credentials stay server-side and must never ship in React/browser code.
8. Location access is role- and tenant-scoped and should be retained only as long as the business requires.

## Backend requirement

This cannot be implemented securely as browser-only `localStorage` state. Production live telemetry needs a server-side ingestion service and persistent event store. The web and Flutter clients should consume a tenant-scoped realtime API/WebSocket/SSE stream from that backend.

## Initial implementation order

1. Add normalized live telemetry domain types.
2. Add server-side ingestion endpoint and provider adapter interface.
3. Connect one authorized GPS/AIS-140 provider end-to-end.
4. Replace simulated vehicle movement with verified live stream.
5. Add stop/idling/geofence alerts.
6. Connect fuel/CAN data for vehicles that support it.
7. Connect weighbridge/load sensor feeds for coal operations.
8. Add toll/FASTag reconciliation through an authorized integration.
9. Build historical playback and trip telemetry reports.
