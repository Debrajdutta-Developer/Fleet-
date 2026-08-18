import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../notifications_providers.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'vehicles':
        return Icons.local_shipping_rounded;
      case 'drivers':
        return Icons.person_rounded;
      case 'inventory':
        return Icons.inventory_2_rounded;
      case 'trips':
        return Icons.explore_rounded;
      case 'billing':
        return Icons.receipt_long_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = ref.watch(filteredNotificationsProvider);
    final search = ref.watch(notificationSearchQueryProvider);
    final categoryFilter = ref.watch(notificationCategoryFilterProvider);
    final priorityFilter = ref.watch(notificationPriorityFilterProvider);
    final evalState = ref.watch(alertEvaluationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/notifications/settings'),
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar/Controls row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notifications...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(notificationSearchQueryProvider.notifier).state =
                          val;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButtonFormField<String>(
                  value: categoryFilter,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    constraints: const BoxConstraints(maxWidth: 150),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                        value: 'vehicles', child: Text('Vehicles')),
                    DropdownMenuItem(value: 'drivers', child: Text('Drivers')),
                    DropdownMenuItem(
                        value: 'inventory', child: Text('Inventory')),
                    DropdownMenuItem(value: 'trips', child: Text('Trips')),
                    DropdownMenuItem(value: 'billing', child: Text('Billing')),
                    DropdownMenuItem(value: 'finance', child: Text('Finance')),
                    DropdownMenuItem(value: 'general', child: Text('General')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(notificationCategoryFilterProvider.notifier)
                          .state = val;
                    }
                  },
                ),
                const SizedBox(width: 16),
                DropdownButtonFormField<String>(
                  value: priorityFilter,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    constraints: const BoxConstraints(maxWidth: 150),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(notificationPriorityFilterProvider.notifier)
                          .state = val;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Actions panel (Mark all as read & Evaluate rules)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomButton(
                      text: 'Mark All Read',
                      icon: Icons.done_all_rounded,
                      onPressed: () async {
                        await ref
                            .read(notificationFormControllerProvider.notifier)
                            .markAllNotificationsAsRead();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('All notifications marked as read.')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: evalState.isEvaluating
                          ? 'Evaluating...'
                          : 'Evaluate Rules',
                      icon: Icons.insights_rounded,
                      onPressed: evalState.isEvaluating
                          ? null
                          : () async {
                              final count = await ref
                                  .read(alertEvaluationControllerProvider
                                      .notifier)
                                  .evaluateAllRules();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Evaluation finished: $count new alerts generated.'),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
                if (evalState.lastEvaluationTime != null)
                  Text(
                    'Last Eval: ${evalState.lastEvaluationTime!.toLocal().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // List of notifications
            Expanded(
              child: filteredNotifications.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Notifications',
                      description: search.isEmpty
                          ? 'All clear! No alerts match your configuration.'
                          : 'No notifications match your search query.',
                      icon: Icons.notifications_none_rounded,
                    )
                  : ListView.builder(
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final n = filteredNotifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: n.isRead ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: n.isRead
                                  ? Colors.grey.shade300
                                  : _getPriorityColor(n.priority)
                                      .withOpacity(0.3),
                              width: n.isRead ? 1 : 2,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getPriorityColor(n.priority)
                                  .withOpacity(0.1),
                              child: Icon(
                                _getCategoryIcon(n.category),
                                color: _getPriorityColor(n.priority),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(n.priority)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    n.priority.toUpperCase(),
                                    style: TextStyle(
                                      color: _getPriorityColor(n.priority),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(n.message),
                                const SizedBox(height: 6),
                                Text(
                                  n.createdAt
                                      .toLocal()
                                      .toString()
                                      .split('.')[0],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!n.isRead)
                                  IconButton(
                                    icon: const Icon(Icons.done_rounded),
                                    onPressed: () => ref
                                        .read(notificationFormControllerProvider
                                            .notifier)
                                        .markAsRead(n),
                                    tooltip: 'Mark as read',
                                  ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                  onPressed: () => ref
                                      .read(notificationFormControllerProvider
                                          .notifier)
                                      .dismissNotification(n.id, n.title),
                                  tooltip: 'Dismiss',
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!n.isRead) {
                                ref
                                    .read(notificationFormControllerProvider
                                        .notifier)
                                    .markAsRead(n);
                              }
                              // View details or navigate
                              context.push('/notifications/alert-details',
                                  extra: n);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
