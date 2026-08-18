import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connection status enum for offline-first tracking.
enum ConnectionStatus { online, offline }

/// A service to monitor internet connectivity.
class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectionStatus> _controller =
      StreamController<ConnectionStatus>.broadcast();

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _controller.add(_mapResultToStatus(result));
    });
  }

  /// Stream to listen to network status updates.
  Stream<ConnectionStatus> get onStatusChanged => _controller.stream;

  /// Check current connection status synchronously/asynchronously.
  Future<ConnectionStatus> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return _mapResultToStatus(result);
  }

  /// Helper to map connectivity result to status.
  ConnectionStatus _mapResultToStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      return ConnectionStatus.offline;
    }
    return ConnectionStatus.online;
  }

  void dispose() {
    _controller.close();
  }
}

/// Provider to access ConnectivityService.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// StreamProvider to monitor live network status in widgets.
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChanged;
});
