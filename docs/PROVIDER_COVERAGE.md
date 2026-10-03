# FleetOS Provider Coverage Strategy

FleetOS is designed so a transport company should not have to replace its existing GPS or sensor hardware just to use FleetOS.

## Coverage layers

1. **Native/partner adapters**
   - Used when a provider publishes or contractually exposes an API/webhook/protocol.
   - Credentials remain server-side and are tenant-scoped.

2. **Config-driven REST connector**
   - For providers that expose JSON over HTTPS.
   - Endpoint, authentication headers, array path, field paths and unit conversions are configurable without changing FleetOS core code.

3. **Generic webhook adapter**
   - For providers that can push JSON events to FleetOS.
   - Arbitrary vendor field names are normalized into FleetOS telemetry.

4. **AIS-140/device protocol adapter**
   - Used when an approved VLT/device/backend protocol is available.
   - Vendor/device packet details still require the documented protocol or an authorized backend feed.

5. **Sensor adapters**
   - CAN/OBD, calibrated fuel probe, load/axle sensor and weighbridge feeds are independent capabilities and can be fused with GPS data from another vendor.

6. **Authority adapters**
   - VAHAN/API Setu/authorized government or FASTag sources are kept separate from live GPS telemetry.
   - FleetOS never scrapes authenticated consumer apps or treats guessed data as authoritative.

## Initial catalog

- Mappls / MapmyIndia InTouch — partner/API onboarding path.
- Letstrack — customer REST/API integration path.
- WheelsEye — partner onboarding until an authorized API contract/schema is available.
- Generic AIS-140 VLT — protocol/backend integration path.
- Generic JSON GPS — configurable webhook/polling path.
- Generic fuel/CAN — configurable sensor feed.
- Generic load/weighbridge — configurable load feed.

This list is not a claim that credentials are bundled. A provider becomes live only after legitimate endpoint access, credentials and/or protocol documentation are supplied.

## Customer promise

The goal is **bring your existing provider**. When a provider exposes an authorized integration path, FleetOS should connect it without requiring the customer to install FleetOS-specific GPS hardware.

## Release gate

FleetOS must not claim universal live-provider support based only on catalog entries. Before production release:

- generic adapter contract tests must pass in CI;
- each native provider adapter must pass schema/auth smoke tests against an authorized sandbox or account;
- provider credentials must be stored as server-side secrets;
- no provider integration may depend on reverse engineering a consumer app;
- missing sensor values remain unknown rather than being fabricated.
