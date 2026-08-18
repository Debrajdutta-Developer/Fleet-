import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/notification_entity.dart';
import '../notifications_providers.dart';

class AlertDetailsScreen extends ConsumerWidget {
  final NotificationEntity notification;

  const AlertDetailsScreen({
    super.key,
    required this.notification,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header category + priority badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    _getPriorityColor(notification.priority)
                                        .withOpacity(0.1),
                                child: Icon(
                                  _getCategoryIcon(notification.category),
                                  color:
                                      _getPriorityColor(notification.priority),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                notification.category.toUpperCase(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(notification.priority)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notification.priority.toUpperCase(),
                              style: TextStyle(
                                color: _getPriorityColor(notification.priority),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Title
                      Text(
                        notification.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message / Description
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),

                      // Expiry/Metadata details
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Generated At:',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(notification.createdAt
                                    .toLocal()
                                    .toString()
                                    .split('.')[0]),
                              ),
                            ],
                          ),
                          if (notification.relatedEntityId != null)
                            TableRow(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('Related Asset:',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                      '${notification.relatedEntityType?.toUpperCase()}: ${notification.relatedEntityId}'),
                                ),
                              ],
                            ),
                          TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Status:',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                    notification.isRead ? 'Read' : 'Unread'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Action button row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomButton(
                            text: 'Dismiss Alert',
                            icon: Icons.delete_outline_rounded,
                            onPressed: () async {
                              await ref
                                  .read(notificationFormControllerProvider
                                      .notifier)
                                  .dismissNotification(
                                      notification.id, notification.title);
                              if (context.mounted) {
                                context.pop();
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          if (notification.actionUrl != null)
                            CustomButton(
                              text: 'Investigate',
                              icon: Icons.search_rounded,
                              onPressed: () {
                                context.push(notification.actionUrl!);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
