# FleetOS dashboard analytics

The owner dashboard must derive operational KPIs from recorded FleetOS data rather than decorative or hard-coded demo series.

## KPI semantics

- **Fleet utilization**: active, non-deleted vehicles divided by all non-deleted vehicles.
- **Cargo in transit**: sum of cargo weight on trips currently marked `in_transit`.
- **Trip revenue trend**: recorded `freightRevenue` grouped by the best available trip operational date.
- **Fuel cost trend**: recorded fuel-log `totalCost` grouped by fuel-log timestamp.
- **Receivables**: billed invoice total less invoices marked paid. This is an operational receivables indicator, not a full accounting ledger balance.
- **Operating contribution**: completed-trip revenue less recorded fuel and maintenance costs. It must never be labelled net profit because payroll, tolls, taxes, depreciation, finance costs and other expenses may not yet be included.
- **Compliance due**: verified/pending documents with an expiry date inside the next 30 days; expired documents are counted separately.
- **Fuel efficiency**: average of positive recorded `calcEconomyKmPerLiter` values. If no trustworthy reading exists, show an em dash instead of inventing a number.

## Product rules

1. Never label local simulation or seed movement as live telemetry.
2. Demo telemetry is opt-in only through `VITE_ENABLE_DEMO_TELEMETRY=true`; production defaults to provider-authoritative data.
3. Missing provider/sensor values stay missing; do not replace them with zero unless zero was actually reported.
4. Charts must use the active tenant/company data available to the UI.
5. Currency formatting must respect the company's configured currency; India-first deployments should normally use INR.
6. Owner-facing risk counts should be explainable from the underlying maintenance, compliance or invoice records.
7. A vehicle in registration state must not be activated until the compliance gate has at least one verified compliance document.
