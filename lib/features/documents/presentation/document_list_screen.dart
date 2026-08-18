import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'document_providers.dart';
import '../domain/document_entity.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key});

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      ref.read(documentSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getFriendlyTypeName(String type) {
    switch (type) {
      case 'gst_certificate':
        return 'GST Certificate';
      case 'pan':
        return 'PAN Card';
      case 'trade_license':
        return 'Trade License';
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

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'company':
        return Icons.business_rounded;
      case 'vehicle':
        return Icons.local_shipping_rounded;
      case 'driver':
        return Icons.badge_rounded;
      case 'customer':
        return Icons.people_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final allDocs = ref.watch(documentsStreamProvider).valueOrNull ?? [];
    final filteredDocs = ref.watch(filteredDocumentsProvider);
    final selectedCategory = ref.watch(selectedDocumentCategoryProvider);
    final selectedType = ref.watch(selectedDocumentTypeProvider);
    final showDeleted = ref.watch(showDeletedDocumentsProvider);
    final sort = ref.watch(documentSortOptionProvider);

    // Compute Expiry Metrics
    final now = DateTime.now();
    final expiredDocs = allDocs
        .where((doc) =>
            doc.deletedAt == null &&
            doc.expiryDate != null &&
            doc.expiryDate!.isBefore(now))
        .toList();
    final expiringSoonDocs = allDocs.where((doc) {
      if (doc.deletedAt != null || doc.expiryDate == null) return false;
      final diff = doc.expiryDate!.difference(now).inDays;
      return diff >= 0 && diff <= 30;
    }).toList();

    // Sort active documents by upload date to get recently uploaded list
    final activeDocs = allDocs.where((doc) => doc.deletedAt == null).toList();
    activeDocs.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    final recentlyUploaded = activeDocs.take(5).toList();

    // Pending verification list
    final pendingDocs = allDocs
        .where((doc) =>
            doc.deletedAt == null && doc.status == 'pending_verification')
        .toList();

    // Determine layout width for responsiveness
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1024;
    final isTablet = width > 640 && width <= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Document Vault'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined),
              text: 'All Vault Documents (${activeDocs.length})',
            ),
            Tab(
              icon: const Icon(Icons.warning_amber_rounded),
              text:
                  'Vault Expirations (${expiredDocs.length + expiringSoonDocs.length})',
            ),
            Tab(
              icon: const Icon(Icons.rate_review_outlined),
              text: 'Approval Inbox (${pendingDocs.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Dashboard Metrics Panel
          _buildDashboardMetricsPanel(
              context,
              activeDocs.length,
              expiringSoonDocs.length,
              expiredDocs.length,
              recentlyUploaded,
              colorScheme,
              theme,
              isDesktop),

          // 2. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllDocumentsTab(
                    context,
                    filteredDocs,
                    selectedCategory,
                    selectedType,
                    showDeleted,
                    sort,
                    colorScheme,
                    theme,
                    isDesktop,
                    isTablet),
                _buildExpirationsTab(
                    context, expiringSoonDocs, expiredDocs, colorScheme, theme),
                _buildApprovalInboxTab(
                    context, pendingDocs, colorScheme, theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload Document'),
        onPressed: () => context.push('/documents/new'),
      ),
    );
  }

  // --- DASHBOARD METRICS PANEL ---
  Widget _buildDashboardMetricsPanel(
    BuildContext context,
    int totalCount,
    int expiringCount,
    int expiredCount,
    List<DocumentEntity> recentlyUploaded,
    ColorScheme colorScheme,
    ThemeData theme,
    bool isDesktop,
  ) {
    final cardPadding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

    return Container(
      color: colorScheme.surfaceVariant.withOpacity(0.12),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metric Card 1: Total
              Expanded(
                child: Card(
                  elevation: 0,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Documents',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text('$totalCount',
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Metric Card 2: Expiring Soon
              Expanded(
                child: Card(
                  elevation: 0,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expiring Soon (30d)',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('$expiringCount',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange)),
                            const SizedBox(width: 8),
                            if (expiringCount > 0)
                              const Tooltip(
                                message:
                                    'Compliance alert prepared for Reminder engine.',
                                child: Icon(Icons.notifications_active_outlined,
                                    color: Colors.orange, size: 18),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Metric Card 3: Expired
              Expanded(
                child: Card(
                  elevation: 0,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: colorScheme.outline.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expired Documents',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('$expiredCount',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800)),
                            const SizedBox(width: 8),
                            if (expiredCount > 0)
                              const Tooltip(
                                message: 'Warning alert triggered.',
                                child: Icon(Icons.error_outline_rounded,
                                    color: Colors.red, size: 18),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Desktop: Show Recently Uploaded panel inline
              if (isDesktop) ...[
                const SizedBox(width: 16),
                Container(
                  width: 320,
                  height: 90,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.outline.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recently Uploaded',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentlyUploaded.length,
                          itemBuilder: (ctx, idx) {
                            final doc = recentlyUploaded[idx];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                avatar: Icon(_getCategoryIcon(doc.category),
                                    size: 14),
                                label: Text(doc.fileName,
                                    style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // --- ALL DOCUMENTS TAB ---
  Widget _buildAllDocumentsTab(
    BuildContext context,
    List<DocumentEntity> list,
    String category,
    String type,
    bool showDeleted,
    String sort,
    ColorScheme colorScheme,
    ThemeData theme,
    bool isDesktop,
    bool isTablet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              // Filters & Search Toolbar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search Bar
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by file name or code...',
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    // Category dropdown
                    DropdownButton<String>(
                      value: category,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Categories')),
                        DropdownMenuItem(
                            value: 'company', child: Text('Company Docs')),
                        DropdownMenuItem(
                            value: 'vehicle', child: Text('Vehicle Docs')),
                        DropdownMenuItem(
                            value: 'driver', child: Text('Driver Docs')),
                        DropdownMenuItem(
                            value: 'customer', child: Text('Customer Docs')),
                        DropdownMenuItem(
                            value: 'finance', child: Text('Finance Docs')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(selectedDocumentCategoryProvider.notifier)
                              .state = val;
                          ref
                              .read(selectedDocumentTypeProvider.notifier)
                              .state = 'all'; // reset type filter
                        }
                      },
                    ),

                    // Sort dropdown
                    DropdownButton<String>(
                      value: sort,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'date_uploaded_desc',
                            child: Text('Date Uploaded (Newest)')),
                        DropdownMenuItem(
                            value: 'name_asc', child: Text('File Name (A-Z)')),
                        DropdownMenuItem(
                            value: 'name_desc', child: Text('File Name (Z-A)')),
                        DropdownMenuItem(
                            value: 'expiry_asc',
                            child: Text('Expiry (Expiring First)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(documentSortOptionProvider.notifier).state =
                              val;
                        }
                      },
                    ),

                    // Show soft-deleted toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: showDeleted,
                          onChanged: (val) {
                            if (val != null) {
                              ref
                                  .read(showDeletedDocumentsProvider.notifier)
                                  .state = val;
                            }
                          },
                        ),
                        Text('Show Soft Deleted Vault',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),

              // Grid list
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(showDeleted
                            ? 'No soft-deleted vault items.'
                            : 'No documents matching criteria.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 220,
                        ),
                        itemCount: list.length,
                        itemBuilder: (ctx, idx) {
                          final doc = list[idx];
                          return _buildDocumentCard(
                              context, doc, colorScheme, theme);
                        },
                      ),
              ),
            ],
          ),
        ),

        // Desktop visual Drag & Drop simulation panel
        if (isDesktop) ...[
          Container(
            width: 240,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                  left:
                      BorderSide(color: colorScheme.outline.withOpacity(0.15))),
              color: colorScheme.surfaceVariant.withOpacity(0.05),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drive_folder_upload,
                      size: 64, color: colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Drag & Drop Files Here',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quickly drop PDF, Image, or spreadsheet files to start uploading to the vault.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/documents/new'),
                    child: const Text('Pick Files'),
                  ),
                ],
              ),
            ),
          )
        ]
      ],
    );
  }

  // --- EXSPIRATIONS TAB ---
  Widget _buildExpirationsTab(
    BuildContext context,
    List<DocumentEntity> expiring,
    List<DocumentEntity> expired,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final list = [...expired, ...expiring];

    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Compliance verified. Zero document expiration alerts!'),
          ],
        ),
      );
    }

    final now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, idx) {
        final doc = list[idx];
        final days =
            doc.expiryDate != null ? doc.expiryDate!.difference(now).inDays : 0;
        final isExpired = days < 0;

        return ListTile(
          leading: Icon(
            isExpired ? Icons.cancel : Icons.warning_amber_rounded,
            color: isExpired ? Colors.red.shade800 : Colors.orange,
            size: 32,
          ),
          title: Text(doc.fileName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${_getFriendlyTypeName(doc.type)} | Scope: ${doc.relatedEntityType?.toUpperCase() ?? "Company"}'),
              Text(
                isExpired
                    ? 'EXPIRED'
                    : 'Expiring in $days days (${DateFormat('yMMMd').format(doc.expiryDate!)})',
                style: TextStyle(
                  color: isExpired ? Colors.red.shade800 : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: OutlinedButton(
            onPressed: () => context.push('/documents/${doc.id}'),
            child: const Text('Resolve'),
          ),
        );
      },
    );
  }

  // --- APPROVAL INBOX TAB ---
  Widget _buildApprovalInboxTab(
    BuildContext context,
    List<DocumentEntity> list,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Inbox empty. No documents pending compliance verification.'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (ctx, idx) {
        final doc = list[idx];

        return ListTile(
          leading: const Icon(Icons.rate_review_outlined,
              color: Colors.orange, size: 32),
          title: Text(doc.fileName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            'Type: ${_getFriendlyTypeName(doc.type)} | Scope: ${doc.relatedEntityType?.toUpperCase() ?? "Company"} | Ref: ${doc.documentNumber}',
          ),
          trailing: ElevatedButton(
            onPressed: () => context.push('/documents/${doc.id}'),
            child: const Text('Review'),
          ),
        );
      },
    );
  }

  // --- CARD BUILDER ---
  Widget _buildDocumentCard(
    BuildContext context,
    DocumentEntity doc,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final statusColor = _getStatusColor(doc.status, colorScheme);
    final sizeKb = (doc.fileSize / 1024).toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/documents/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(_getCategoryIcon(doc.category),
                      color: colorScheme.primary, size: 28),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
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
                ],
              ),
              const Spacer(),
              Text(
                doc.fileName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Type: ${_getFriendlyTypeName(doc.type)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
              ),
              Text(
                'Size: $sizeKb KB | Reference: ${doc.documentNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
              ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc.entityName ?? 'Company Level',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: colorScheme.primary),
                  ),
                  Text(
                    doc.expiryDate == null
                        ? 'No Expiry'
                        : 'Expires: ${DateFormat('MM/dd/yy').format(doc.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: doc.expiryDate != null &&
                              doc.expiryDate!.isBefore(DateTime.now())
                          ? Colors.red.shade800
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: doc.expiryDate != null &&
                              doc.expiryDate!.isBefore(DateTime.now())
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
