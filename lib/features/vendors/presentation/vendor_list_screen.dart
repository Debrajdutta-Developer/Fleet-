import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/vendor_entity.dart';
import 'vendor_providers.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  String _searchQuery = '';
  String _typeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Directory'),
      ),
      body: vendorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync vendors',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(vendorsStreamProvider),
          ),
        ),
        data: (vendors) {
          final filtered = vendors.where((v) {
            final matchesType = _typeFilter == 'All' ||
                v.serviceType == _typeFilter.toLowerCase();
            final query = _searchQuery.toLowerCase();
            final matchesQuery = v.name.toLowerCase().contains(query) ||
                v.phone.contains(query) ||
                v.email.toLowerCase().contains(query);
            return matchesType && matchesQuery;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by vendor name, email, phone...',
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
                      value: _typeFilter,
                      decoration: InputDecoration(
                        constraints: const BoxConstraints(maxWidth: 160),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        'All',
                        'Fuel',
                        'Maintenance',
                        'Parts',
                        'Permit',
                        'Miscellaneous'
                      ]
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _typeFilter = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: 'Add Vendor',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/vendors/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Vendors Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by onboarding your first Service/Goods Vendor.'
                              : 'No vendors match your search query.',
                          icon: Icons.business_rounded,
                          actionText:
                              _searchQuery.isEmpty ? 'Add Vendor' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/vendors/new')
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
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, index) {
                            final vendor = filtered[index];
                            return _VendorCard(vendor: vendor);
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

class _VendorCard extends ConsumerWidget {
  final VendorEntity vendor;

  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        vendor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          vendor.serviceType.toUpperCase(),
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
                          context.push('/vendors/${vendor.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Vendor'),
                            content: Text(
                                'Are you sure you want to delete ${vendor.name}?'),
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
                              .read(vendorListControllerProvider.notifier)
                              .deleteVendor(vendor.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 14),
                const SizedBox(width: 6),
                Text(vendor.phone, style: theme.textTheme.bodyMedium),
              ],
            ),
            if (vendor.email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text(vendor.email, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (vendor.address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vendor.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
