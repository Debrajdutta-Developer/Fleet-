import 'fuel_entity.dart';
import 'maintenance_entity.dart';
import 'compliance_entity.dart';

abstract class FleetOpsRepository {
  // Fuel Management
  Stream<List<FuelEntity>> watchFuelLogs(String companyId);
  Future<List<FuelEntity>> getFuelLogs(String companyId);
  Future<FuelEntity> createFuelLog(String companyId, FuelEntity fuelLog);
  Future<void> updateFuelLog(String companyId, FuelEntity fuelLog);
  Future<void> deleteFuelLog(String companyId, String fuelLogId);

  // Maintenance Management
  Stream<List<MaintenanceEntity>> watchMaintenanceLogs(String companyId);
  Future<List<MaintenanceEntity>> getMaintenanceLogs(String companyId);
  Future<MaintenanceEntity> createMaintenanceLog(
      String companyId, MaintenanceEntity maintLog);
  Future<void> updateMaintenanceLog(
      String companyId, MaintenanceEntity maintLog);
  Future<void> deleteMaintenanceLog(String companyId, String maintLogId);

  // Compliance & Document Management
  Stream<List<ComplianceEntity>> watchComplianceDocuments(String companyId);
  Future<List<ComplianceEntity>> getComplianceDocuments(String companyId);
  Future<ComplianceEntity> createComplianceDocument(
      String companyId, ComplianceEntity compliance);
  Future<void> updateComplianceDocument(
      String companyId, ComplianceEntity compliance);
  Future<void> deleteComplianceDocument(String companyId, String complianceId);
}
