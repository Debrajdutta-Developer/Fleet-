import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'dispatch_providers.dart';

class RouteListScreen extends ConsumerWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes Catalog'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/contracts'), // fallback or navigations
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Route Rate'),
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: EmptyStateWidget(
            title: 'Failed to sync routes',
            description: err.toString(),
            icon: Icons.error_outline_rounded,
            actionText: 'Retry',
            onActionPressed: () => ref.invalidate(routesStreamProvider),
          ),
        ),
        data: (routes) {
          if (routes.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                title: 'No routes declared',
                description:
                    'Add point-to-point routes to begin dispatcher routing.',
                icon: Icons.map_outlined,
                actionText: 'Declare First Route',
                onActionPressed: () => context.push('/contracts/new'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.navigation_outlined),
                  ),
                  title: Text(route.name),
                  subtitle: Text(
                    '${route.startLocation} ➔ ${route.endLocation} (${route.distanceKm} km)',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm deletion'),
                          content: const Text(
                              'Are you sure you want to delete this route?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(routeListControllerProvider.notifier)
                            .deleteRoute(route.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
