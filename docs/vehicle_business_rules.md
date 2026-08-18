# FleetOS ERP - Vehicle Module Business Rules Specification (Comprehensive)

This document defines the core business logic, compliance constraints, and operational rules governing the **Vehicle Module** within FleetOS ERP. These rules must be enforced across all client interfaces, database layers, and automation services to ensure compliance and cost-effective operations.

---

## 🔄 1. Vehicle Lifecycle State Machine

A vehicle’s status determines its eligibility for driver assignments, trip dispatches, maintenance logging, and financial calculations. The transition between these states must follow the strict rules below.

```
       [ Registration ]
              │
              ▼
    ┌──►  [ Active ]  ◄──┐
    │         │          │
    │         ▼          │
    │   [ Maintenance ]  │
    │         │          │
    │         ▼          │
    └───  [ Idle ]  ─────┘
              │
              ▼
           [ Sold ]
              │
              ▼
         [ Archived ]
```

### 1.1 State Definitions & Transition Criteria

*   **Registration (Onboarding Phase):** The vehicle record has been initialized (VIN, make, model, purchase specs captured) but is not yet road-ready.
    *   *Operational Rules:* Cannot be assigned to any drivers or trips. GPS/Telematics hardware pairing occurs in this state.
    *   *Transition out:* Moves to **Active** only after a verified safety inspection certificate is uploaded and active insurance details are verified.
*   **Active (Operational):** The vehicle is road-ready, fully compliant, and available for operations.
    *   *Operational Rules:* Telemetry feeds (GPS, OBD-II/CAN-bus data) must be active. Eligible for driver and trip assignments.
    *   *Transition out:* Moves to **Maintenance** automatically if a fault code is raised or manually by dispatch. Moves to **Idle** if unassigned for >48 hours.
*   **Maintenance (Out of Service):** Undergoing scheduled servicing or unscheduled breakdown repairs.
    *   *Operational Rules:* Locked from all trip dispatches. Current driver assignments are automatically unlinked.
    *   *Transition out:* Moves to **Active** (or **Idle**) only when a maintenance work order is marked "Closed" and signed off by a certified technician.
*   **Idle (Inactive Asset):** Fully operational but currently has no active trip assignments or driver links.
    *   *Operational Rules:* Telemetry checks are reduced to once per day (battery saver mode). Flagged on the operator console for under-utilization alerts.
    *   *Transition out:* Moves to **Active** automatically upon assignment to a driver or dispatch trip.
*   **Sold (Decommissioned):** Liquidated or removed from the tenant's corporate asset sheet.
    *   *Operational Rules:* Permanently read-only. Telemetry links are severed. Unlinked from all historic driver mappings.
    *   *Transition out:* Terminal state. Can only move to **Archived**.
*   **Archived (Soft Deleted):** Retained solely for historical tax audits, mileage reviews, and insurance reviews.
    *   *Operational Rules:* Hidden from all search grids and active drop-downs. Cannot transition back to any active lifecycle state.

---

## 👤 2. Driver Assignment Rules

To minimize liability and coordinate driver shifts, the system enforces the following constraints:

1.  **The Single Occupancy Rule:** A vehicle can have a maximum of **one** active primary driver linked at any given timestamp. Secondary drivers (co-drivers) must be explicitly registered under a separate "Co-Driver" role on the Trip Manifest.
2.  **License Category Enforcement:** The assigned driver's Commercial Driver's License (CDL) class must match or exceed the Gross Vehicle Weight Rating (GVWR) of the vehicle:
    *   *Class A CDL:* Required for tractor-trailers (GVWR > 26,000 lbs, towing > 10,000 lbs).
    *   *Class B CDL:* Required for straight trucks or box trucks (GVWR > 26,000 lbs, towing < 10,000 lbs).
3.  **Safety Score Gate:** Drivers with a safety rating score below **70%** (calculated from telemetry indicators of hard braking, speeding, and rapid acceleration) are blocked from operating heavy-duty or high-value vehicles (Class A).
4.  **Assigned Status Logic:** A driver must be in the `available` state to be linked. Once assigned, their status transitions to `on_duty` and they cannot be linked to another vehicle.

---

## 🗺️ 3. Trip Assignment Rules

To maximize payload efficiency and preserve safety margins, trips are dispatched using these parameters:

1.  **State Gate:** The vehicle must be in an **Active** lifecycle state. Vehicles in `Maintenance` or `Sold` states cannot be selected during trip planning.
2.  **Payload Compliance Margin:** The cargo weight specified in the trip manifest must not exceed **90%** of the vehicle's maximum legal payload capacity. A 10% safety margin is enforced to prevent premature suspension wear and compliance issues.
3.  **Range / State-of-Charge Validation:**
    *   *Internal Combustion Engines (ICE):* The current fuel volume (reported via CAN-bus telemetry) must be sufficient to complete the route or reach the first planned refuel station.
    *   *Electric Vehicles (EV):* State of Charge (SoC) must exceed the calculated energy demand for the route (incorporating elevation gains and payload weight) plus a **15% battery safety reserve**.
4.  **No Schedule Overlap:** A vehicle cannot be assigned to multiple trips with overlapping delivery windows. A minimum **2-hour turnaround buffer** is enforced between the estimated completion time of Trip A and the departure time of Trip B.

---

## 📄 4. Insurance & Compliance Expiry Rules

Regulatory compliance requires active insurance coverage. FleetOS ERP enforces these automated checkpoints:

1.  **Proactive Notifications:** The system monitors policy expiration dates and triggers alerts 30, 15, and 7 days prior.
2.  **Automated Compliance Lockout:** If the system time passes the policy expiration date and no verified policy update is recorded, the vehicle’s state is automatically transitioned to **Maintenance** with a sub-state tag: `Compliance Lock`.
3.  **Dispatch Block:** Any vehicle under a `Compliance Lock` is blocked from trip dispatches.
4.  **Re-activation Criteria:** The vehicle can return to `Active` status only after a new insurance certificate is uploaded (Firebase Storage) and verified by a manager, updating the policy details.

---

## 🔬 5. Pollution Certificate (PUC) Rules

1.  **Expiry Warnings:** Emissions / Pollution Under Control (PUC) certificate expiry warnings trigger at 30, 15, and 7 days before expiration.
2.  **Lockout Trigger:** Upon reaching the expiration date without renewal, the system triggers a `Compliance Lockout: PUC` block. The vehicle is automatically transitioned to **Maintenance** status.
3.  **Verification Check:** Re-activation requires uploading a scan of the new PUC certificate with corresponding validity periods and emission readings, which must be cross-verified by the compliance team.

---

## 🩺 6. Fitness Certificate Rules

1.  **Validity Gate:** Commercial vehicles must possess a valid, state-approved Fitness Certificate.
2.  **RTO Inspection Lock:** Expiry triggers an immediate dispatch lock. The vehicle is automatically routed to **Maintenance: Fitness Inspection** status.
3.  **Test Upload Requirement:** To clear the lock, operators must upload the official inspection report, showing passing metrics for brakes, lights, speed governor calibration, and reflective tape visibility.

---

## 🎟️ 7. Permit Rules (National & State)

1.  **Route Border Crossing Check:** During trip planning, if GoRouter coordinates cross state borders, the system queries the vehicle's active permits.
2.  **Permit Matching:** The vehicle must hold either a valid **National Permit (NP)** or a specific **State Transit Permit** for each crossed state boundary.
3.  **Dispatch Interceptor:** If the matching permit is missing or expires before the trip's estimated time of arrival (ETA), the dispatch creation tool is disabled with the error message: `Missing Route Permits`.

---

## 🛣️ 8. Road Tax Rules

1.  **Payment Validation:** Vehicles must verify paid road tax (annual or lifetime) within their primary region of operations.
2.  **Grace Period Buffer:** A **5-day grace period** is permitted post-due date. During these 5 days, warnings are pinned to the operator console.
3.  **Automatic Suspend:** On day 6 post-due date, the vehicle status transitions to `Maintenance: Tax Suspension` and is blocked from public roads.

---

## 🏷️ 9. FASTag & Toll Management

1.  **Low Balance Threshold:** The system polls FASTag/toll balance API every 4 hours.
    *   *Warning Threshold:* If the balance drops below **$15 (or ₹1,000)**, an automated alert triggers to top-up.
2.  **Critical Threshold Block:** If the balance drops below **$5 (or ₹300)**:
    *   The vehicle is blocked from new trip dispatches.
    *   Active in-transit vehicles trigger an immediate SMS alert to the dispatcher to process an instant recharge before the next toll gate.

---

## ⛽ 10. Fuel Log Validation & Theft Prevention

To prevent fuel siphoning and invoice fraud, the system executes a three-factor validation loop on every fuel entry:

1.  **Odometer Check:** The entered odometer reading must be greater than the previous entry and deviate by no more than **+/- 2%** from the GPS odometer calculation.
2.  **Fuel Consumption Audit:** The fuel economy (Miles Per Gallon or Kilometers Per Liter) is calculated. If the consumption rate deviates by **>20%** from the vehicle's historical baseline, the log is flagged as `Pending Audit - Fuel Discrepancy`.
3.  **GPS Geofence Match:** The GPS coordinates of the vehicle at the timestamp on the fuel receipt must match the coordinates of the fuel station within a **100-meter radius**. If they do not match, the transaction is marked as `High Risk - Location Mismatch` and triggers an audit alert.

---

## 📟 11. Odometer Validation

1.  **Telemetry Source of Truth:** The telemetry system (GPS/OBD-II distance tracker) is the primary source of truth.
2.  **Manual Entry Delta Limit:** Manual driver inputs during fuel logs or shift handovers cannot differ by more than **5%** from the telemetry log. Any larger discrepancy flags the entry for manager review.
3.  **Rollback Protection:** Any odometer entry value lower than the current database record is rejected by Firestore security rules.

---

## 📅 12. Service Scheduling (PM Matrix)

Preventative Maintenance (PM) schedules are governed by three concurrent triggers:

*   **Trigger 1: Odometer Interval:** Every **10,000 km (or 6,000 miles)** since last service.
*   **Trigger 2: Time Interval:** Every **180 days** since last service.
*   **Trigger 3: Engine Hours:** Every **250 operating hours** since last service.

*   **Action:** Whichever trigger is reached first automatically generates a maintenance ticket and prompts the planner. If ignored for over 1,000 km (or 10 days), the vehicle is automatically flagged as `Overdue Service` and locked from new long-haul dispatches.

---

## 🚨 13. Breakdown Workflow

In the event of a mechanical breakdown, the following automated sequence is triggered:

1.  **Initiation:** Triggered either via Driver App SOS button or a critical CAN-bus engine error code.
2.  **Immediate Status Transition:** Vehicle transitions to `Maintenance: Breakdown` status.
3.  **SLA Alerts:** Sends high-priority push notifications to the dispatcher and regional maintenance partners.
4.  **Cargo Redirection:** The system locates the closest active or idle `available` vehicle with matching payload capacity and generates a transshipment route to transfer the cargo.

---

## 💥 14. Accident Workflow

1.  **Immediate Lock:** Triggered via Driver SOS or telemetry crash sensors (G-force exceeding 2.5G). The vehicle is placed in `Maintenance: Accident Lockout`.
2.  **Emergency Broadcast:** Automatic SMS/Email notification containing GPS coordinates, driver identity, and recent diagnostic status sent to the safety officer and insurance handler.
3.  **Information Archival:** Telemetry data from 5 minutes preceding the event (speed, braking, steering angles) is locked in a read-only document partition for legal/insurance reviews.

---

## 📁 15. Vehicle Document Management

All vehicle compliance documents are stored in Firebase Storage and cataloged in Firestore with the following metadata standards:

*   **Required Fields:** `documentId`, `vehicleId`, `documentType` (enum: `RC` | `Insurance` | `PUC` | `Fitness` | `Permit`), `expiryDate`, `verificationStatus` (enum: `pending` | `verified` | `expired`), `verifiedByUserId`, `fileUrl`.
*   **Storage Pathing:** `/companies/{companyId}/vehicles/{vehicleId}/documents/{documentType}_{timestamp}.pdf`

---

## 🔔 16. Notification Rules

| Event Type | Channels | Recipient Group | Escalation Rules |
| :--- | :--- | :--- | :--- |
| **Breakdown / SOS** | Push, SMS, Dashboard Popup | Dispatcher, Fleet Manager | Escalates to Operations Director if unacknowledged within 15 minutes. |
| **Accident Crash Sensor**| SMS, Email, System Alarm | Safety Director, HR, Insurer | Immediate emergency broadcast; cannot be silenced. |
| **Doc Expiry (30 Days)** | Push, Email | Compliance Officer | Repeats weekly. |
| **Doc Expiry (7 Days)** | Push, SMS, Email | Fleet Manager, Driver | Daily alerts; blocks future trip scheduling. |

---

## 📝 17. Audit Log Requirements

Every state transition and field change must record an audit entry:

*   **Immutable Entries:** Once written, audit entries cannot be edited or deleted.
*   **Data Fields:** Must capture the exact fields changed, state before, state after, operator UID, IP address, and server timestamp.
*   **Audit Lifetime:** Retained permanently (minimum 7 years for compliance).

---

## 🗑️ 18. Soft Delete Policy

*   **Logical Deletions Only:** The database prohibits the physical deletion (`delete()`) of vehicle records.
*   **Archiving Execution:** Deleting a vehicle sets `deletedAt = serverTimestamp()` and transitions status to `Archived`.
*   **Query Enforcements:** All database queries must explicitly include `where('deletedAt', '==', null)` to exclude decommissioned assets from operational grids.

---

## 🔐 19. Security & Permissions Matrix

| Operations Role | Read Vehicle | Onboard Vehicle | Schedule Service | Delete Vehicle (Archive) |
| :--- | :--- | :--- | :--- | :--- |
| **Super Admin** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Fleet Manager** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No (View Only) |
| **Dispatcher** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Driver** | 👤 Assigned Only | ❌ No | ❌ No | ❌ No |

---

## ⚠️ 20. Edge Cases & Failure Scenarios

### 20.1 Offline Operations & Database Synchronization
*   *Scenario:* A driver operates in a remote mountainous zone with no cell reception.
*   *Rule:* The Driver App stores all diagnostic updates, odometer entries, and logs locally in SQLite/Hive. Updates are timestamped locally. On reconnection, Firestore updates the records in chronological order. Conflict resolution favors the local device's timestamped inputs.

### 20.2 Telemetry Signal Loss (Blackout)
*   *Scenario:* GPS tracking hardware fails or is disconnected during an active trip.
*   *Rule:* If telemetry ping is lost for **>30 minutes** during an active trip, the system flags the vehicle as `Telemetry Offline` and alerts the dispatcher. The driver must perform manual check-ins at pre-planned checkpoints via the app.

### 20.3 Multi-Tenant Identifier Mismatch
*   *Scenario:* A developer attempts to query vehicles across companies using a Collection Group query.
*   *Rule:* Firestore Security Rules immediately reject any request that does not include a `companyId` validation token matching the user's account custom claim, preventing cross-tenant leakage.
