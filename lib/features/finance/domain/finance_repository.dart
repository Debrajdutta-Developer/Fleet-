import '../../trips/domain/audit_log_entity.dart';
import 'finance_transaction_entity.dart';

abstract class FinanceRepository {
  /// Watch all active transactions for a company
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId);

  /// Fetch all active transactions for a company
  Future<List<FinanceTransactionEntity>> getTransactions(String companyId);

  /// Fetch a single transaction by ID
  Future<FinanceTransactionEntity?> getTransactionById(
    String companyId,
    String transactionId,
  );

  /// Create or update a transaction
  Future<FinanceTransactionEntity> createTransaction(
    String companyId,
    FinanceTransactionEntity transaction,
    AuditLogEntity auditLog,
  );

  /// Soft delete a transaction by updating its deletedAt timestamp
  Future<void> deleteTransaction(
    String companyId,
    String transactionId,
    AuditLogEntity auditLog,
  );

  /// Watch audit logs related to finance
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId);
}
