import 'report_entity.dart';

abstract class ReportRepository {
  Stream<List<ReportEntity>> watchReports(String companyId);
  Future<List<ReportEntity>> getReports(String companyId);
  Future<ReportEntity?> getReportById(String companyId, String id);
  Future<ReportEntity> createReport(String companyId, ReportEntity report);
  Future<void> deleteReport(String companyId, String id);
}
