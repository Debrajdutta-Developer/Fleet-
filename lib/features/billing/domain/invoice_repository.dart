import '../../customers/domain/invoice_entity.dart';

abstract class InvoiceRepository {
  Stream<List<InvoiceEntity>> watchInvoices(String companyId);
  Future<List<InvoiceEntity>> getInvoices(String companyId);
  Future<InvoiceEntity?> getInvoiceById(String companyId, String invoiceId);
  Future<InvoiceEntity> createInvoice(String companyId, InvoiceEntity invoice);
  Future<void> updateInvoice(String companyId, InvoiceEntity invoice);
  Future<void> deleteInvoice(String companyId, String invoiceId);
}
