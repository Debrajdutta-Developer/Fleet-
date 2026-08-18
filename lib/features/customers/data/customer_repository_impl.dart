import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/customer_entity.dart';
import '../domain/contract_entity.dart';
import '../domain/invoice_entity.dart';
import '../domain/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CustomerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  // --- Customers ---

  @override
  Stream<List<CustomerEntity>> watchCustomers(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customers')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomerEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<CustomerEntity>> getCustomers(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<CustomerEntity?> getCustomerById(
      String companyId, String customerId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(customerId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return CustomerEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<CustomerEntity> createCustomer(
      String companyId, CustomerEntity customer) async {
    try {
      final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
      final newCustomer = customer.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(id)
          .set(newCustomer.toMap());

      return newCustomer;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateCustomer(String companyId, CustomerEntity customer) async {
    try {
      final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(customer.id)
          .update(updatedCustomer.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteCustomer(String companyId, String customerId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('customers')
          .doc(customerId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // --- Contracts ---

  @override
  Stream<List<ContractEntity>> watchContracts(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('contracts')
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<ContractEntity>> getContracts(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('contracts')
          .where('deletedAt', isNull: true)
          .get();

      return snapshot.docs
          .map((doc) => ContractEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ContractEntity?> getContractById(
      String companyId, String contractId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('contracts')
          .doc(contractId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data['deletedAt'] != null) return null;
      return ContractEntity.fromMap(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ContractEntity> createContract(
      String companyId, ContractEntity contract) async {
    try {
      final id = contract.id.isEmpty ? _uuid.v4() : contract.id;
      final newContract = contract.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('contracts')
          .doc(id)
          .set(newContract.toMap());

      return newContract;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> updateContract(String companyId, ContractEntity contract) async {
    try {
      final updatedContract = contract.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('contracts')
          .doc(contract.id)
          .update(updatedContract.toMap());
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteContract(String companyId, String contractId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('contracts')
          .doc(contractId)
          .update({
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // --- Invoices ---

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
  Future<void> updateInvoiceStatus(
      String companyId, String invoiceId, String status) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('invoices')
          .doc(invoiceId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
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
      });
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
