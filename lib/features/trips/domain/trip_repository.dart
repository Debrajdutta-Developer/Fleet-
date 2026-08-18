import 'trip_entity.dart';
import 'audit_log_entity.dart';

abstract class TripRepository {
  /// Stream monitoring trips list (offline-friendly real-time updates)
  Stream<List<TripEntity>> watchTrips(String companyId);

  /// Fetch trips list
  Future<List<TripEntity>> getTrips(String companyId);

  /// Fetch a single trip by ID
  Future<TripEntity?> getTripById(String companyId, String tripId);

  /// Create a new trip.
  Future<TripEntity> createTrip(
    String companyId,
    TripEntity trip,
    AuditLogEntity initialAuditLog,
  );

  /// Update trip status and record status history change & audit log
  Future<void> updateTripStatus(
    String companyId,
    String tripId,
    String newStatus,
    String changedByUserId,
    String changedByUserName, {
    String? notes,
  });

  /// Soft deletes trip record by setting deletedAt
  Future<void> deleteTrip(
    String companyId,
    String tripId,
    AuditLogEntity deleteAuditLog,
  );

  /// Fetch audit logs for a trip (or general audit logs)
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
    String companyId,
    String tripId,
  );
}
