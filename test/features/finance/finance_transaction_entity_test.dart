import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';

void main() {
  group('FinanceTransactionEntity Tests', () {
    final tTxMap = {
      'id': 'tx_123',
      'companyId': 'comp_456',
      'type': 'expense',
      'category': 'diesel',
      'amount': 250.75,
      'paymentMode': 'upi',
      'referenceNumber': 'UPI-99421',
      'tripId': 'trip_001',
      'tripNumber': 'TRIP-001',
      'vehicleId': 'v_992',
      'vehicleLicensePlate': 'NY-OK-884',
      'notes': 'Refueled diesel at geofenced station',
      'transactionDate': '2026-07-06T12:00:00.000',
      'createdAt': '2026-07-06T12:00:00.000',
      'updatedAt': '2026-07-06T12:00:00.000',
      'deletedAt': null,
    };

    final tTxEntity = FinanceTransactionEntity(
      id: 'tx_123',
      companyId: 'comp_456',
      type: 'expense',
      category: 'diesel',
      amount: 250.75,
      paymentMode: 'upi',
      referenceNumber: 'UPI-99421',
      tripId: 'trip_001',
      tripNumber: 'TRIP-001',
      vehicleId: 'v_992',
      vehicleLicensePlate: 'NY-OK-884',
      notes: 'Refueled diesel at geofenced station',
      transactionDate: DateTime.parse('2026-07-06T12:00:00.000'),
      createdAt: DateTime.parse('2026-07-06T12:00:00.000'),
      updatedAt: DateTime.parse('2026-07-06T12:00:00.000'),
      deletedAt: null,
    );

    test('should parse from valid map representation correctly', () {
      final result = FinanceTransactionEntity.fromMap(tTxMap);
      expect(result.id, tTxEntity.id);
      expect(result.companyId, tTxEntity.companyId);
      expect(result.type, tTxEntity.type);
      expect(result.category, tTxEntity.category);
      expect(result.amount, tTxEntity.amount);
      expect(result.paymentMode, tTxEntity.paymentMode);
      expect(result.referenceNumber, tTxEntity.referenceNumber);
      expect(result.tripId, tTxEntity.tripId);
      expect(result.vehicleId, tTxEntity.vehicleId);
      expect(result.notes, tTxEntity.notes);
    });

    test('should serialize to matching map correctly', () {
      final result = tTxEntity.toMap();
      expect(result['id'], tTxMap['id']);
      expect(result['type'], tTxMap['type']);
      expect(result['category'], tTxMap['category']);
      expect(result['amount'], tTxMap['amount']);
      expect(result['paymentMode'], tTxMap['paymentMode']);
    });

    test('should copyWith updating specified parameters correctly', () {
      final updated = tTxEntity.copyWith(amount: 300.00, paymentMode: 'bank');
      expect(updated.amount, 300.00);
      expect(updated.paymentMode, 'bank');
      expect(updated.id, tTxEntity.id); // Stays unchanged
    });
  });
}
