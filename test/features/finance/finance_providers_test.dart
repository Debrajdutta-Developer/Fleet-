import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_repository.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';

class MockFinanceRepository implements FinanceRepository {
  final List<FinanceTransactionEntity> transactions;
  final List<AuditLogEntity> auditLogs = [];

  MockFinanceRepository({required this.transactions});

  @override
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId) {
    return Stream.value(transactions);
  }

  @override
  Future<List<FinanceTransactionEntity>> getTransactions(
    String companyId,
  ) async {
    return transactions;
  }

  @override
  Future<FinanceTransactionEntity?> getTransactionById(
    String companyId,
    String transactionId,
  ) async {
    try {
      return transactions.firstWhere((t) => t.id == transactionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FinanceTransactionEntity> createTransaction(
    String companyId,
    FinanceTransactionEntity transaction,
    AuditLogEntity auditLog,
  ) async {
    transactions.add(transaction);
    auditLogs.add(auditLog);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(
    String companyId,
    String transactionId,
    AuditLogEntity auditLog,
  ) async {
    final idx = transactions.indexWhere((t) => t.id == transactionId);
    if (idx != -1) {
      transactions[idx] = transactions[idx].copyWith(deletedAt: DateTime.now());
    }
    auditLogs.add(auditLog);
  }

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId) {
    return Stream.value(auditLogs);
  }
}

void main() {
  group('Finance Module Providers & Calculations Tests', () {
    late List<FinanceTransactionEntity> tTxs;
    final now = DateTime.now();

    setUp(() {
      tTxs = [
        FinanceTransactionEntity(
          id: 'tx_1',
          companyId: 'comp_1',
          type: 'income',
          category: 'income',
          amount: 5000.0,
          paymentMode: 'bank',
          transactionDate: now.subtract(const Duration(days: 5)),
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionEntity(
          id: 'tx_2',
          companyId: 'comp_1',
          type: 'expense',
          category: 'diesel',
          amount: 1500.0,
          paymentMode: 'upi',
          transactionDate: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
        ),
        FinanceTransactionEntity(
          id: 'tx_3',
          companyId: 'comp_1',
          type: 'expense',
          category: 'driver_salary',
          amount: 2000.0,
          paymentMode: 'cash',
          transactionDate: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    test(
      'should dynamically generate ledger with correct running balances',
      () async {
        final repository = MockFinanceRepository(transactions: tTxs);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => UserEntity(
                uid: 'user_1',
                email: 'test@company.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'comp_1',
                createdAt: DateTime.now(),
              ),
            ),
            financeRepositoryProvider.overrideWithValue(repository),
          ],
        );

        // Force stream read and wait for it to emit
        await container.read(financeTransactionsStreamProvider.future);

        final ledger = container.read(ledgerProvider);

        // Entries should be sorted newest first: tx_3, tx_2, tx_1
        expect(ledger.length, 3);
        expect(ledger[0].transaction.id, 'tx_3');
        expect(ledger[0].runningBalance, 1500.0); // 5000 - 1500 - 2000 = 1500

        expect(ledger[1].transaction.id, 'tx_2');
        expect(ledger[1].runningBalance, 3500.0); // 5000 - 1500 = 3500

        expect(ledger[2].transaction.id, 'tx_1');
        expect(ledger[2].runningBalance, 5000.0); // Initial income
      },
    );

    test('should dynamically calculate Profit/Loss statement', () async {
      final repository = MockFinanceRepository(transactions: tTxs);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          financeRepositoryProvider.overrideWithValue(repository),
        ],
      );

      await container.read(financeTransactionsStreamProvider.future);
      final pl = container.read(profitLossProvider);

      expect(pl.totalIncome, 5000.0);
      expect(pl.totalExpense, 3500.0);
      expect(pl.netProfit, 1500.0);
      expect(pl.expensesByCategory['diesel'], 1500.0);
      expect(pl.expensesByCategory['driver_salary'], 2000.0);
      expect(pl.expensesByCategory['repair'], 0.0);
    });

    test('should record transaction and audit log successfully', () async {
      final repository = MockFinanceRepository(transactions: []);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          financeRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final controller = container.read(financeFormControllerProvider.notifier);
      final tx = FinanceTransactionEntity(
        id: 'tx_new',
        companyId: 'comp_1',
        type: 'expense',
        category: 'toll',
        amount: 50.0,
        paymentMode: 'cash',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveTransaction(tx);
      expect(result, true);
      expect(repository.transactions.length, 1);
      expect(repository.transactions[0].id, 'tx_new');
      expect(repository.auditLogs.length, 1);
      expect(repository.auditLogs[0].action, 'transaction_created');
      expect(repository.auditLogs[0].userName, 'Operator John');
    });

    test(
      'should soft-delete transaction and write delete audit log successfully',
      () async {
        final repository = MockFinanceRepository(transactions: tTxs);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => UserEntity(
                uid: 'user_1',
                email: 'test@company.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'comp_1',
                createdAt: DateTime.now(),
              ),
            ),
            financeRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final controller = container.read(
          financeListControllerProvider.notifier,
        );
        final success = await controller.deleteTransaction(
          'tx_2',
          'diesel',
          1500.0,
        );

        expect(success, true);
        expect(repository.transactions[1].deletedAt, isNotNull);
        expect(repository.auditLogs.length, 1);
        expect(repository.auditLogs[0].action, 'transaction_deleted');
      },
    );
  });
}
