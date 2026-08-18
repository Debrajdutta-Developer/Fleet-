import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'document_providers.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _getFriendlyTypeName(String type) {
    switch (type) {
      case 'gst_certificate':
        return 'GST Certificate';
      case 'pan':
        return 'PAN Card';
      case 'trade_license':
        return 'Trade License / Registration';
      case 'company_logo':
        return 'Company Logo';
      case 'rc':
        return 'Registration Certificate (RC)';
      case 'insurance':
        return 'Insurance Policy';
      case 'fitness':
        return 'Fitness Certificate';
      case 'puc':
        return 'Pollution Certificate (PUC)';
      case 'permit':
        return 'National/State Permit';
      case 'road_tax':
        return 'Road Tax receipt';
      case 'driving_license':
        return 'Driving License (DL)';
      case 'national_id':
        return 'Aadhaar / National ID';
      case 'medical_certificate':
        return 'Medical Certificate';
      case 'training_certificate':
        return 'Training Certificate';
      case 'contract':
        return 'signed Contract';
      case 'agreement':
        return 'SLA / Agreement';
      case 'purchase_order':
        return 'Purchase Order (PO)';
      case 'kyc_document':
        return 'KYC Document';
      case 'invoice':
        return 'Finance Invoice';
      case 'receipt':
        return 'Receipt Log';
      case 'expense_bill':
        return 'Expense Bill';
      case 'payment_proof':
        return 'Payment Proof';
      default:
        return 'Other Document';
    }
  }

  Color _getStatusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending_verification':
        return Colors.orange;
      case 'rejected':
        return scheme.error;
      case 'expired':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleVerification(String status) async {
    final note = _noteController.text.trim();
    final success = await ref
        .read(documentFormControllerProvider.notifier)
        .verifyDocument(
            widget.documentId, status, note.isNotEmpty ? note : null);

    if (success && mounted) {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Document status updated to ${status.replaceAll('_', ' ')}.')),
      );
    }
  }

  Future<void> _handleRename(String currentName) async {
    final renameController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(
              labelText: 'Display Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(renameController.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      final success = await ref
          .read(documentFormControllerProvider.notifier)
          .renameDocument(widget.documentId, newName);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document successfully renamed.')),
        );
      }
    }
  }

  Future<void> _handleReplace() async {
    // Simulate selecting a replacement file
    final mockBytes = Uint8List.fromList(List.generate(100, (i) => i));
    final originalName = 'replaced_contract_${math.Random().nextInt(99)}.pdf';

    final success = await ref
        .read(documentFormControllerProvider.notifier)
        .replaceDocumentFile(
          widget.documentId,
          fileBytes: mockBytes,
          originalFileName: originalName,
          mimeType: 'application/pdf',
          fileSize: 1200000, // 1.2MB
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vault document file successfully replaced.')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Document'),
        content: const Text(
            'Are you sure you want to soft-delete this document? It can be restored later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Soft Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(documentFormControllerProvider.notifier)
          .deleteDocument(widget.documentId);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  Future<void> _handleRestore() async {
    final success = await ref
        .read(documentFormControllerProvider.notifier)
        .restoreDocument(widget.documentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document restored to active vault.')),
      );
    }
  }

  Future<void> _handleDownload() async {
    // Trigger download simulation and log download audit trail
    await ref
        .read(documentFormControllerProvider.notifier)
        .simulateDownload(widget.documentId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Simulated file download initiated (audit log registered).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final documents = ref.watch(documentsStreamProvider).valueOrNull ?? [];
    final docList = documents.where((d) => d.id == widget.documentId).toList();

    if (docList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Vault Detail')),
        body: const Center(
            child: Text('Document record not found in company vault.')),
      );
    }

    final doc = docList.first;
    final statusColor = _getStatusColor(doc.status, colorScheme);
    final isDeleted = doc.deletedAt != null;
    final sizeKb = (doc.fileSize / 1024).toStringAsFixed(1);

    // Filter audits matching this document ID
    // We mock this using state dates for visual verification
    final formState = ref.watch(documentFormControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'Rename Display Name',
            onPressed: () => _handleRename(doc.fileName),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Replace File Attachment',
            onPressed: _handleReplace,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download Original File',
            onPressed: _handleDownload,
          ),
          if (isDeleted)
            IconButton(
              icon: const Icon(Icons.restore_from_trash_outlined,
                  color: Colors.green),
              tooltip: 'Restore Document',
              onPressed: _handleRestore,
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Soft Delete Document',
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: File Visual preview inspector
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Inspector container
                  Container(
                    height: 520,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: colorScheme.outline.withOpacity(0.15)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            doc.mimeType == 'application/pdf'
                                ? Icons.picture_as_pdf
                                : (doc.mimeType.startsWith('image')
                                    ? Icons.image
                                    : Icons.table_view_outlined),
                            size: 80,
                            color: colorScheme.primary.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            doc.originalFileName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Size: $sizeKb KB | Format: ${doc.mimeType.toUpperCase()}',
                            style: TextStyle(
                                color:
                                    colorScheme.onBackground.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Visual Attachment Preview Inspector View',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Metadata, Audits, Verification controls
          Container(
            width: 380,
            decoration: BoxDecoration(
              border: Border(
                  left:
                      BorderSide(color: colorScheme.outline.withOpacity(0.2))),
              color: colorScheme.surfaceVariant.withOpacity(0.15),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fileName,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          doc.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (isDeleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: const Text(
                            'SOFT DELETED',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const Divider(height: 32),

                  // Metadata properties
                  _buildProperty(
                      context, 'Category', doc.category.toUpperCase()),
                  _buildProperty(
                      context, 'Document Type', _getFriendlyTypeName(doc.type)),
                  _buildProperty(
                      context, 'Reference ID / Number', doc.documentNumber),
                  _buildProperty(context, 'Mapping Scope',
                      doc.entityName ?? 'Company Level'),
                  _buildProperty(context, 'Mime Type', doc.mimeType),
                  _buildProperty(context, 'Storage Path', doc.storagePath),
                  _buildProperty(
                    context,
                    'Expiry Date',
                    doc.expiryDate != null
                        ? DateFormat('yMMMMd').format(doc.expiryDate!)
                        : 'No expiration',
                  ),
                  if (doc.notes != null && doc.notes!.isNotEmpty)
                    _buildProperty(context, 'Notes', doc.notes!),

                  const Divider(height: 32),

                  // Verification Controls (if not soft deleted)
                  if (!isDeleted) ...[
                    Text(
                      'COMPLIANCE MANAGEMENT',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Verification note / reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Reject'),
                            onPressed: formState.isLoading
                                ? null
                                : () => _handleVerification('rejected'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Approve'),
                            onPressed: formState.isLoading
                                ? null
                                : () => _handleVerification('verified'),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                  ],

                  // Audit Trail Timeline
                  Text(
                    'AUDIT TIMELINE LOGS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (doc.deletedAt != null)
                    _buildTimelineItem(
                      title: 'Document Soft Deleted',
                      subtitle: 'Removed from active search vault.',
                      time: DateFormat('MM/dd/yy HH:mm').format(doc.deletedAt!),
                      color: Colors.red,
                      isLast: false,
                    ),
                  _buildTimelineItem(
                    title: 'Verification Status Updated',
                    subtitle: doc.status == 'pending_verification'
                        ? 'Pending manager review.'
                        : 'Marked ${doc.status.toUpperCase()} by ${doc.verifiedBy ?? "system"}.',
                    time: doc.verifiedAt != null
                        ? DateFormat('MM/dd/yy HH:mm').format(doc.verifiedAt!)
                        : 'N/A',
                    color: statusColor,
                    isLast: false,
                  ),
                  _buildTimelineItem(
                    title: 'Document Uploaded & Saved',
                    subtitle: 'Metadata registered by ${doc.uploadedBy}.',
                    time: DateFormat('MM/dd/yy HH:mm').format(doc.uploadDate),
                    color: colorScheme.primary,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProperty(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
