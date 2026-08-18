import 'vendor_entity.dart';

abstract class VendorRepository {
  Stream<List<VendorEntity>> watchVendors(String companyId);
  Future<List<VendorEntity>> getVendors(String companyId);
  Future<VendorEntity?> getVendorById(String companyId, String vendorId);
  Future<VendorEntity> createVendor(String companyId, VendorEntity vendor);
  Future<void> updateVendor(String companyId, VendorEntity vendor);
  Future<void> deleteVendor(String companyId, String vendorId);
}
