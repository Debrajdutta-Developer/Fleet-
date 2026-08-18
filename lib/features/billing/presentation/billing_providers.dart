import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../customers/domain/customer_repository.dart';
import '../../customers/presentation/customer_providers.dart';
import '../../customers/domain/invoice_entity.dart';
import '../../trips/domain/audit_log_entity.dart';
import '../../trips/domain/trip_repository.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../trips/domain/trip_entity.dart';
import '../domain/invoice_repository.dart';
import '../data/invoice_repository_impl.dart';
import '../domain/payment_entity.dart';
import '../domain/payment_repository.dart';
import '../data/payment_repository_impl.dart';
import '../domain/ledger_entity.dart';
import '../domain/ledger_repository.dart';
import '../data/ledger_repository_impl.dart';

// --- Repository Providers ---

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl();
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepositoryImpl();
});

// --- Stream Providers ---

final billingInvoicesProvider =
    StreamProvider.autoDispose<List<InvoiceEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(invoiceRepositoryProvider).watchInvoices(user!.companyId!);
});

final billingPaymentsProvider =
    StreamProvider.autoDispose<List<PaymentEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(paymentRepositoryProvider).watchPayments(user!.companyId!);
});

final billingLedgerProvider =
    StreamProvider.autoDispose<List<LedgerEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(ledgerRepositoryProvider).watchLedger(user!.companyId!);
});

// --- Invoice Form State & Controller ---

class InvoiceFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const InvoiceFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  InvoiceFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return InvoiceFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class InvoiceFormController extends StateNotifier<InvoiceFormState> {
  final InvoiceRepository _invoiceRepo;
  final TripRepository _tripRepo;
  final LedgerRepository _ledgerRepo;
  final CustomerRepository _customerRepo;
  final Ref _ref;

  InvoiceFormController({
    required InvoiceRepository invoiceRepo,
    required TripRepository tripRepo,
    required LedgerRepository ledgerRepo,
    required CustomerRepository customerRepo,
    required Ref ref,
  })  : _invoiceRepo = invoiceRepo,
        _tripRepo = tripRepo,
        _ledgerRepo = ledgerRepo,
        _customerRepo = customerRepo,
        _ref = ref,
        super(const InvoiceFormState());

  Future<bool> saveInvoice(InvoiceEntity invoice) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      // 1. Validation: Prevent negative totals
      if (invoice.grandTotal < 0.0) {
        throw Exception('Grand total cannot be negative.');
      }
      if (invoice.freightCharge < 0.0 ||
          invoice.fuelCharge < 0.0 ||
          invoice.tollCharge < 0.0 ||
          invoice.extraCharges < 0.0 ||
          invoice.discount < 0.0 ||
          invoice.gstVat < 0.0) {
        throw Exception('Individual charges and discounts cannot be negative.');
      }

      // 2. Validation: Prevent duplicate invoice numbers
      final existingInvoices = await _invoiceRepo.getInvoices(companyId);
      final hasDuplicateNumber = existingInvoices.any((inv) =>
          inv.invoiceNumber.trim().toLowerCase() ==
              invoice.invoiceNumber.trim().toLowerCase() &&
          inv.id != invoice.id);
      if (hasDuplicateNumber) {
        throw Exception(
            'Invoice number "${invoice.invoiceNumber}" is already in use.');
      }

      // 3. Validation: Prevent editing paid invoices unless Admin
      if (invoice.id.isNotEmpty) {
        final currentInvoice =
            await _invoiceRepo.getInvoiceById(companyId, invoice.id);
        if (currentInvoice != null &&
            (currentInvoice.status == 'paid' ||
                currentInvoice.status == 'partially_paid' ||
                currentInvoice.amountPaid > 0.0)) {
          if (user.role != 'admin') {
            throw Exception(
                'Permission Blocked: Only Administrators can modify invoices with payment history.');
          }
        }
      }

      // Save Invoice
      InvoiceEntity savedInvoice;
      final isNew = invoice.id.isEmpty;
      if (isNew) {
        savedInvoice = await _invoiceRepo.createInvoice(companyId, invoice);
      } else {
        await _invoiceRepo.updateInvoice(companyId, invoice);
        savedInvoice = invoice;
      }

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'invoice',
        entityId: savedInvoice.id,
        action: isNew ? 'invoice_created' : 'invoice_updated',
        description: isNew
            ? 'Created Draft Invoice ${savedInvoice.invoiceNumber} for Customer ${savedInvoice.customerName}.'
            : 'Updated Invoice ${savedInvoice.invoiceNumber} details.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await _tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const InvoiceFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = InvoiceFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> issueInvoice(String invoiceId) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final invoice = await _invoiceRepo.getInvoiceById(companyId, invoiceId);
      if (invoice == null) throw Exception('Invoice not found.');
      if (invoice.status != 'draft')
        throw Exception('Only draft invoices can be issued.');

      final issuedInvoice = invoice.copyWith(
        status: 'issued',
        issueDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _invoiceRepo.updateInvoice(companyId, issuedInvoice);

      // Create official Finance Ledger Entries (Debit A/R, Credit Revenue)
      // Debit Accounts Receivable
      final arEntry = LedgerEntity(
        id: '',
        companyId: companyId,
        type: 'debit',
        accountType: 'accounts_receivable',
        amount: issuedInvoice.grandTotal,
        referenceId: issuedInvoice.id,
        description:
            'Accounts Receivable increased for Issued Invoice ${issuedInvoice.invoiceNumber}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _ledgerRepo.createLedgerEntry(companyId, arEntry);

      // Credit Revenue
      final revEntry = LedgerEntity(
        id: '',
        companyId: companyId,
        type: 'credit',
        accountType: 'revenue',
        amount: issuedInvoice.grandTotal,
        referenceId: issuedInvoice.id,
        description:
            'Revenue recognized for Issued Invoice ${issuedInvoice.invoiceNumber}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _ledgerRepo.createLedgerEntry(companyId, revEntry);

      // Update customer outstanding balance if not updated during draft creation (but we also update on payment)
      // For consistency, draft creation already increased it in trip completion flow. Let's make sure it is updated.

      // Audit Log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'invoice',
        entityId: issuedInvoice.id,
        action: 'invoice_issued',
        description:
            'Issued Invoice ${issuedInvoice.invoiceNumber} of amount $companyId.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await _tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const InvoiceFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = InvoiceFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final invoice = await _invoiceRepo.getInvoiceById(companyId, invoiceId);
      if (invoice == null) throw Exception('Invoice not found.');
      if (invoice.status == 'paid' && user.role != 'admin') {
        throw Exception(
            'Permission Blocked: Only Administrators can delete paid invoices.');
      }

      await _invoiceRepo.deleteInvoice(companyId, invoiceId);

      // Deduct from customer's outstanding balance
      final customer =
          await _customerRepo.getCustomerById(companyId, invoice.customerId);
      if (customer != null) {
        final updatedCustomer = customer.copyWith(
          outstandingBalance:
              (customer.outstandingBalance - invoice.outstandingAmount)
                  .clamp(0.0, double.infinity),
        );
        await _customerRepo.updateCustomer(companyId, updatedCustomer);
      }

      // Audit Log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'invoice',
        entityId: invoiceId,
        action: 'invoice_deleted',
        description: 'Deleted Invoice ${invoice.invoiceNumber}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await _tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const InvoiceFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = InvoiceFormState(errorMessage: e.toString());
      return false;
    }
  }

  TripEntity _dummyTrip(String companyId) {
    return TripEntity(
      id: '',
      companyId: companyId,
      vehicleId: '',
      vehicleLicensePlate: '',
      driverId: '',
      driverName: '',
      customerId: '',
      customerName: '',
      pickupLocation: '',
      deliveryLocation: '',
      cargoType: '',
      coalQuantity: 0.0,
      freightAmount: 0.0,
      advancePayment: 0.0,
      permitExpense: 0.0,
      status: 'draft',
      statusHistory: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

final billingInvoiceFormControllerProvider =
    StateNotifierProvider.autoDispose<InvoiceFormController, InvoiceFormState>(
        (ref) {
  return InvoiceFormController(
    invoiceRepo: ref.watch(invoiceRepositoryProvider),
    tripRepo: ref.watch(tripRepositoryProvider),
    ledgerRepo: ref.watch(ledgerRepositoryProvider),
    customerRepo: ref.watch(customerRepositoryProvider),
    ref: ref,
  );
});

// --- Payment Form State & Controller ---

class PaymentFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const PaymentFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  PaymentFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return PaymentFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class PaymentFormController extends StateNotifier<PaymentFormState> {
  final PaymentRepository _paymentRepo;
  final InvoiceRepository _invoiceRepo;
  final LedgerRepository _ledgerRepo;
  final CustomerRepository _customerRepo;
  final TripRepository _tripRepo;
  final Ref _ref;

  PaymentFormController({
    required PaymentRepository paymentRepo,
    required InvoiceRepository invoiceRepo,
    required LedgerRepository ledgerRepo,
    required CustomerRepository customerRepo,
    required TripRepository tripRepo,
    required Ref ref,
  })  : _paymentRepo = paymentRepo,
        _invoiceRepo = invoiceRepo,
        _ledgerRepo = ledgerRepo,
        _customerRepo = customerRepo,
        _tripRepo = tripRepo,
        _ref = ref,
        super(const PaymentFormState());

  Future<bool> recordPayment(PaymentEntity payment) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      // 1. Validation: Prevent invalid payment amounts
      if (payment.amount <= 0.0) {
        throw Exception('Payment amount must be greater than zero.');
      }

      final invoice =
          await _invoiceRepo.getInvoiceById(companyId, payment.invoiceId);
      if (invoice == null) throw Exception('Invoice not found.');

      if (payment.amount > invoice.outstandingAmount) {
        throw Exception(
            'Payment amount exceeds outstanding invoice balance (\$${invoice.outstandingAmount.toStringAsFixed(2)}).');
      }

      // Save Payment
      final savedPayment = await _paymentRepo.createPayment(companyId, payment);

      // Update Invoice outstanding amount & status
      final newAmountPaid = invoice.amountPaid + payment.amount;
      final newOutstanding =
          (invoice.grandTotal - newAmountPaid).clamp(0.0, double.infinity);
      String newStatus = invoice.status;
      if (newOutstanding == 0.0) {
        newStatus = 'paid';
      } else if (newAmountPaid > 0.0) {
        newStatus = 'partially_paid';
      }

      final updatedInvoice = invoice.copyWith(
        amountPaid: newAmountPaid,
        outstandingAmount: newOutstanding,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _invoiceRepo.updateInvoice(companyId, updatedInvoice);

      // Update Customer outstanding balance
      final customer =
          await _customerRepo.getCustomerById(companyId, invoice.customerId);
      if (customer != null) {
        final updatedCustomer = customer.copyWith(
          outstandingBalance: (customer.outstandingBalance - payment.amount)
              .clamp(0.0, double.infinity),
        );
        await _customerRepo.updateCustomer(companyId, updatedCustomer);
      }

      // Finance Ledger Entries (Debit Cash/Bank, Credit Accounts Receivable)
      // Debit Cash/Bank
      final cashEntry = LedgerEntity(
        id: '',
        companyId: companyId,
        type: 'debit',
        accountType: 'cash_bank',
        amount: payment.amount,
        referenceId: savedPayment.id,
        description:
            'Cash/Bank increased for payment received on Invoice ${invoice.invoiceNumber}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _ledgerRepo.createLedgerEntry(companyId, cashEntry);

      // Credit Accounts Receivable
      final arEntry = LedgerEntity(
        id: '',
        companyId: companyId,
        type: 'credit',
        accountType: 'accounts_receivable',
        amount: payment.amount,
        referenceId: savedPayment.id,
        description:
            'Accounts Receivable decreased for payment received on Invoice ${invoice.invoiceNumber}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _ledgerRepo.createLedgerEntry(companyId, arEntry);

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'payment',
        entityId: savedPayment.id,
        action: 'payment_received',
        description:
            'Received payment of \$${payment.amount.toStringAsFixed(2)} via ${payment.paymentMethod.toUpperCase()} for Invoice ${invoice.invoiceNumber}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await _tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const PaymentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = PaymentFormState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> refundPayment(String paymentId) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      final payment = await _paymentRepo.getPaymentById(companyId, paymentId);
      if (payment == null) throw Exception('Payment not found.');
      if (payment.status == 'refunded')
        throw Exception('Payment has already been refunded.');

      // Mark payment as refunded
      final refundedPayment = payment.copyWith(
        status: 'refunded',
        updatedAt: DateTime.now(),
      );
      await _paymentRepo.updatePayment(companyId, refundedPayment);

      // Get Invoice
      final invoice =
          await _invoiceRepo.getInvoiceById(companyId, payment.invoiceId);
      if (invoice == null) throw Exception('Invoice not found.');

      // Revert outstanding balance and amount paid on Invoice
      final newAmountPaid =
          (invoice.amountPaid - payment.amount).clamp(0.0, double.infinity);
      final newOutstanding =
          (invoice.grandTotal - newAmountPaid).clamp(0.0, double.infinity);
      String newStatus = invoice.status;
      if (newOutstanding == invoice.grandTotal) {
        newStatus = 'issued';
      } else if (newAmountPaid > 0.0) {
        newStatus = 'partially_paid';
      }

      final updatedInvoice = invoice.copyWith(
        amountPaid: newAmountPaid,
        outstandingAmount: newOutstanding,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _invoiceRepo.updateInvoice(companyId, updatedInvoice);

      // Revert Customer outstanding balance
      final customer =
          await _customerRepo.getCustomerById(companyId, invoice.customerId);
      if (customer != null) {
        final updatedCustomer = customer.copyWith(
          outstandingBalance: customer.outstandingBalance + payment.amount,
        );
        await _customerRepo.updateCustomer(companyId, updatedCustomer);
      }

      // Finance Ledger Entries (Debit Accounts Receivable, Credit Cash/Bank)
      // Debit Accounts Receivable
      final arEntry = LedgerEntity(
        id: '',
        companyId: companyId,
        type: 'debit',
        accountType: 'accounts_receivable',
        amount: payment.amount,
        referenceId: payment.id,
        description:
            'Accounts Receivable increased for refunded payment on Invoice ${invoice.invoiceNumber}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _ledgerRepo.createLedgerEntry(companyId, arEntry);

      // Credit Cash/Bank
      final cashEntry = LedgerEntity(
        id: '',
        companyId: companyId,
        type: 'credit',
        accountType: 'cash_bank',
        amount: payment.amount,
        referenceId: payment.id,
        description:
            'Cash/Bank decreased for refunded payment on Invoice ${invoice.invoiceNumber}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _ledgerRepo.createLedgerEntry(companyId, cashEntry);

      // Write Audit Log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'payment',
        entityId: paymentId,
        action: 'payment_refunded',
        description:
            'Refunded payment of \$${payment.amount.toStringAsFixed(2)} for Invoice ${invoice.invoiceNumber}.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );
      await _tripRepo.createTrip(companyId, _dummyTrip(companyId), auditLog);

      state = const PaymentFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = PaymentFormState(errorMessage: e.toString());
      return false;
    }
  }

  TripEntity _dummyTrip(String companyId) {
    return TripEntity(
      id: '',
      companyId: companyId,
      vehicleId: '',
      vehicleLicensePlate: '',
      driverId: '',
      driverName: '',
      customerId: '',
      customerName: '',
      pickupLocation: '',
      deliveryLocation: '',
      cargoType: '',
      coalQuantity: 0.0,
      freightAmount: 0.0,
      advancePayment: 0.0,
      permitExpense: 0.0,
      status: 'draft',
      statusHistory: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

final paymentFormControllerProvider =
    StateNotifierProvider.autoDispose<PaymentFormController, PaymentFormState>(
        (ref) {
  return PaymentFormController(
    paymentRepo: ref.watch(paymentRepositoryProvider),
    invoiceRepo: ref.watch(invoiceRepositoryProvider),
    ledgerRepo: ref.watch(ledgerRepositoryProvider),
    customerRepo: ref.watch(customerRepositoryProvider),
    tripRepo: ref.watch(tripRepositoryProvider),
    ref: ref,
  );
});

final billingAuditLogsProvider =
    StreamProvider.autoDispose<List<AuditLogEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(user!.companyId!)
      .collection('audit_logs')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AuditLogEntity.fromMap(doc.data()))
          .toList());
});
