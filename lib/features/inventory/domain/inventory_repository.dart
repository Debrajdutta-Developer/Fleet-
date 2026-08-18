import 'part_entity.dart';
import 'supplier_entity.dart';
import 'inventory_transaction_entity.dart';

abstract class InventoryRepository {
  // Spare Parts
  Stream<List<PartEntity>> watchParts(String companyId);
  Future<List<PartEntity>> getParts(String companyId);
  Future<PartEntity?> getPartById(String companyId, String partId);
  Future<PartEntity> createPart(String companyId, PartEntity part);
  Future<void> updatePart(String companyId, PartEntity part);
  Future<void> deletePart(String companyId, String partId);

  // Suppliers
  Stream<List<SupplierEntity>> watchSuppliers(String companyId);
  Future<List<SupplierEntity>> getSuppliers(String companyId);
  Future<SupplierEntity?> getSupplierById(String companyId, String supplierId);
  Future<SupplierEntity> createSupplier(
      String companyId, SupplierEntity supplier);
  Future<void> updateSupplier(String companyId, SupplierEntity supplier);
  Future<void> deleteSupplier(String companyId, String supplierId);

  // Inventory Transactions
  Stream<List<InventoryTransactionEntity>> watchTransactions(String companyId);
  Future<List<InventoryTransactionEntity>> getTransactions(String companyId);
  Future<InventoryTransactionEntity> createTransaction(
      String companyId, InventoryTransactionEntity transaction);
}
