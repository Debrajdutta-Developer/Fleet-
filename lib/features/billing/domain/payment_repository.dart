import 'payment_entity.dart';

abstract class PaymentRepository {
  Stream<List<PaymentEntity>> watchPayments(String companyId);
  Future<List<PaymentEntity>> getPayments(String companyId);
  Future<List<PaymentEntity>> getPaymentsForInvoice(
      String companyId, String invoiceId);
  Future<PaymentEntity?> getPaymentById(String companyId, String paymentId);
  Future<PaymentEntity> createPayment(String companyId, PaymentEntity payment);
  Future<void> updatePayment(String companyId, PaymentEntity payment);
  Future<void> deletePayment(String companyId, String paymentId);
}
