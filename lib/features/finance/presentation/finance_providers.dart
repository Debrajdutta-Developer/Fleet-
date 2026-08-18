import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../data/finance_repository_impl.dart';
import '../domain/finance_transaction_entity.dart';
import '../domain/finance_repository.dart';

/// Provider for FinanceRepository.
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepositoryImpl();
});

/// StreamProvider listening to real-time active transactions list.
final financeTransactionsStreamProvider =
    StreamProvider.autoDispose<List<FinanceTransactionEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(financeRepositoryProvider)
      .watchTransactions(user!.companyId!);
});

/// StreamProvider listening to audit logs for finance transactions.
final financeAuditLogsStreamProvider =
    StreamProvider.autoDispose<List<AuditLogEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref
      .watch(financeRepositoryProvider)
      .watchAuditLogsForFinance(user!.companyId!);
});

/// Ledger Entry Model containing a transaction and its running balance
class LedgerEntry {
  final FinanceTransactionEntity transaction;
  final double runningBalance;

  const LedgerEntry({required this.transaction, required this.runningBalance});
}

/// Provider to automatically calculate the Ledger with running balance from transactions
final ledgerProvider = Provider.autoDispose<List<LedgerEntry>>((ref) {
  final txsAsync = ref.watch(financeTransactionsStreamProvider);
  final txs = txsAsync.valueOrNull ?? [];

  // Sort oldest first to calculate running balance correctly
  final sorted = List<FinanceTransactionEntity>.from(txs)
    ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

  double balance = 0.0;
  final List<LedgerEntry> entries = [];

  for (final tx in sorted) {
    if (tx.type == 'income') {
      balance += tx.amount;
    } else {
      balance -= tx.amount;
    }
    entries.add(LedgerEntry(transaction: tx, runningBalance: balance));
  }

  // Return reversed (newest first) for UI display
  return entries.reversed.toList();
});

/// Profit and Loss Report Model
class ProfitLossReport {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final Map<String, double> expensesByCategory;

  const ProfitLossReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.expensesByCategory,
  });
}

/// Provider to automatically generate the Profit & Loss statement
final profitLossProvider = Provider.autoDispose<ProfitLossReport>((ref) {
  final txsAsync = ref.watch(financeTransactionsStreamProvider);
  final txs = txsAsync.valueOrNull ?? [];

  double income = 0.0;
  double expense = 0.0;
  final Map<String, double> expensesByCategory = {
    'driver_salary': 0.0,
    'advance_salary': 0.0,
    'diesel': 0.0,
    'toll': 0.0,
    'repair': 0.0,
    'tyre': 0.0,
    'insurance': 0.0,
    'miscellaneous': 0.0,
  };

  for (final tx in txs) {
    if (tx.type == 'income') {
      income += tx.amount;
    } else {
      expense += tx.amount;
      expensesByCategory[tx.category] =
          (expensesByCategory[tx.category] ?? 0.0) + tx.amount;
    }
  }

  return ProfitLossReport(
    totalIncome: income,
    totalExpense: expense,
    netProfit: income - expense,
    expensesByCategory: expensesByCategory,
  );
});

/// Summary Period representing a monthly/yearly row
class SummaryPeriod {
  final String label;
  final double income;
  final double expense;
  final double profit;

  const SummaryPeriod({
    required this.label,
    required this.income,
    required this.expense,
    required this.profit,
  });
}

/// Finance Summary Model
class FinanceSummary {
  final List<SummaryPeriod> monthlySummaries;
  final List<SummaryPeriod> yearlySummaries;

  const FinanceSummary({
    required this.monthlySummaries,
    required this.yearlySummaries,
  });
}

/// Provider to automatically generate monthly and yearly summaries
final financeSummaryProvider = Provider.autoDispose<FinanceSummary>((ref) {
  final txsAsync = ref.watch(financeTransactionsStreamProvider);
  final txs = txsAsync.valueOrNull ?? [];

  final Map<String, double> monthlyIncome = {};
  final Map<String, double> monthlyExpense = {};
  final Map<String, double> yearlyIncome = {};
  final Map<String, double> yearlyExpense = {};

  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  for (final tx in txs) {
    final date = tx.transactionDate;
    final monthKey = "${months[date.month - 1]} ${date.year}";
    final yearKey = "${date.year}";

    if (tx.type == 'income') {
      monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0.0) + tx.amount;
      yearlyIncome[yearKey] = (yearlyIncome[yearKey] ?? 0.0) + tx.amount;
    } else {
      monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0.0) + tx.amount;
      yearlyExpense[yearKey] = (yearlyExpense[yearKey] ?? 0.0) + tx.amount;
    }
  }

  final List<SummaryPeriod> monthly = [];
  final allMonthsKeys =
      (monthlyIncome.keys.toSet()..addAll(monthlyExpense.keys)).toList();

  // Sort keys chronologically (newest first)
  allMonthsKeys.sort((a, b) {
    final aParts = a.split(' ');
    final bParts = b.split(' ');
    final aYear = int.tryParse(aParts[1]) ?? 0;
    final bYear = int.tryParse(bParts[1]) ?? 0;
    if (aYear != bYear) return bYear.compareTo(aYear);
    final aMonth = months.indexOf(aParts[0]);
    final bMonth = months.indexOf(bParts[0]);
    return bMonth.compareTo(aMonth);
  });

  for (final key in allMonthsKeys) {
    final inc = monthlyIncome[key] ?? 0.0;
    final exp = monthlyExpense[key] ?? 0.0;
    monthly.add(
      SummaryPeriod(label: key, income: inc, expense: exp, profit: inc - exp),
    );
  }

  final List<SummaryPeriod> yearly = [];
  final allYearKeys = (yearlyIncome.keys.toSet()..addAll(yearlyExpense.keys))
      .toList()
    ..sort((a, b) => b.compareTo(a));

  for (final key in allYearKeys) {
    final inc = yearlyIncome[key] ?? 0.0;
    final exp = yearlyExpense[key] ?? 0.0;
    yearly.add(
      SummaryPeriod(label: key, income: inc, expense: exp, profit: inc - exp),
    );
  }

  return FinanceSummary(monthlySummaries: monthly, yearlySummaries: yearly);
});

/// UI State for Finance Form operations.
class FinanceFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const FinanceFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  FinanceFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return FinanceFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Controller overseeing transaction creation and editing
class FinanceFormController extends StateNotifier<FinanceFormState> {
  final FinanceRepository _repository;
  final Ref _ref;

  FinanceFormController({
    required FinanceRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const FinanceFormState());

  /// Save (create/update) transaction with verification audits
  Future<bool> saveTransaction(FinanceTransactionEntity transaction) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'finance_transaction',
        entityId: transaction.id,
        action: (transaction.id.isEmpty || transaction.id == 'tx_new')
            ? 'transaction_created'
            : 'transaction_updated',
        description: (transaction.id.isEmpty || transaction.id == 'tx_new')
            ? '${transaction.type.toUpperCase()} recorded for Category: ${transaction.category.toUpperCase()} with Amount: \$${transaction.amount.toStringAsFixed(2)}.'
            : 'Transaction updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await _repository.createTransaction(companyId, transaction, auditLog);
      state = const FinanceFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = FinanceFormState(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Provider for FinanceFormController.
final financeFormControllerProvider =
    StateNotifierProvider.autoDispose<FinanceFormController, FinanceFormState>((
  ref,
) {
  final repository = ref.watch(financeRepositoryProvider);
  return FinanceFormController(repository: repository, ref: ref);
});

/// Controller overseeing list actions (soft delete)
class FinanceListController extends StateNotifier<AsyncValue<void>> {
  final FinanceRepository _repository;
  final Ref _ref;

  FinanceListController({
    required FinanceRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Soft deletes a transaction, writing an audit log
  Future<bool> deleteTransaction(
    String transactionId,
    String category,
    double amount,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      final deleteAuditLog = AuditLogEntity(
        id: '',
        companyId: user!.companyId!,
        entityType: 'finance_transaction',
        entityId: transactionId,
        action: 'transaction_deleted',
        description:
            'Transaction $transactionId of Category $category and Amount \$$amount was soft-deleted.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await _repository.deleteTransaction(
        user.companyId!,
        transactionId,
        deleteAuditLog,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for FinanceListController.
final financeListControllerProvider =
    StateNotifierProvider.autoDispose<FinanceListController, AsyncValue<void>>((
  ref,
) {
  final repository = ref.watch(financeRepositoryProvider);
  return FinanceListController(repository: repository, ref: ref);
});
