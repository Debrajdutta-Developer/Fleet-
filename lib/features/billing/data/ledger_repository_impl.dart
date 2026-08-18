import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../domain/ledger_entity.dart';
import '../domain/ledger_repository.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  LedgerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = const Uuid();

  @override
  Stream<List<LedgerEntity>> watchLedger(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('ledger')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LedgerEntity.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<LedgerEntity>> getLedger(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('ledger')
          .get();

      return snapshot.docs
          .map((doc) => LedgerEntity.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<LedgerEntity> createLedgerEntry(
      String companyId, LedgerEntity entry) async {
    try {
      final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
      final newEntry = LedgerEntity(
        id: id,
        companyId: companyId,
        type: entry.type,
        accountType: entry.accountType,
        amount: entry.amount,
        referenceId: entry.referenceId,
        description: entry.description,
        date: entry.date,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('ledger')
          .doc(id)
          .set(newEntry.toMap());

      return newEntry;
    } on FirebaseException catch (e) {
      throw ServerFailure.fromFirebaseException(e.code, e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
