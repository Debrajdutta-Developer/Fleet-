# FleetOS Zero-Touch Company Onboarding

## Goal

A transport-company owner should not need to manually create every vehicle, GPS integration, compliance record, or recurring sync. FleetOS should automate discovery and enrichment wherever an official or contractually authorized source exists.

## Owner onboarding

1. The owner creates a FleetOS company account and submits the business identity details required by the applicable verification provider.
2. FleetOS records explicit consent for registry lookup and optional recurring fleet synchronization.
3. The company remains `pending` until the configured business/registry provider confirms the organization.
4. Once verified, FleetOS can synchronize the vehicles that the authorized source confirms belong to the company.
5. The owner sees discovered vehicles as `owned` without retyping the same vehicle details.

FleetOS must never infer ownership from a registration number alone and must not scrape private owner data from public web pages.

## Manager vehicle workflow

A company manager can enter only a registration number for a hired, attached, or third-party vehicle. FleetOS then asks the configured authoritative registry gateway for the permitted vehicle record and shows the verified fields that the company is entitled to use. The manager chooses the relationship (`hired`, `attached`, or `third_party`) and attaches the vehicle to the company.

If the authoritative source is unavailable or the company is not entitled to the record, FleetOS keeps the vehicle unverified instead of fabricating data.

## Automatic new-vehicle detection

When recurring fleet sync is enabled, FleetOS compares the latest authorized company fleet snapshot with the previous snapshot. A registration number that appears for the first time is added as a newly discovered owned vehicle. Changed registry/compliance fields are updated. A vehicle missing from the latest snapshot is flagged for review rather than silently deleted.

This allows a newly purchased vehicle to appear automatically only when the connected authoritative source can expose that relationship to the verified company.

## Integration layers

- Company verification provider: business identity / organization authorization.
- Vehicle registry provider: registration, vehicle class, make/model, permitted compliance fields and ownership relationship when authorized.
- GPS/AIS-140 provider layer: live position, motion and device telemetry.
- CAN/OBD/fuel/load sensors: vehicle and cargo telemetry.
- Weighbridge integration: gross/tare/net load evidence.
- FASTag/toll provider: authorized toll transaction feed.
- Compliance authorities/providers: insurance, fitness, PUC, permit, tax and challan data where legitimately available.

Each source is normalized into FleetOS but retains its source ID and verification timestamp.

## Zero-touch principle

Customers should not have to install a custom FleetOS GPS device if their existing provider exposes an authorized API, webhook, documented protocol, or export that FleetOS can connect to. Provider credentials belong on the FleetOS backend, never in the browser.

If an existing device/provider is closed and exposes no authorized integration path, FleetOS must report that limitation. It should not bypass provider security, scrape authenticated apps, or label simulated data as live.

## Data ownership and privacy

- Data access is tenant-scoped.
- Vehicle ownership is never inferred from registration number alone.
- Manager lookups require company authorization and are audited.
- Sensitive government/partner credentials are server-side secrets.
- Every authoritative record retains source and verification evidence.
- Automatic sync requires explicit company consent and can be disabled.
