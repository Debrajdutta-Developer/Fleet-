import 'route_entity.dart';
import 'dispatch_entity.dart';

abstract class DispatchRepository {
  // Routes
  Stream<List<RouteEntity>> watchRoutes(String companyId);
  Future<List<RouteEntity>> getRoutes(String companyId);
  Future<RouteEntity> createRoute(String companyId, RouteEntity route);
  Future<void> updateRoute(String companyId, RouteEntity route);
  Future<void> deleteRoute(String companyId, String routeId);

  // Dispatches
  Stream<List<DispatchEntity>> watchDispatches(String companyId);
  Future<List<DispatchEntity>> getDispatches(String companyId);
  Future<DispatchEntity?> getDispatchById(String companyId, String id);
  Future<DispatchEntity> createDispatch(
      String companyId, DispatchEntity dispatch);
  Future<void> updateDispatch(String companyId, DispatchEntity dispatch);
  Future<void> updateDispatchStatus(
      String companyId, String dispatchId, String status);
  Future<void> deleteDispatch(String companyId, String id);
}
