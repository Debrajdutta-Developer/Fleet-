import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/notification_preferences_entity.dart';
import '../notifications_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _quietHoursEnabled = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '06:00';
  String _minPriorityFilter = 'low';
  final List<String> _enabledCategories = [];

  bool _initialized = false;

  final List<String> _allCategories = [
    'vehicles',
    'drivers',
    'inventory',
    'trips',
    'billing',
    'finance',
    'general'
  ];

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Failed to load settings: $err')),
        data: (prefs) {
          if (!_initialized) {
            _quietHoursEnabled = prefs.quietHoursEnabled;
            _quietHoursStart = prefs.quietHoursStart;
            _quietHoursEnd = prefs.quietHoursEnd;
            _minPriorityFilter = prefs.minPriorityFilter;
            _enabledCategories.addAll(prefs.enabledCategories);
            _initialized = true;
          }

          final theme = Theme.of(context);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferences & Delivery Rules',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure quiet hours, filter by priority levels, or disable notifications for specific modules.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const Divider(height: 32),

                          // 1. Min Priority
                          Text(
                            'Minimum Priority Level',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _minPriorityFilter,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(
                                  value: 'low', child: Text('Low and Above')),
                              DropdownMenuItem(
                                  value: 'medium',
                                  child: Text('Medium and Above')),
                              DropdownMenuItem(
                                  value: 'high', child: Text('High and Above')),
                              DropdownMenuItem(
                                  value: 'critical',
                                  child: Text('Critical Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _minPriorityFilter = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // 2. Enabled Categories
                          Text(
                            'Enabled Categories',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: _allCategories.map((cat) {
                              return CheckboxListTile(
                                title: Text(cat.toUpperCase()),
                                value: _enabledCategories.contains(cat),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _enabledCategories.add(cat);
                                    } else {
                                      _enabledCategories.remove(cat);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // 3. Quiet Hours Toggles
                          SwitchListTile(
                            title: const Text('Enable Quiet Hours'),
                            subtitle: const Text(
                                'Silences non-critical alerts during selected hours.'),
                            value: _quietHoursEnabled,
                            onChanged: (val) {
                              setState(() {
                                _quietHoursEnabled = val;
                              });
                            },
                          ),
                          if (_quietHoursEnabled) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ListTile(
                                    title: const Text('Start Time'),
                                    subtitle: Text(_quietHoursStart),
                                    trailing:
                                        const Icon(Icons.access_time_rounded),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay(
                                          hour: int.parse(
                                              _quietHoursStart.split(':')[0]),
                                          minute: int.parse(
                                              _quietHoursStart.split(':')[1]),
                                        ),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _quietHoursStart =
                                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: const Text('End Time'),
                                    subtitle: Text(_quietHoursEnd),
                                    trailing:
                                        const Icon(Icons.access_time_rounded),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay(
                                          hour: int.parse(
                                              _quietHoursEnd.split(':')[0]),
                                          minute: int.parse(
                                              _quietHoursEnd.split(':')[1]),
                                        ),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _quietHoursEnd =
                                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 32),

                          // Save actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => context.pop(),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              CustomButton(
                                text: 'Save Preferences',
                                icon: Icons.save_rounded,
                                onPressed: () async {
                                  final newPrefs =
                                      NotificationPreferencesEntity(
                                    companyId: prefs.companyId,
                                    enabledCategories: _enabledCategories,
                                    quietHoursEnabled: _quietHoursEnabled,
                                    quietHoursStart: _quietHoursStart,
                                    quietHoursEnd: _quietHoursEnd,
                                    minPriorityFilter: _minPriorityFilter,
                                  );

                                  await ref
                                      .read(notificationFormControllerProvider
                                          .notifier)
                                      .savePreferences(newPrefs);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Preferences saved successfully.')),
                                    );
                                    context.pop();
                                  }
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
          );
        },
      ),
    );
  }
}
