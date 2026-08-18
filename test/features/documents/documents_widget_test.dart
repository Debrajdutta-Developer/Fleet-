import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/drivers/presentation/driver_providers.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/documents/domain/document_entity.dart';
import 'package:fleet_os_erp/features/documents/presentation/document_list_screen.dart';
import 'package:fleet_os_erp/features/documents/presentation/document_providers.dart';
import 'documents_providers_test.dart' show MockDocumentRepository;

void main() {
  testWidgets(
      'DocumentListScreen renders Material 3 widgets, sorting, and drag drop mock',
      (WidgetTester tester) async {
    final now = DateTime.now();

    final testDoc = DocumentEntity(
      id: 'doc_1',
      companyId: 'c_1',
      fileName: 'GST Certificate 2026',
      category: 'company',
      type: 'gst_certificate',
      originalFileName: 'gst.pdf',
      fileSize: 150000,
      mimeType: 'application/pdf',
      storagePath: 'documents/gst.pdf',
      downloadUrl: 'https://mock-storage/gst.pdf',
      uploadDate: now,
      status: 'pending_verification',
      uploadedBy: 'Operator John',
      documentNumber: 'GST-9988-12',
      createdAt: now,
      updatedAt: now,
    );

    final mockRepo = MockDocumentRepository();
    await mockRepo.createDocument('c_1', testDoc);

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
          documentRepositoryProvider.overrideWithValue(mockRepo),
          vehiclesStreamProvider.overrideWith((ref) => Stream.value([])),
          driversStreamProvider.overrideWith((ref) => Stream.value([])),
          customersStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: DocumentListScreen(),
        ),
      ),
    );

    // Let UI render
    await tester.pumpAndSettle();

    // 1. Verify main screen title
    expect(find.text('Enterprise Document Vault'), findsOneWidget);

    // 2. Verify Tab headers
    expect(find.textContaining('All Vault Documents'), findsOneWidget);
    expect(find.textContaining('Vault Expirations'), findsOneWidget);
    expect(find.textContaining('Approval Inbox'), findsOneWidget);

    // 3. Verify Dashboard Widget Cards
    expect(find.text('Total Documents'), findsOneWidget);
    expect(find.text('Expiring Soon (30d)'), findsOneWidget);
    expect(find.text('Expired Documents'), findsOneWidget);

    // 4. Verify Document Card is listed in list view
    expect(find.text('GST Certificate 2026'), findsOneWidget);
    expect(find.text('Type: GST Certificate'), findsOneWidget);

    // 5. Verify Filter and Sort dropdown indicators
    expect(find.text('All Categories'), findsOneWidget);
    expect(find.text('Date Uploaded (Newest)'), findsOneWidget);

    // 6. Verify Drag & Drop visual panel is present on desktop sizes
    // We simulate a desktop layout width by setting the screen size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pump();
    expect(find.text('Drag & Drop Files Here'), findsOneWidget);

    // Reset layout size
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
