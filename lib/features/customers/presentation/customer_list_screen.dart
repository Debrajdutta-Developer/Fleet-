import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../domain/customer_entity.dart';
import 'customer_providers.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Accounts'),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync customers',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(customersStreamProvider),
          ),
        ),
        data: (customers) {
          final filtered = customers.where((c) {
            final query = _searchQuery.toLowerCase();
            return c.name.toLowerCase().contains(query) ||
                c.contactName.toLowerCase().contains(query) ||
                c.phone.contains(query) ||
                c.email.toLowerCase().contains(query);
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
                          hintText:
                              'Search by customer name, contact, phone...',
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
                    CustomButton(
                      text: 'Add Customer',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/customers/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Customers Found',
                          description: _searchQuery.isEmpty
                              ? 'Get started by onboarding your first Billed Corporate Customer.'
                              : 'No customers match your search query.',
                          icon: Icons.people_outline_rounded,
                          actionText:
                              _searchQuery.isEmpty ? 'Add Customer' : null,
                          onActionPressed: _searchQuery.isEmpty
                              ? () => context.push('/customers/new')
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
                            final customer = filtered[index];
                            return _CustomerCard(customer: customer);
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

class _CustomerCard extends ConsumerWidget {
  final CustomerEntity customer;

  const _CustomerCard({required this.customer});

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
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Contact: ${customer.contactName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
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
                          context.push('/customers/${customer.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Customer'),
                            content: Text(
                                'Are you sure you want to delete ${customer.name}?'),
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
                              .read(customerListControllerProvider.notifier)
                              .deleteCustomer(customer.id);
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
                Text(customer.phone, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_score_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Limit: \$${customer.creditLimit.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Bal: \$${customer.outstandingBalance.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: (customer.creditLimit > 0 &&
                                customer.outstandingBalance >=
                                    customer.creditLimit)
                            ? Colors.red
                            : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (customer.contacts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${customer.contacts.length} additional contacts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (customer.email.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text(customer.email, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (customer.address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer.address,
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
