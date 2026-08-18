import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../domain/finance_transaction_entity.dart';
import '../domain/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  FinanceRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('finance_transactions')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FinanceTransactionEntity.fromMap(doc.data()))
          .toList();
      // Sort in-memory to ensure correct sorting offline/online
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return list;
    });
  }

  @override
  Future<List<FinanceTransactionEntity>> getTransactions(
    String companyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('finance_transactions')
          .where('deletedAt', isNull: true)
          .get();

      final list = snapshot.docs
          .map((doc) => FinanceTransactionEntity.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return list;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<FinanceTransactionEntity?> getTransactionById(
    String companyId,
    String transactionId,
  ) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('finance_transactions')
          .doc(transactionId)
          .get();
      if (!doc.exists) return null;
      return FinanceTransactionEntity.fromMap(doc.data()!);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<FinanceTransactionEntity> createTransaction(
    String companyId,
    FinanceTransactionEntity transaction,
    AuditLogEntity auditLog,
  ) async {
    try {
      final transactionId =
          transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final auditLogId = auditLog.id.isEmpty ? _uuid.v4() : auditLog.id;

      final now = DateTime.now();
      final newTransaction = transaction.copyWith(
        id: transactionId,
        companyId: companyId,
        createdAt: transaction.id.isEmpty ? now : transaction.createdAt,
        updatedAt: now,
      );

      final newAuditLog = AuditLogEntity(
        id: auditLogId,
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: transactionId,
        action: auditLog.action,
        description: auditLog.description,
        userId: auditLog.userId,
        userName: auditLog.userName,
        timestamp: now,
      );

      final batch = _firestore.batch();

      final txRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('finance_transactions')
          .doc(transactionId);

      final auditRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLogId);

      batch.set(txRef, newTransaction.toMap());
      batch.set(auditRef, newAuditLog.toMap());

      await batch.commit();

      return newTransaction;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(
    String companyId,
    String transactionId,
    AuditLogEntity auditLog,
  ) async {
    try {
      final now = DateTime.now();
      final txRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('finance_transactions')
          .doc(transactionId);

      final auditLogId = auditLog.id.isEmpty ? _uuid.v4() : auditLog.id;
      final auditRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('audit_logs')
          .doc(auditLogId);

      final finalAuditLog = AuditLogEntity(
        id: auditLogId,
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: transactionId,
        action: auditLog.action,
        description: auditLog.description,
        userId: auditLog.userId,
        userName: auditLog.userName,
        timestamp: now,
      );

      final batch = _firestore.batch();
      batch.update(txRef, {
        'deletedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      batch.set(auditRef, finalAuditLog.toMap());

      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('audit_logs')
        .where('entityType', isEqualTo: 'finance_transaction')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AuditLogEntity.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
