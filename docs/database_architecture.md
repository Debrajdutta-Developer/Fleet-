# FleetOS ERP - Multi-Tenant Firestore Database Architecture

This document defines the database architecture for **FleetOS ERP**, designed to scale to **thousands of companies (tenants)** and **millions of records**. 

---

## 🏗️ Multi-Tenancy Design Pattern: Hierarchical Isolation

To guarantee security, performance, and compliance for corporate clients, FleetOS ERP implements a **Hierarchical Multi-Tenancy Pattern** utilizing Firestore Subcollections:

```
/companies/{companyId}/[subcollections]
```

### Why Hierarchical Isolation?
1. **Ironclad Data Separation:** Prevents developer error from accidentally leaking data across tenants.
2. **Simplified Security Rules:** Path-based access rules permit security checks at the root level (`/companies/{companyId}`), removing the need to read individual child documents for permission checks.
3. **Optimized Index Scoping:** Firestore indexes are scoped per subcollection. Query performance for a single company depends only on that company's dataset size, not the total size of millions of global records.
4. **Independent Tenant Operations:** Easier backup, restoration, or deletion of a single tenant's data.

---

## 🗄️ Collections & Subcollections Schema Blueprint

### 1. Global / Root-Level Collections

#### Root Collection: `/users`
Stores user authentication profiles, cross-referenced to their respective company tenant.

*   **Document ID:** Auth User UID (`uid`)
*   **Fields:**
    *   `uid`: `string` (UUID)
    *   `email`: `string`
    *   `displayName`: `string`
    *   `role`: `string` (enum: `super_admin` | `company_admin` | `dispatcher` | `fleet_manager` | `driver`)
    *   `companyId`: `string` (references `/companies/{companyId}`; null if onboarding is incomplete)
    *   `status`: `string` (enum: `active` | `suspended` | `pending`)
    *   `createdAt`: `timestamp`
    *   `updatedAt`: `timestamp`
    *   `deletedAt`: `timestamp` (null if active; holds deletion timestamp if soft-deleted)

#### Root Collection: `/companies`
Defines the corporate tenants in the SaaS.

*   **Document ID:** Generated UUID (`companyId`)
*   **Fields:**
    *   `id`: `string` (UUID)
    *   `name`: `string` (Legal name)
    *   `logoUrl`: `string`
    *   `industry`: `string`
    *   `fleetSizeTier`: `string`
    *   `subscriptionTier`: `string` (enum: `growth` | `scale` | `enterprise`)
    *   `isActive`: `boolean`
    *   `createdAt`: `timestamp`
    *   `updatedAt`: `timestamp`
    *   `deletedAt`: `timestamp`

---

### 2. Tenant-Scoped Subcollections (`/companies/{companyId}/...`)

#### Subcollection: `vehicles`
Stores fleet vehicle diagnostic metrics and telemetry status.

*   **Path:** `/companies/{companyId}/vehicles/{vehicleId}`
*   **Fields:**
    *   `id`: `string` (UUID)
    *   `vin`: `string` (Unique across vehicles)
    *   `licensePlate`: `string`
    *   `make`: `string`
    *   `model`: `string`
    *   `year`: `number`
    *   `status`: `string` (enum: `active` | `maintenance` | `in_transit` | `decommissioned`)
    *   `fuelType`: `string` (enum: `diesel` | `unleaded` | `electric`)
    *   `odometer`: `number` (Kilometers)
    *   `lastServiceDate`: `timestamp`
    *   `telemetry`: `map`
        *   `latitude`: `number`
        *   `longitude`: `number`
        *   `speed`: `number`
        *   `batteryHealth`: `string`
        *   `updatedAt`: `timestamp`
    *   `createdAt`: `timestamp`
    *   `updatedAt`: `timestamp`
    *   `deletedAt`: `timestamp`

#### Subcollection: `drivers`
Maintains operational details, license metrics, and compliance ratings for drivers.

*   **Path:** `/companies/{companyId}/drivers/{driverId}`
*   **Fields:**
    *   `id`: `string` (UUID, maps to `/users/{userId}`)
    *   `fullName`: `string`
    *   `phone`: `string`
    *   `licenseNumber`: `string`
    *   `licenseExpiry`: `timestamp`
    *   `status`: `string` (enum: `available` | `on_duty` | `suspended` | `off_duty`)
    *   `safetyScore`: `number` (Percentage: 0 - 100)
    *   `assignedVehicleId`: `string` (references `../vehicles/{vehicleId}`; optional)
    *   `createdAt`: `timestamp`
    *   `updatedAt`: `timestamp`
    *   `deletedAt`: `timestamp`

#### Subcollection: `trips`
Handles logistics manifests, routing coordinates, checkpoints, and real-time delivery phases.

*   **Path:** `/companies/{companyId}/trips/{tripId}`
*   **Fields:**
    *   `id`: `string` (UUID)
    *   `tripNumber`: `string` (Sequential, user-facing format: `TRIP-001048`)
    *   `status`: `string` (enum: `planned` | `assigned` | `in_transit` | `completed` | `cancelled`)
    *   `driverId`: `string` (references `../drivers/{driverId}`)
    *   `vehicleId`: `string` (references `../vehicles/{vehicleId}`)
    *   `cargo`: `map`
        *   `description`: `string`
        *   `weightKg`: `number`
        *   `hazardClass`: `string` (optional)
    *   `route`: `map`
        *   `startLocationName`: `string`
        *   `endLocationName`: `string`
        *   `estimatedDurationSec`: `number`
        *   `actualDurationSec`: `number` (updated on completion)
    *   `checkpoints`: `array` of `maps`
        *   `location`: `geopoint`
        *   `address`: `string`
        *   `status`: `string` (enum: `pending` | `passed` | `delayed`)
        *   `passedAt`: `timestamp`
    *   `startedAt`: `timestamp`
    *   `completedAt`: `timestamp`
    *   `createdAt`: `timestamp`
    *   `updatedAt`: `timestamp`
    *   `deletedAt`: `timestamp`

#### Subcollection: `inventory`
Manages fuel stocks, spare parts, and maintenance tooling assets.

*   **Path:** `/companies/{companyId}/inventory/{itemId}`
*   **Fields:**
    *   `id`: `string` (UUID)
    *   `partNumber`: `string`
    *   `name`: `string`
    *   `quantity`: `number`
    *   `minThreshold`: `number` (Alert limit for reorders)
    *   `unitPrice`: `number` (Currency decimal scale represented as cents: e.g. `$25.50` -> `2550`)
    *   `warehouseLocation`: `string`
    *   `createdAt`: `timestamp`
    *   `updatedAt`: `timestamp`
    *   `deletedAt`: `timestamp`

#### Subcollection: `audit_logs`
Automated, read-only system events containing system logs.

*   **Path:** `/companies/{companyId}/audit_logs/{logId}`
*   **Fields:**
    *   `id`: `string` (UUID)
    *   `userId`: `string` (references `/users/{userId}`)
    *   `userEmail`: `string`
    *   `action`: `string` (enum: `CREATE` | `UPDATE` | `DELETE` | `STATUS_CHANGE`)
    *   `collection`: `string` (e.g. `vehicles`)
    *   `documentId`: `string`
    *   `changes`: `map`
        *   `before`: `map` (Historical fields; empty for CREATE)
        *   `after`: `map` (Updated fields)
    *   `ipAddress`: `string`
    *   `userAgent`: `string`
    *   `timestamp`: `timestamp`

---

## 🔒 Security Rules & Access Control

These Firestore Security Rules enforce tenant-level isolation:
- Users can only read or write to `/companies/{companyId}/...` if the user's root `/users/{userId}` record has a matching `companyId`.
- No cross-tenant reads are allowed.
- Audit logs are read-only (`write: if false` except for backend services).

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions for security
    function isAuthenticated() {
      return request.auth != null;
    }

    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function isMemberOfCompany(companyId) {
      return isAuthenticated() 
        && getUserData().companyId == companyId 
        && getUserData().status == 'active';
    }

    function isCompanyAdmin(companyId) {
      return isMemberOfCompany(companyId) 
        && getUserData().role in ['company_admin', 'super_admin'];
    }

    // Rules for Root-level User accounts
    match /users/{userId} {
      allow read: if isAuthenticated() && (request.auth.uid == userId || getUserData().role == 'super_admin');
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (request.auth.uid == userId || getUserData().role == 'super_admin');
      allow delete: if false; // Users must be soft-deleted or suspended instead
    }

    // Rules for Root-level Company configuration details
    match /companies/{companyId} {
      allow read: if isMemberOfCompany(companyId);
      allow create: if isAuthenticated(); // Handled during company onboarding setup
      allow update: if isCompanyAdmin(companyId);
      allow delete: if false; // System deletion should occur via platform billing suspension pipeline only

      // Rules for Subcollections
      match /vehicles/{vehicleId} {
        allow read: if isMemberOfCompany(companyId);
        allow write: if isMemberOfCompany(companyId) && getUserData().role in ['company_admin', 'fleet_manager', 'dispatcher'];
      }

      match /drivers/{driverId} {
        allow read: if isMemberOfCompany(companyId);
        allow write: if isMemberOfCompany(companyId) && getUserData().role in ['company_admin', 'fleet_manager'];
      }

      match /trips/{tripId} {
        allow read: if isMemberOfCompany(companyId);
        // Dispatcher, admin, and assigned driver can update trips
        allow create, update: if isMemberOfCompany(companyId) && (
          getUserData().role in ['company_admin', 'dispatcher', 'fleet_manager'] ||
          (getUserData().role == 'driver' && resource.data.driverId == request.auth.uid)
        );
        allow delete: if isCompanyAdmin(companyId);
      }

      match /inventory/{itemId} {
        allow read: if isMemberOfCompany(companyId);
        allow write: if isMemberOfCompany(companyId) && getUserData().role in ['company_admin', 'fleet_manager'];
      }

      // Audit logs are append-only. Only cloud functions / server-side processes can write them.
      match /audit_logs/{logId} {
        allow read: if isCompanyAdmin(companyId);
        allow write: if false; 
      }
    }
  }
}
```

---

## ⚡ Index Optimization strategy

Firestore automatically builds single-field indexes, but compound indexes are mandatory for composite filter criteria. To prevent index limit exhaustion, composite indexes are minimized and restricted to core operational pathways.

### Required Composite Indexes:

1.  **Vehicle Live Monitoring Index:**
    *   Collection path: `vehicles`
    *   Fields: `deletedAt` (Ascending), `status` (Ascending), `telemetry.updatedAt` (Descending)
2.  **Trip Dispatch Management Index:**
    *   Collection path: `trips`
    *   Fields: `deletedAt` (Ascending), `driverId` (Ascending), `status` (Ascending), `startedAt` (Descending)
3.  **Critical Diagnostics Feed Index:**
    *   Collection path: `vehicles`
    *   Fields: `deletedAt` (Ascending), `status` (Ascending), `odometer` (Descending)
4.  **Security/Audit Log Trail Index:**
    *   Collection path: `audit_logs`
    *   Fields: `collection` (Ascending), `timestamp` (Descending)

---

## 🔄 Soft Delete & Audit Log Orchestration

### Soft Delete Strategy
To protect critical operations data from accidental removal, standard `delete` calls are prohibited. 
*   Every document includes a nullable `deletedAt` field of type `timestamp`.
*   Active documents carry `deletedAt = null`.
*   When a user soft-deletes a record, the client updates the document:
    ```javascript
    db.doc("companies/ABC/vehicles/123").update({ 
      deletedAt: FieldValue.serverTimestamp() 
    });
    ```
*   **Query Filtering:** All UI dashboard queries filter for active assets using:
    `where('deletedAt', '==', null)`

### Audit Log Pattern
Every transaction (create, update, status toggle) is accompanied by an audit record inside the `audit_logs` subcollection.
*   **Implementation:** Triggered via **Cloud Functions (`v2`)** listening to write operations.
*   **Cloud Function Hook:**
    ```typescript
    export const onVehicleWrite = onDocumentWritten("companies/{companyId}/vehicles/{vehicleId}", (event) => {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      
      const companyId = event.params.companyId;
      const vehicleId = event.params.vehicleId;
      
      let action = "UPDATE";
      if (!beforeData) action = "CREATE";
      if (!afterData) action = "DELETE";

      const logDoc = {
        userId: event.auth?.uid || "system",
        userEmail: event.auth?.token.email || "system@fleetos.com",
        action,
        collection: "vehicles",
        documentId: vehicleId,
        changes: {
          before: beforeData || {},
          after: afterData || {}
        },
        timestamp: Timestamp.now()
      };

      return admin.firestore()
        .collection("companies").doc(companyId)
        .collection("audit_logs").add(logDoc);
    });
    ```
