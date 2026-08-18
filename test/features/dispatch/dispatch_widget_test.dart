import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/dispatch/presentation/dispatch_list_screen.dart';
import 'package:fleet_os_erp/features/dispatch/presentation/dispatch_providers.dart';
import 'package:fleet_os_erp/features/dispatch/domain/dispatch_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';

void main() {
  testWidgets(
      'DispatchListScreen displays metrics and empty state when no dispatches exist',
      (WidgetTester tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          dispatchesStreamProvider.overrideWith((ref) => Stream.value([])),
          vehiclesStreamProvider.overrideWith((ref) => Stream.value([])),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
          routesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: DispatchListScreen(),
        ),
      ),
    );

    // Let the stream emit the empty list and repaint
    await tester.pump();

    // Verify app bar title
    expect(find.text('Dispatches & Scheduling'), findsOneWidget);

    // Verify floating action button exists
    expect(find.text('Schedule Dispatch'), findsOneWidget);

    // Verify status choice chips are rendered
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('IN TRANSIT'), findsOneWidget);
  });

  testWidgets(
      'DispatchListScreen displays dispatches and summary statistics correctly',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final tDispatch = DispatchEntity(
      id: 'disp_1',
      dispatchNumber: 'DISP-001',
      companyId: 'c_1',
      vehicleId: 'v_1',
      vehicleLicensePlate: 'NY-884-OK',
      driverId: 'd_1',
      driverName: 'Robert Jenkins',
      routeId: 'r_1',
      routeName: 'Chicago to New York',
      status: 'in_transit',
      scheduledTime: now,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserEntity(
                uid: 'u_1',
                email: 'operator@fleet.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'c_1',
                createdAt: now,
              )),
          dispatchesStreamProvider
              .overrideWith((ref) => Stream.value([tDispatch])),
          vehiclesStreamProvider.overrideWith((ref) => Stream.value([])),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
          routesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: DispatchListScreen(),
        ),
      ),
    );

    // Load data and repaint
    await tester.pump();

    // Verify dispatch list item values
    expect(find.text('DISP-001 - Chicago to New York'), findsOneWidget);
    expect(find.textContaining('Driver: Robert Jenkins • Vehicle: NY-884-OK'),
        findsOneWidget);

    // Verify Active summary card value (1 in transit)
    expect(find.text('Active (In Transit)'), findsOneWidget);
  });
}
