import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/contract_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/invoice_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_repository.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_repository.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';

class MockCustomerRepository implements CustomerRepository {
  final List<CustomerEntity> customers;
  final List<ContractEntity> contracts = [];
  final List<InvoiceEntity> invoices = [];

  MockCustomerRepository({required this.customers});

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
  Future<void> deleteCustomer(String companyId, String customerId) async {
    final idx = customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      customers[idx] = customers[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  // Contracts
  @override
  Stream<List<ContractEntity>> watchContracts(String companyId) =>
      Stream.value(contracts);
  @override
  Future<List<ContractEntity>> getContracts(String companyId) async =>
      contracts;
  @override
  Future<ContractEntity?> getContractById(
      String companyId, String contractId) async {
    try {
      return contracts.firstWhere((c) => c.id == contractId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ContractEntity> createContract(
      String companyId, ContractEntity contract) async {
    contracts.add(contract);
    return contract;
  }

  @override
  Future<void> updateContract(String companyId, ContractEntity contract) async {
    final idx = contracts.indexWhere((c) => c.id == contract.id);
    if (idx != -1) {
      contracts[idx] = contract;
    }
  }

  @override
  Future<void> deleteContract(String companyId, String contractId) async {
    final idx = contracts.indexWhere((c) => c.id == contractId);
    if (idx != -1) {
      contracts[idx] = contracts[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  // Invoices
  @override
  Stream<List<InvoiceEntity>> watchInvoices(String companyId) =>
      Stream.value(invoices);
  @override
  Future<List<InvoiceEntity>> getInvoices(String companyId) async => invoices;
  @override
  Future<InvoiceEntity?> getInvoiceById(
      String companyId, String invoiceId) async {
    try {
      return invoices.firstWhere((i) => i.id == invoiceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<InvoiceEntity> createInvoice(
      String companyId, InvoiceEntity invoice) async {
    invoices.add(invoice);
    return invoice;
  }

  @override
  Future<void> updateInvoiceStatus(
      String companyId, String invoiceId, String status) async {
    final idx = invoices.indexWhere((i) => i.id == invoiceId);
    if (idx != -1) {
      invoices[idx] = invoices[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> deleteInvoice(String companyId, String invoiceId) async {
    final idx = invoices.indexWhere((i) => i.id == invoiceId);
    if (idx != -1) {
      invoices[idx] = invoices[idx].copyWith(deletedAt: DateTime.now());
    }
  }
}

class MockTripRepository implements TripRepository {
  final List<AuditLogEntity> auditLogs = [];
  final List<TripEntity> trips = [];

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) => Stream.value(trips);

  @override
  Future<List<TripEntity>> getTrips(String companyId) async => trips;

  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async {
    try {
      return trips.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TripEntity> createTrip(
      String companyId, TripEntity trip, AuditLogEntity initialAuditLog) async {
    auditLogs.add(initialAuditLog);
    final idx = trips.indexWhere((t) => t.id == trip.id);
    if (idx != -1) {
      trips[idx] = trip;
    } else {
      trips.add(trip);
    }
    return trip;
  }

  @override
  Future<void> updateTripStatus(String companyId, String tripId,
      String newStatus, String cbId, String cbName,
      {String? notes}) async {
    final idx = trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      trips[idx] = trips[idx].copyWith(status: newStatus);
    }
  }

  @override
  Future<void> deleteTrip(
      String companyId, String tripId, AuditLogEntity deleteAuditLog) async {}

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
          String companyId, String tripId) =>
      Stream.value([]);

  Stream<List<AuditLogEntity>> watchAuditLogs(String companyId) =>
      Stream.value(auditLogs);
}

class MockVehicleRepository implements VehicleRepository {
  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {}
  @override
  Stream<List<VehicleEntity>> watchVehicles(String companyId) =>
      Stream.value([]);
  @override
  Future<List<VehicleEntity>> getVehicles(String companyId) async => [];
  @override
  Future<VehicleEntity> createVehicle(
          String companyId, VehicleEntity vehicle) async =>
      vehicle;
  @override
  Future<void> deleteVehicle(String companyId, String vehicleId) async {}
  @override
  Future<void> assignDriver(String companyId, String vehicleId,
      String? driverId, String? driverName) async {}
  @override
  Future<String> uploadComplianceDocument(String companyId, String vehicleId,
          String docType, dynamic file) async =>
      '';
}

class MockFinanceRepository implements FinanceRepository {
  final List<FinanceTransactionEntity> txs = [];

  @override
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId) =>
      Stream.value(txs);
  @override
  Future<List<FinanceTransactionEntity>> getTransactions(
          String companyId) async =>
      txs;
  @override
  Future<FinanceTransactionEntity?> getTransactionById(
          String companyId, String transactionId) async =>
      null;
  @override
  Future<FinanceTransactionEntity> createTransaction(String companyId,
      FinanceTransactionEntity transaction, AuditLogEntity auditLog) async {
    txs.add(transaction);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(
      String companyId, String transactionId, AuditLogEntity auditLog) async {}
  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId) =>
      Stream.value([]);
}

void main() {
  group('Customer & Contract Providers Business Logic Tests', () {
    final now = DateTime.now();
    final tCustomers = [
      CustomerEntity(
        id: 'cust_1',
        name: 'Walmart Fulfillment',
        contactName: 'Alice',
        phone: '1234567890',
        email: 'alice@walmart.com',
        address: 'Bentonville',
        createdAt: now,
        updatedAt: now,
        creditLimit: 5000.0,
        outstandingBalance: 1000.0,
      ),
    ];

    test('should save customer and write audit logs successfully', () async {
      final customerRepo =
          MockCustomerRepository(customers: List.from(tCustomers));
      final tripRepo = MockTripRepository();

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
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller =
          container.read(customerFormControllerProvider.notifier);
      final newCustomer = CustomerEntity(
        id: '',
        name: 'Amazon Retail Inc.',
        contactName: 'Bob',
        phone: '0987654321',
        email: 'bob@amazon.com',
        address: 'Seattle',
        createdAt: now,
        updatedAt: now,
        contacts: [
          const ContactPerson(
              name: 'Charlie',
              email: 'c@amazon.com',
              phone: '123',
              role: 'Billing')
        ],
        creditLimit: 10000.0,
      );

      final result = await controller.saveCustomer(newCustomer);

      expect(result, true);
      expect(customerRepo.customers.length, 2);
      expect(customerRepo.customers[1].name, 'Amazon Retail Inc.');
      expect(customerRepo.customers[1].contacts.length, 1);
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'customer_created');
    });

    test(
        'should validate customer credit limit and block trip scheduling if exceeded',
        () async {
      final customerRepo =
          MockCustomerRepository(customers: List.from(tCustomers));
      final tripRepo = MockTripRepository();

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
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          vehicleRepositoryProvider.overrideWithValue(MockVehicleRepository()),
        ],
      );

      final formController =
          container.read(tripFormControllerProvider.notifier);

      // Walmart has creditLimit = 5000.0, outstandingBalance = 1000.0.
      // Scheduling a trip with freightAmount = 4500.0 (total 5500.0) should fail.
      final trip = TripEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: 'veh_1',
        vehicleLicensePlate: 'LP1',
        driverId: 'drv_1',
        driverName: 'Driver 1',
        customerId: 'cust_1',
        customerName: 'Walmart Fulfillment',
        pickupLocation: 'Hub A',
        deliveryLocation: 'Plant B',
        cargoType: 'Coal',
        coalQuantity: 20.0,
        freightAmount: 4500.0,
        advancePayment: 0.0,
        permitExpense: 0.0,
        status: 'draft',
        statusHistory: const [],
        createdAt: now,
        updatedAt: now,
      );

      final success = await formController.saveTrip(trip);
      expect(success, false);
      expect(container.read(tripFormControllerProvider).errorMessage,
          contains('exceeded'));
    });

    test(
        'should auto-draft invoice and update customer balance on trip completion based on contract pricing',
        () async {
      final customerRepo =
          MockCustomerRepository(customers: List.from(tCustomers));
      final tripRepo = MockTripRepository();
      final vehicleRepo = MockVehicleRepository();
      final financeRepo = MockFinanceRepository();

      final contract = ContractEntity(
        id: 'contract_1',
        customerId: 'cust_1',
        customerName: 'Walmart Fulfillment',
        contractNumber: 'CON-001',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 5)),
        status: 'active',
        defaultFreightRate: 15.0, // $15 per ton
        routeRates: [
          const RouteRate(
              pickup: 'Hub A', delivery: 'Plant B', ratePerTon: 22.0),
        ],
        createdAt: now,
        updatedAt: now,
      );
      customerRepo.contracts.add(contract);

      final trip = TripEntity(
        id: 'trip_1',
        companyId: 'comp_1',
        vehicleId: 'veh_1',
        vehicleLicensePlate: 'LP1',
        driverId: 'drv_1',
        driverName: 'Driver 1',
        customerId: 'cust_1',
        customerName: 'Walmart Fulfillment',
        pickupLocation: 'Hub A',
        deliveryLocation: 'Plant B',
        cargoType: 'Coal',
        coalQuantity: 20.0,
        freightAmount:
            50.0, // Overwritten by contract rate $22/ton * 20 tons = $440
        advancePayment: 0.0,
        permitExpense: 0.0,
        status: 'inTransit',
        statusHistory: const [],
        createdAt: now,
        updatedAt: now,
      );
      tripRepo.trips.add(trip);

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
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          financeRepositoryProvider.overrideWithValue(financeRepo),
        ],
      );

      final listController =
          container.read(tripListControllerProvider.notifier);
      final result = await listController.updateStatus('trip_1', 'completed');

      expect(result, true);

      // Verify draft invoice was created with contract rate: $440
      expect(customerRepo.invoices.length, 1);
      expect(customerRepo.invoices[0].amount, 440.0);
      expect(customerRepo.invoices[0].status, 'draft');

      // Verify customer balance was incremented by $440
      final updatedWalmart =
          customerRepo.customers.firstWhere((c) => c.id == 'cust_1');
      expect(updatedWalmart.outstandingBalance, 1440.0); // 1000 base + 440 new

      // Verify income finance transaction logged $440
      expect(financeRepo.txs.length, 1);
      expect(financeRepo.txs[0].amount, 440.0);
    });
  });
}
