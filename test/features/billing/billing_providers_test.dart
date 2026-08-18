import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_repository.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/contract_entity.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/billing/domain/invoice_repository.dart';
import 'package:fleet_os_erp/features/billing/domain/payment_entity.dart';
import 'package:fleet_os_erp/features/billing/domain/payment_repository.dart';
import 'package:fleet_os_erp/features/billing/domain/ledger_entity.dart';
import 'package:fleet_os_erp/features/billing/domain/ledger_repository.dart';
import 'package:fleet_os_erp/features/billing/presentation/billing_providers.dart';
import '../dispatch/dispatch_providers_test.dart' show MockTripRepository;

class MockInvoiceRepository implements InvoiceRepository {
  final List<InvoiceEntity> invoices;

  MockInvoiceRepository({required this.invoices});

  @override
  Stream<List<InvoiceEntity>> watchInvoices(String companyId) =>
      Stream.value(invoices);

  @override
  Future<List<InvoiceEntity>> getInvoices(String companyId) async => invoices;

  @override
  Future<InvoiceEntity?> getInvoiceById(
      String companyId, String invoiceId) async {
    try {
      return invoices.firstWhere((inv) => inv.id == invoiceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<InvoiceEntity> createInvoice(
      String companyId, InvoiceEntity invoice) async {
    final id = invoice.id.isEmpty ? 'inv_${invoices.length}' : invoice.id;
    final newInv = invoice.copyWith(id: id, companyId: companyId);
    invoices.add(newInv);
    return newInv;
  }

  @override
  Future<void> updateInvoice(String companyId, InvoiceEntity invoice) async {
    final idx = invoices.indexWhere((inv) => inv.id == invoice.id);
    if (idx != -1) {
      invoices[idx] = invoice;
    }
  }

  @override
  Future<void> deleteInvoice(String companyId, String invoiceId) async {
    final idx = invoices.indexWhere((inv) => inv.id == invoiceId);
    if (idx != -1) {
      invoices[idx] = invoices[idx].copyWith(deletedAt: DateTime.now());
    }
  }
}

class MockPaymentRepository implements PaymentRepository {
  final List<PaymentEntity> payments = [];

  @override
  Stream<List<PaymentEntity>> watchPayments(String companyId) =>
      Stream.value(payments);

  @override
  Future<List<PaymentEntity>> getPayments(String companyId) async => payments;

  @override
  Future<List<PaymentEntity>> getPaymentsForInvoice(
      String companyId, String invoiceId) async {
    return payments.where((p) => p.invoiceId == invoiceId).toList();
  }

  @override
  Future<PaymentEntity?> getPaymentById(
      String companyId, String paymentId) async {
    try {
      return payments.firstWhere((p) => p.id == paymentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PaymentEntity> createPayment(
      String companyId, PaymentEntity payment) async {
    final id = payment.id.isEmpty ? 'pay_${payments.length}' : payment.id;
    final newPay = payment.copyWith(id: id, companyId: companyId);
    payments.add(newPay);
    return newPay;
  }

  @override
  Future<void> updatePayment(String companyId, PaymentEntity payment) async {
    final idx = payments.indexWhere((p) => p.id == payment.id);
    if (idx != -1) {
      payments[idx] = payment;
    }
  }

  @override
  Future<void> deletePayment(String companyId, String paymentId) async {
    final idx = payments.indexWhere((p) => p.id == paymentId);
    if (idx != -1) {
      payments[idx] = payments[idx].copyWith(deletedAt: DateTime.now());
    }
  }
}

class MockLedgerRepository implements LedgerRepository {
  final List<LedgerEntity> ledgerEntries = [];

  @override
  Stream<List<LedgerEntity>> watchLedger(String companyId) =>
      Stream.value(ledgerEntries);

  @override
  Future<List<LedgerEntity>> getLedger(String companyId) async => ledgerEntries;

  @override
  Future<LedgerEntity> createLedgerEntry(
      String companyId, LedgerEntity entry) async {
    final id = entry.id.isEmpty ? 'led_${ledgerEntries.length}' : entry.id;
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
    ledgerEntries.add(newEntry);
    return newEntry;
  }
}

class MockCustomerRepositoryB implements CustomerRepository {
  final List<CustomerEntity> customers;
  MockCustomerRepositoryB({required this.customers});

  @override
  Stream<List<CustomerEntity>> watchCustomers(String companyId) =>
      Stream.value(customers);
  @override
  Future<List<CustomerEntity>> getCustomers(String companyId) async =>
      customers;
  @override
  Future<CustomerEntity?> getCustomerById(
      String companyId, String customerId) async {
    try {
      return customers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CustomerEntity> createCustomer(
      String companyId, CustomerEntity customer) async {
    customers.add(customer);
    return customer;
  }

  @override
  Future<void> updateCustomer(String companyId, CustomerEntity customer) async {
    final idx = customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      customers[idx] = customer;
    }
  }

  @override
  Future<void> deleteCustomer(String companyId, String customerId) async {}
  @override
  Stream<List<ContractEntity>> watchContracts(String companyId) =>
      Stream.value([]);
  @override
  Future<List<ContractEntity>> getContracts(String companyId) async => [];
  @override
  Future<ContractEntity?> getContractById(
          String companyId, String contractId) async =>
      null;
  @override
  Future<ContractEntity> createContract(
          String companyId, ContractEntity contract) async =>
      contract;
  @override
  Future<void> updateContract(
      String companyId, ContractEntity contract) async {}
  @override
  Future<void> deleteContract(String companyId, String contractId) async {}
  @override
  Stream<List<InvoiceEntity>> watchInvoices(String companyId) =>
      Stream.value([]);
  @override
  Future<List<InvoiceEntity>> getInvoices(String companyId) async => [];
  @override
  Future<InvoiceEntity?> getInvoiceById(
          String companyId, String invoiceId) async =>
      null;
  @override
  Future<InvoiceEntity> createInvoice(
          String companyId, InvoiceEntity invoice) async =>
      invoice;
  @override
  Future<void> updateInvoiceStatus(
      String companyId, String invoiceId, String status) async {}
  @override
  Future<void> deleteInvoice(String companyId, String invoiceId) async {}
}

void main() {
  final now = DateTime.now();

  group('Billing & Payment Engine Unit and Business Logic Tests', () {
    late MockInvoiceRepository invoiceRepo;
    late MockPaymentRepository paymentRepo;
    late MockLedgerRepository ledgerRepo;
    late MockCustomerRepositoryB customerRepo;
    late MockTripRepository tripRepo;
    late ProviderContainer container;

    setUp(() {
      final customer = CustomerEntity(
        id: 'cust_1',
        name: 'Walmart Corp',
        contactName: 'Jane Doe',
        email: 'jane@walmart.com',
        phone: '123456',
        address: 'HQ 1',
        outstandingBalance: 1000.0,
        creditLimit: 5000.0,
        createdAt: now,
        updatedAt: now,
      );

      invoiceRepo = MockInvoiceRepository(invoices: []);
      paymentRepo = MockPaymentRepository();
      ledgerRepo = MockLedgerRepository();
      customerRepo = MockCustomerRepositoryB(customers: [customer]);
      tripRepo = MockTripRepository(trips: []);

      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'admin@fleetos.com',
                displayName: 'Admin User',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          invoiceRepositoryProvider.overrideWithValue(invoiceRepo),
          paymentRepositoryProvider.overrideWithValue(paymentRepo),
          ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should prevent saving invoice with negative totals', () async {
      final controller =
          container.read(billingInvoiceFormControllerProvider.notifier);

      final invalidInvoice = InvoiceEntity(
        id: '',
        tripId: 't_1',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-1',
        freightCharge: -500.0, // negative
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      final success = await controller.saveInvoice(invalidInvoice);
      expect(success, false);
      expect(container.read(billingInvoiceFormControllerProvider).errorMessage,
          contains('cannot be negative'));
    });

    test('should prevent duplicate invoice numbers', () async {
      final controller =
          container.read(billingInvoiceFormControllerProvider.notifier);

      final inv1 = InvoiceEntity(
        id: 'inv_1',
        tripId: 't_1',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-DUPE',
        freightCharge: 1000.0,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      invoiceRepo.invoices.add(inv1);

      final inv2 = InvoiceEntity(
        id: '',
        tripId: 't_2',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-DUPE', // dupe number
        freightCharge: 1500.0,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      final success = await controller.saveInvoice(inv2);
      expect(success, false);
      expect(container.read(billingInvoiceFormControllerProvider).errorMessage,
          contains('already in use'));
    });

    test('should block non-admins from editing paid invoices', () async {
      // Set user role to operator (non-admin)
      final operatorContainer = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleetos.com',
                displayName: 'Operator User',
                role: 'operator',
                companyId: 'c_1',
                createdAt: now,
              )),
          invoiceRepositoryProvider.overrideWithValue(invoiceRepo),
          paymentRepositoryProvider.overrideWithValue(paymentRepo),
          ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller =
          operatorContainer.read(billingInvoiceFormControllerProvider.notifier);

      final paidInvoice = InvoiceEntity(
        id: 'inv_paid',
        tripId: 't_1',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-PAID',
        freightCharge: 1000.0,
        amountPaid: 1000.0,
        outstandingAmount: 0.0,
        status: 'paid',
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      invoiceRepo.invoices.add(paidInvoice);

      final modified = paidInvoice.copyWith(notes: 'Trying to edit notes');
      final success = await controller.saveInvoice(modified);
      expect(success, false);
      expect(
          operatorContainer
              .read(billingInvoiceFormControllerProvider)
              .errorMessage,
          contains('Only Administrators can modify'));
    });

    test('should issue invoice, record ledger entries and log audit', () async {
      final controller =
          container.read(billingInvoiceFormControllerProvider.notifier);

      final draftInvoice = InvoiceEntity(
        id: 'inv_draft',
        tripId: 't_1',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-DRAFT',
        freightCharge: 1000.0,
        status: 'draft',
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      invoiceRepo.invoices.add(draftInvoice);

      final success = await controller.issueInvoice(draftInvoice.id);
      expect(success, true);

      // Verify status changed to issued
      expect(invoiceRepo.invoices[0].status, 'issued');

      // Verify Ledger entries created (Debit AR, Credit Revenue)
      expect(ledgerRepo.ledgerEntries.length, 2);
      expect(ledgerRepo.ledgerEntries[0].accountType, 'accounts_receivable');
      expect(ledgerRepo.ledgerEntries[0].type, 'debit');
      expect(ledgerRepo.ledgerEntries[0].amount, 1000.0);

      expect(ledgerRepo.ledgerEntries[1].accountType, 'revenue');
      expect(ledgerRepo.ledgerEntries[1].type, 'credit');
      expect(ledgerRepo.ledgerEntries[1].amount, 1000.0);

      // Verify audit log registered
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'invoice_issued');
    });

    test(
        'should record payments, automatically update outstanding amount and customer balance',
        () async {
      final controller = container.read(paymentFormControllerProvider.notifier);

      final issuedInvoice = InvoiceEntity(
        id: 'inv_issued',
        tripId: 't_1',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-ISSUED',
        freightCharge: 1000.0,
        status: 'issued',
        amountPaid: 0.0,
        outstandingAmount: 1000.0,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      invoiceRepo.invoices.add(issuedInvoice);

      final payment = PaymentEntity(
        id: '',
        companyId: 'c_1',
        invoiceId: 'inv_issued',
        amount: 400.0, // partial payment
        paymentMethod: 'upi',
        status: 'completed',
        paymentDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final success = await controller.recordPayment(payment);
      expect(success, true);

      // Verify Invoice Updated
      final updatedInv = invoiceRepo.invoices[0];
      expect(updatedInv.amountPaid, 400.0);
      expect(updatedInv.outstandingAmount, 600.0);
      expect(updatedInv.status, 'partially_paid');

      // Verify Customer balance updated (decreased outstandingBalance from 1000.0 to 600.0)
      expect(customerRepo.customers[0].outstandingBalance, 600.0);

      // Verify Ledger entries created (Debit cash_bank, Credit accounts_receivable)
      expect(ledgerRepo.ledgerEntries.length, 2);
      expect(ledgerRepo.ledgerEntries[0].accountType, 'cash_bank');
      expect(ledgerRepo.ledgerEntries[0].type, 'debit');
      expect(ledgerRepo.ledgerEntries[0].amount, 400.0);

      expect(ledgerRepo.ledgerEntries[1].accountType, 'accounts_receivable');
      expect(ledgerRepo.ledgerEntries[1].type, 'credit');
      expect(ledgerRepo.ledgerEntries[1].amount, 400.0);
    });

    test('should block payment from exceeding outstanding balance', () async {
      final controller = container.read(paymentFormControllerProvider.notifier);

      final issuedInvoice = InvoiceEntity(
        id: 'inv_issued',
        tripId: 't_1',
        customerId: 'cust_1',
        customerName: 'Walmart Corp',
        invoiceNumber: 'INV-ISSUED',
        freightCharge: 1000.0,
        status: 'issued',
        amountPaid: 0.0,
        outstandingAmount: 1000.0,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      invoiceRepo.invoices.add(issuedInvoice);

      final payment = PaymentEntity(
        id: '',
        companyId: 'c_1',
        invoiceId: 'inv_issued',
        amount: 1200.0, // invalid amount exceeding 1000.0 outstanding
        paymentMethod: 'upi',
        status: 'completed',
        paymentDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final success = await controller.recordPayment(payment);
      expect(success, false);
      expect(container.read(paymentFormControllerProvider).errorMessage,
          contains('exceeds outstanding invoice balance'));
    });
  });
}
