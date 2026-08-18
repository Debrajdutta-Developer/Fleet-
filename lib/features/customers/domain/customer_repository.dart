import 'customer_entity.dart';
import 'contract_entity.dart';
import 'invoice_entity.dart';

abstract class CustomerRepository {
  // Customers
  Stream<List<CustomerEntity>> watchCustomers(String companyId);
  Future<List<CustomerEntity>> getCustomers(String companyId);
  Future<CustomerEntity?> getCustomerById(String companyId, String customerId);
  Future<CustomerEntity> createCustomer(
      String companyId, CustomerEntity customer);
  Future<void> updateCustomer(String companyId, CustomerEntity customer);
  Future<void> deleteCustomer(String companyId, String customerId);

  // Contracts
  Stream<List<ContractEntity>> watchContracts(String companyId);
  Future<List<ContractEntity>> getContracts(String companyId);
  Future<ContractEntity?> getContractById(String companyId, String contractId);
  Future<ContractEntity> createContract(
      String companyId, ContractEntity contract);
  Future<void> updateContract(String companyId, ContractEntity contract);
  Future<void> deleteContract(String companyId, String contractId);

  // Invoices
  Stream<List<InvoiceEntity>> watchInvoices(String companyId);
  Future<List<InvoiceEntity>> getInvoices(String companyId);
  Future<InvoiceEntity?> getInvoiceById(String companyId, String invoiceId);
  Future<InvoiceEntity> createInvoice(String companyId, InvoiceEntity invoice);
  Future<void> updateInvoiceStatus(
      String companyId, String invoiceId, String status);
  Future<void> deleteInvoice(String companyId, String invoiceId);
}
