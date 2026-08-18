import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/part_entity.dart';
import '../domain/supplier_entity.dart';
import '../domain/inventory_transaction_entity.dart';
import '../domain/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  InventoryRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // ================= SPARE PARTS =================

  @override
  Stream<List<PartEntity>> watchParts(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('parts')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PartEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<PartEntity>> getParts(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('parts')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => PartEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<PartEntity?> getPartById(String companyId, String partId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('parts')
          .doc(partId)
          .get();
      if (!doc.exists) return null;
      return PartEntity.fromMap(doc.data()!);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<PartEntity> createPart(String companyId, PartEntity part) async {
    try {
      final id = part.id.isEmpty ? _uuid.v4() : part.id;
      final newPart = part.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('parts')
          .doc(id)
          .set(newPart.toMap());

      return newPart;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updatePart(String companyId, PartEntity part) async {
    try {
      final updated = part.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('parts')
          .doc(part.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deletePart(String companyId, String partId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('parts')
          .doc(partId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ================= SUPPLIERS =================

  @override
  Stream<List<SupplierEntity>> watchSuppliers(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('suppliers')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupplierEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<SupplierEntity>> getSuppliers(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('suppliers')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => SupplierEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<SupplierEntity?> getSupplierById(
      String companyId, String supplierId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('suppliers')
          .doc(supplierId)
          .get();
      if (!doc.exists) return null;
      return SupplierEntity.fromMap(doc.data()!);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<SupplierEntity> createSupplier(
      String companyId, SupplierEntity supplier) async {
    try {
      final id = supplier.id.isEmpty ? _uuid.v4() : supplier.id;
      final newSupplier = supplier.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('suppliers')
          .doc(id)
          .set(newSupplier.toMap());

      return newSupplier;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateSupplier(String companyId, SupplierEntity supplier) async {
    try {
      final updated = supplier.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('suppliers')
          .doc(supplier.id)
          .update(updated.toMap());
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteSupplier(String companyId, String supplierId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('suppliers')
          .doc(supplierId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ================= INVENTORY TRANSACTIONS =================

  @override
  Stream<List<InventoryTransactionEntity>> watchTransactions(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('inventory_transactions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryTransactionEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<InventoryTransactionEntity>> getTransactions(
      String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('inventory_transactions')
          .get();

      return snapshot.docs
          .map((doc) => InventoryTransactionEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<InventoryTransactionEntity> createTransaction(
      String companyId, InventoryTransactionEntity transaction) async {
    try {
      final id = transaction.id.isEmpty ? _uuid.v4() : transaction.id;
      final newTx = transaction.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('inventory_transactions')
          .doc(id)
          .set(newTx.toMap());

      return newTx;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
