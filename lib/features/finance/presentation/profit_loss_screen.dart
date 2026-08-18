import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'finance_providers.dart';

class ProfitLossScreen extends ConsumerWidget {
  const ProfitLossScreen({super.key});

  String _formatCurrency(double amount) {
    final prefix = amount < 0 ? '-\$' : '\$';
    return '$prefix${amount.abs().toStringAsFixed(2)}';
  }

  String _formatCategoryKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plReport = ref.watch(profitLossProvider);
    final summaries = ref.watch(financeSummaryProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 992;

    final Widget reportSummaryCards = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'TOTAL REVENUE (INCOME)',
                value: _formatCurrency(plReport.totalIncome),
                color: Colors.green,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'TOTAL EXPENDITURE',
                value: _formatCurrency(plReport.totalExpense),
                color: Colors.red,
                icon: Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'NET SURPLUS (PROFIT/LOSS)',
                value: _formatCurrency(plReport.netProfit),
                color:
                    plReport.netProfit >= 0 ? colorScheme.primary : Colors.red,
                icon: Icons.account_balance_rounded,
                isLarge: true,
              ),
            ),
          ],
        ),
      ],
    );

    final Widget expenseBreakdownCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenditures by Category Allocation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ...plReport.expensesByCategory.entries.map((entry) {
              final pct = plReport.totalExpense > 0
                  ? (entry.value / plReport.totalExpense)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatCategoryKey(entry.key),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${_formatCurrency(entry.value)} (${(pct * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: entry.value > 0
                                ? Colors.red
                                : colorScheme.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: colorScheme.surfaceVariant,
                      color: Colors.red.withOpacity(0.7),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );

    final Widget summariesCard = DefaultTabController(
      length: 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Performance Summaries',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(text: 'MONTHLY SUMMARIES'),
                  Tab(text: 'YEARLY SUMMARIES'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 380,
                child: TabBarView(
                  children: [
                    // Monthly table
                    _SummaryList(
                      periods: summaries.monthlySummaries,
                      formatCurrency: _formatCurrency,
                    ),
                    // Yearly table
                    _SummaryList(
                      periods: summaries.yearlySummaries,
                      formatCurrency: _formatCurrency,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profit & Loss Statements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                reportSummaryCards,
                const SizedBox(height: 24),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: expenseBreakdownCard),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: summariesCard),
                        ],
                      )
                    : Column(
                        children: [
                          expenseBreakdownCard,
                          const SizedBox(height: 24),
                          summariesCard,
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isLarge;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isLarge ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 24.0 : 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 28 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: isLarge ? 28 : 20,
              backgroundColor: color.withOpacity(0.08),
              child: Icon(icon, color: color, size: isLarge ? 28 : 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  final List<SummaryPeriod> periods;
  final String Function(double) formatCurrency;

  const _SummaryList({required this.periods, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (periods.isEmpty) {
      return Center(
        child: Text(
          'No historical records captured yet.',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
        ),
      );
    }

    return ListView.separated(
      itemCount: periods.length,
      separatorBuilder: (c, i) => const Divider(),
      itemBuilder: (context, index) {
        final period = periods[index];
        final isProfit = period.profit >= 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  period.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.green,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatCurrency(period.income),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatCurrency(period.expense),
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Net: ${formatCurrency(period.profit)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isProfit ? colorScheme.primary : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
