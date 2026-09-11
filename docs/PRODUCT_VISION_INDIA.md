# FleetOS India Product Vision

FleetOS is an India-first transport-company operating system. Coal transport is the first deep vertical, but the platform must support any small, medium or large road-transport operator without an artificial fleet-size ceiling.

## Who it serves

A company may:

- operate only its own vehicles;
- hire vehicles from outside owners;
- attach third-party vehicles for longer periods;
- run a mixed fleet of owned and hired vehicles;
- transport its own material;
- work under another logistics company or principal contractor;
- operate tens, hundreds or more vehicles under one tenant.

FleetOS must model the commercial relationship around the vehicle, not assume that every truck is owned by the company.

## Core operating model

### Fleet Operations

Every vehicle has an ownership type (`owned`, `hired`, `attached`, `third_party`), commercial terms, current driver, trip history, odometer, fuel history, maintenance history, compliance documents and profitability history.

### Driver Portal

Drivers have separate accounts and should see only authorized operational information, including:

- assigned vehicle and active trip;
- loading and delivery locations;
- load/challan details;
- advances and allowances;
- FASTag/toll information permitted for the trip;
- document checklist;
- expense submission;
- fuel, toll, repair, loading/unloading and other receipt upload;
- payment/salary information the company permits them to view.

A driver must never gain access to company-wide finance or another driver's private records through client-side role switching.

### Coal Transport

Coal is the first specialized workflow:

`loading point/mine -> weighment -> challan -> driver/vehicle -> transit -> destination weighment/unloading -> proof -> billing -> collection`

The record should support gross, tare and net weight, rate per tonne, source, destination, loading slip, challan/royalty references, shortage/excess, detention, loading/unloading charges, proof of delivery and settlement status.

Coal revenue should be calculated from validated commercial inputs, while all expenses remain individually traceable.

### Finance

FleetOS Finance is a first-class subsystem, not a small billing tab. It should support:

- freight revenue;
- invoices and receipts;
- customer outstanding and ageing;
- diesel, toll and FASTag expenditure;
- driver advances and settlements;
- salary/payroll;
- maintenance and spare parts;
- tyre/battery cost;
- insurance, permit and road-tax payments;
- challan expense;
- hired-vehicle payable and owner settlement;
- cash/bank/UPI accounts;
- vehicle-wise, trip-wise, owner-wise and customer-wise profitability.

Every financial mutation must be auditable. An AI feature may prepare a draft but must not silently create accounting entries or claim a payment succeeded.

### Compliance

Track at minimum:

- Registration Certificate (RC)
- insurance
- PUC
- fitness
- national/state permits
- road tax
- driving licence
- FASTag status
- challans

Expiry alerts should support 30, 15, 7 and 1 day warnings, plus expired status.

### Maintenance

Track preventive and breakdown maintenance, odometer-based service intervals, engine oil, brakes, tyres, batteries, clutch/suspension where relevant, parts, labour, workshop, downtime and lifetime vehicle maintenance cost.

## Government and regulated integrations

FleetOS must never pretend an integration exists.

For every external government, FASTag, insurance or regulated workflow, record one of these modes:

1. `official_api` — directly documented and authorized API.
2. `authorized_partner` — provider/aggregator access supported by contract and permitted scope.
3. `official_portal_deeplink` — FleetOS opens the correct official flow but does not claim to execute the transaction.
4. `manual_verification` — staff completes the action externally and uploads/records confirmed proof.

No discount, challan settlement, renewal success, FASTag recharge, tax payment or permit renewal may be hard-coded as successful. The authoritative provider response or explicit verified proof must drive final status.

## Roles

Target roles include:

- owner / super admin
- company admin
- fleet manager
- dispatcher
- accountant
- compliance manager
- HR/payroll staff
- driver
- optional client/logistics partner portal

Authorization must ultimately be enforced by the backend and tenant scope, not only by React controls.

## Scale principle

Do not encode product tiers as operational vehicle limits. Billing plans may differ commercially, but the core data model should work for 10, 100, 200+ vehicles through pagination, indexed queries, background jobs and aggregate reporting instead of loading an entire fleet into one browser state object.

## Migration from current prototype

The current web prototype contains a number of US-oriented demo concepts such as CDL classes, US-style plates/locations and USD seed data. These are demo artifacts, not the target domain.

Migration order:

1. introduce India commercial/coal domain types without breaking the existing UI;
2. replace demo data with Indian transport/coal fixtures;
3. replace CDL-specific rules with Indian licence/vehicle-class eligibility rules;
4. switch financial presentation to tenant currency, defaulting India deployments to INR;
5. add backend tenancy/authentication and server-enforced authorization;
6. move compliance, trip, finance and driver actions to backend services;
7. integrate only verified external providers;
8. add workflow/integration tests before marking production readiness.
