import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../customers/domain/invoice_entity.dart';
import '../domain/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  InvoiceRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<InvoiceEntity>> watchInvoices(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invoices')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvoiceEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<InvoiceEntity>> getInvoices(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('invoices')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceEntity.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<InvoiceEntity?> getInvoiceById(
      String companyId, String invoiceId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return InvoiceEntity.fromMap(data);
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<InvoiceEntity> createInvoice(
      String companyId, InvoiceEntity invoice) async {
    try {
      final id = invoice.id.isEmpty ? _uuid.v4() : invoice.id;
      final newInvoice = invoice.copyWith(
        id: id,
        companyId: companyId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('invoices')
          .doc(id)
          .set(newInvoice.toMap());

      return newInvoice;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateInvoice(String companyId, InvoiceEntity invoice) async {
    try {
      final updatedInvoice = invoice.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('invoices')
          .doc(invoice.id)
          .set(updatedInvoice.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteInvoice(String companyId, String invoiceId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('invoices')
          .doc(invoiceId)
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
