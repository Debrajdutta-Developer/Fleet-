# FleetOS Universal Provider Integration Architecture

FleetOS must support mixed fleets where different vehicles use different GPS vendors, AIS-140 devices, CAN/OBD systems, fuel probes, load sensors and weighbridges.

The integration design therefore separates provider-specific payloads from the FleetOS domain model.

## 1. Live telemetry lane

Supported capability classes:

- GPS / GNSS tracking
- AIS-140 VLT feeds
- CAN / OBD vehicle data
- Fuel level and fuel-consumption sensors
- Load-cell / axle-load sensors
- Weighbridge systems

Providers can send data through webhooks or be connected by provider-specific polling adapters. FleetOS normalizes incoming fields into one canonical telemetry schema.

Example canonical fields:

- provider / device ID
- vehicle ID or registration number
- recorded time / received time
- latitude / longitude
- speed in km/h
- ignition state
- engine RPM
- odometer in km
- fuel percentage / trip fuel used in litres
- gross / tare / net load in kg
- source evidence/reference ID

A generic JSON adapter supports configurable nested field paths and numeric unit conversion. This allows a new provider to be integrated without changing FleetOS core code when the provider can expose JSON.

## 2. Official authority lane

Official/government or regulated-network data must not be treated as a live GPS sensor feed.

Examples include:

- VAHAN / mParivahan vehicle and document status
- API Setu vehicle-registration or driving-licence integrations where access is granted
- Authorized NETC/FASTag issuer or partner APIs
- State AIS-140/VLT regulatory backends where the company is authorized to consume data

These sources enrich or verify FleetOS records. They do not automatically replace the truck's operational telemetry source.

## 3. No fake-live rule

FleetOS must never manufacture missing GPS, fuel, load or government data.

If a provider does not supply a field, FleetOS stores it as unavailable. If a feed becomes old, the freshness state degrades from live to recent, stale and finally offline.

## 4. Security model

- Provider credentials remain server-side only.
- Generic ingest endpoints require a server secret/token.
- Production integrations should use provider-specific signature verification where available.
- Government/regulated APIs are connected only with authorized credentials and according to their terms.
- Raw third-party payloads should be retained only when necessary for audit/evidence and according to company retention policy.

## 5. Multi-provider fleet example

A single transport company can run:

- 60 owned trucks using GPS Vendor A
- 25 hired trucks using GPS Vendor B
- 15 attached trucks using an AIS-140 vendor
- fuel probes from another sensor company
- a mine weighbridge integration
- FASTag transaction data from the authorized issuer/partner

FleetOS merges these sources by the company's canonical vehicle identity while preserving the provider and evidence source of every reading.

## 6. Provider onboarding contract

For a new vendor, FleetOS needs one of the following:

1. webhook/API documentation and authorized credentials;
2. a sample JSON payload plus field definitions;
3. a supported AIS-140/VLT integration contract;
4. an export/file format for non-live systems.

The generic JSON adapter can cover many vendors through configuration only. A custom adapter is needed when authentication, transport protocol, signatures or payload semantics are proprietary.
