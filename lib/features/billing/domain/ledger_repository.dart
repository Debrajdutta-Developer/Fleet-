import 'ledger_entity.dart';

abstract class LedgerRepository {
  Stream<List<LedgerEntity>> watchLedger(String companyId);
  Future<List<LedgerEntity>> getLedger(String companyId);
  Future<LedgerEntity> createLedgerEntry(String companyId, LedgerEntity entry);
}
