import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/payment_entity.dart';
import '../domain/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  PaymentRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<PaymentEntity>> watchPayments(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('payments')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<PaymentEntity>> getPayments(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentEntity.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<List<PaymentEntity>> getPaymentsForInvoice(
      String companyId, String invoiceId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .where('invoiceId', isEqualTo: invoiceId)
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentEntity.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<PaymentEntity?> getPaymentById(
      String companyId, String paymentId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return PaymentEntity.fromMap(data);
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<PaymentEntity> createPayment(
      String companyId, PaymentEntity payment) async {
    try {
      final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
      final newPayment = payment.copyWith(
        id: id,
        companyId: companyId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .doc(id)
          .set(newPayment.toMap());

      return newPayment;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updatePayment(String companyId, PaymentEntity payment) async {
    try {
      final updatedPayment = payment.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .doc(payment.id)
          .set(updatedPayment.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deletePayment(String companyId, String paymentId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('payments')
          .doc(paymentId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
