import 'vehicle_entity.dart';

/// Contract defining Vehicle database operations in domain layer.
abstract class VehicleRepository {
  /// Stream monitoring active fleet list for real-time tracking
  Stream<List<VehicleEntity>> watchVehicles(String companyId);

  /// Fetch vehicles list (offline-friendly)
  Future<List<VehicleEntity>> getVehicles(String companyId);

  /// Create new vehicle asset record
  Future<VehicleEntity> createVehicle(String companyId, VehicleEntity vehicle);

  /// Update existing vehicle specifications
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle);

  /// Soft deletes vehicle record by setting deletedAt
  Future<void> deleteVehicle(String companyId, String vehicleId);

  /// Link or unlink primary driver to vehicle
  Future<void> assignDriver(
    String companyId,
    String vehicleId,
    String? driverId,
    String? driverName,
  );

  /// Upload compliance PDF/Image document to storage bucket and link URL
  Future<String> uploadComplianceDocument(
    String companyId,
    String vehicleId,
    String docType, // insurance, puc, fitness
    dynamic file,
  );
}
