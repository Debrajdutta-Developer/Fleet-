import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/report_entity.dart';
import '../domain/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  ReportRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<ReportEntity>> watchReports(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('reports')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<ReportEntity>> getReports(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('reports')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportEntity.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ReportEntity?> getReportById(String companyId, String id) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('reports')
          .doc(id)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return ReportEntity.fromMap(data);
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ReportEntity> createReport(
      String companyId, ReportEntity report) async {
    try {
      final id = report.id.isEmpty ? _uuid.v4() : report.id;
      final newReport = report.copyWith(
        id: id,
        companyId: companyId,
        generatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('reports')
          .doc(id)
          .set(newReport.toMap());

      return newReport;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteReport(String companyId, String id) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('reports')
          .doc(id)
          .update({'deletedAt': DateTime.now().toIso8601String()});
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
