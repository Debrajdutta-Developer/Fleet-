import 'driver_entity.dart';

abstract class DriverRepository {
  /// Stream monitoring drivers list for real-time tracking
  Stream<List<DriverEntity>> watchDrivers(String companyId);

  /// Fetch drivers list (offline-friendly)
  Future<List<DriverEntity>> getDrivers(String companyId);

  /// Fetch single driver details
  Future<DriverEntity?> getDriverById(String companyId, String driverId);

  /// Create new driver record
  Future<DriverEntity> createDriver(String companyId, DriverEntity driver);

  /// Update existing driver details
  Future<void> updateDriver(String companyId, DriverEntity driver);

  /// Soft deletes driver record by setting deletedAt
  Future<void> deleteDriver(String companyId, String driverId);

  /// Update driver status directly
  Future<void> updateDriverStatus(
      String companyId, String driverId, String status);

  /// Link or unlink primary vehicle to driver
  Future<void> linkVehicle(
    String companyId,
    String driverId,
    String? vehicleId,
    String? vehicleLicensePlate,
  );
}
