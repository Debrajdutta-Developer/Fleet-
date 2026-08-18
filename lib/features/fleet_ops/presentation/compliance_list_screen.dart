import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/compliance_entity.dart';
import 'fleet_ops_providers.dart';

class ComplianceListScreen extends ConsumerStatefulWidget {
  const ComplianceListScreen({super.key});

  @override
  ConsumerState<ComplianceListScreen> createState() =>
      _ComplianceListScreenState();
}

class _ComplianceListScreenState extends ConsumerState<ComplianceListScreen> {
  String _searchQuery = '';
  String _docFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final docsAsync = ref.watch(complianceDocumentsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Documents'),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync compliance documents',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () =>
                ref.invalidate(complianceDocumentsStreamProvider),
          ),
        ),
        data: (docs) {
          final filtered = docs.where((d) {
            final matchesType = _docFilter == 'All' ||
                d.documentType.toLowerCase() == _docFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery =
                d.vehicleLicensePlate.toLowerCase().contains(query) ||
                    d.documentNumber.toLowerCase().contains(query);
            return matchesType && matchesQuery;
          }).toList();

          final expiredDocsCount = filtered
              .where((d) => d.expiryDate.isBefore(DateTime.now()))
              .length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top overview card
                Card(
                  color: expiredDocsCount > 0
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          expiredDocsCount > 0
                              ? Icons.error_outline_rounded
                              : Icons.verified_user_rounded,
                          color: expiredDocsCount > 0
                              ? colorScheme.error
                              : colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expiredDocsCount > 0
                                    ? 'Expired compliance warning!'
                                    : 'Statutory compliance is verified',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: expiredDocsCount > 0
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                expiredDocsCount > 0
                                    ? 'You have $expiredDocsCount expired statutory documents across the fleet. Dispatch blocked.'
                                    : 'All fleet vehicles have active, compliant documentation.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: expiredDocsCount > 0
                                      ? colorScheme.onErrorContainer
                                          .withOpacity(0.8)
                                      : colorScheme.onSurfaceVariant
                                          .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by vehicle plate, certificate number...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButtonFormField<String>(
                      value: _docFilter,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxWidth: 160),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['All', 'Insurance', 'PUC', 'Fitness', 'Permit']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _docFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Add Document',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/compliance/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Compliance Documents Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by uploading your first vehicle compliance document.'
                              : 'No compliance records match your search query.',
                          icon: Icons.assignment_turned_in_outlined,
                          actionText:
                              _searchQuery.isEmpty ? 'Add Document' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/compliance/new')
                              : null,
                        )
                      : GridView.builder(
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                isDesktop ? 3 : (screenWidth > 600 ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.4,
                          ),
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            return _ComplianceCard(doc: doc);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComplianceCard extends ConsumerWidget {
  final ComplianceEntity doc;

  const _ComplianceCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat('dd MMM yyyy').format(doc.expiryDate);
    final isExpired = doc.expiryDate.isBefore(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.vehicleLicensePlate,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          doc.documentType.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          context.push('/compliance/${doc.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Compliance Document'),
                            content: const Text(
                                'Are you sure you want to delete this document certificate record?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref
                              .read(complianceListControllerProvider.notifier)
                              .deleteComplianceDocument(doc.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Doc Certificate No.', style: theme.textTheme.labelSmall),
                Text(
                  doc.documentNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: isExpired ? colorScheme.error : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expires: $dateStr',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isExpired ? colorScheme.error : null,
                        fontWeight: isExpired ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
                if (isExpired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'EXPIRED',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
