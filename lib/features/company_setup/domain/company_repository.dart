import 'dart:io';
import 'company_entity.dart';

/// Contract definition for Company/Tenant configuration in Clean Architecture.
abstract class CompanyRepository {
  /// Create new company registry record.
  /// Throws [ServerFailure] on failure.
  Future<CompanyEntity> createCompany({
    required String name,
    required String ownerName,
    required String ownerUid,
    String? gstNumber,
    String? panNumber,
    required String phone,
    required String email,
    required String address,
    required String defaultCurrency,
    required String timeZone,
    File? logoFile,
  });

  /// Retrieve company details.
  Future<CompanyEntity?> getCompany(String companyId);

  /// Upload logo image to storage bucket and fetch URL.
  Future<String> uploadLogo(String companyId, File logoFile);
}
