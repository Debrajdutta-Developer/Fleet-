import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/fuel_entity.dart';
import '../domain/maintenance_entity.dart';
import '../domain/compliance_entity.dart';
import '../domain/fleet_ops_repository.dart';

class FleetOpsRepositoryImpl implements FleetOpsRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FleetOpsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // ================= FUEL LOGS =================

  @override
  Stream<List<FuelEntity>> watchFuelLogs(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('fuel_logs')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FuelEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<FuelEntity>> getFuelLogs(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('fuel_logs')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => FuelEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<FuelEntity> createFuelLog(String companyId, FuelEntity fuelLog) async {
    try {
      final id = fuelLog.id.isEmpty ? _uuid.v4() : fuelLog.id;
      final newLog = fuelLog.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('fuel_logs')
          .doc(id)
          .set(newLog.toMap());

      return newLog;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateFuelLog(String companyId, FuelEntity fuelLog) async {
    try {
      final updated = fuelLog.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('fuel_logs')
          .doc(fuelLog.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteFuelLog(String companyId, String fuelLogId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('fuel_logs')
          .doc(fuelLogId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ================= MAINTENANCE LOGS =================

  @override
  Stream<List<MaintenanceEntity>> watchMaintenanceLogs(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('maintenance_logs')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MaintenanceEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<MaintenanceEntity>> getMaintenanceLogs(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('maintenance_logs')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => MaintenanceEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<MaintenanceEntity> createMaintenanceLog(
      String companyId, MaintenanceEntity maintLog) async {
    try {
      final id = maintLog.id.isEmpty ? _uuid.v4() : maintLog.id;
      final newLog = maintLog.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('maintenance_logs')
          .doc(id)
          .set(newLog.toMap());

      return newLog;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateMaintenanceLog(
      String companyId, MaintenanceEntity maintLog) async {
    try {
      final updated = maintLog.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('maintenance_logs')
          .doc(maintLog.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteMaintenanceLog(String companyId, String maintLogId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('maintenance_logs')
          .doc(maintLogId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ================= COMPLIANCE DOCUMENTS =================

  @override
  Stream<List<ComplianceEntity>> watchComplianceDocuments(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('compliance_documents')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ComplianceEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<ComplianceEntity>> getComplianceDocuments(
      String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('compliance_documents')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => ComplianceEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ComplianceEntity> createComplianceDocument(
      String companyId, ComplianceEntity compliance) async {
    try {
      final id = compliance.id.isEmpty ? _uuid.v4() : compliance.id;
      final newDoc = compliance.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('compliance_documents')
          .doc(id)
          .set(newDoc.toMap());

      return newDoc;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateComplianceDocument(
      String companyId, ComplianceEntity compliance) async {
    try {
      final updated = compliance.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('compliance_documents')
          .doc(compliance.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteComplianceDocument(
      String companyId, String complianceId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('compliance_documents')
          .doc(complianceId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
