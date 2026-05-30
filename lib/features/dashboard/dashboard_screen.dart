import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/status.dart';
import '../../ui/widgets/empty_state.dart';
import '../notes/notes_store.dart';
import '../tasks/tasks_screen_embedded.dart';
import '../tasks/tasks_store.dart';
import '../wishlist/wishlist_store.dart';
import 'dashboard_store.dart';
import '../../services/analytics_pdf_exporter.dart';
import '../../core/settings/settings_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DashboardStore>();
    final settings = context.watch<SettingsStore>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Dashboard'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) async {
                switch (value) {
                  case 'export':
                    await AnalyticsPdfExporter.export(
                      context,
                      wishlist: context
                          .read<WishlistStore>()
                          .allItems
                          .toList(growable: false),
                      tasks: context.read<TasksStore>().tasks.toList(growable: false),
                      notes: context.read<NotesStore>().notes.toList(growable: false),
                      dashboard: store,
                    );
                    break;
                  case 'theme':
                    settings.toggleLightDark();
                    break;
                  case 'refresh':
                    // Stores recompute automatically via proxy provider; this is a noop UI affordance.
                    // Keeping it for UX: users expect a refresh action.
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Export analytics (PDF)'),
                  ),
                ),
                PopupMenuItem(
                  value: 'theme',
                  child: ListTile(
                    leading: Icon(
                      settings.themeMode == ThemeMode.light
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: Text(
                      settings.themeMode == ThemeMode.light ? 'Switch to dark' : 'Switch to light',
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: ListTile(
                    leading: Icon(Icons.refresh),
                    title: Text('Refresh stats'),
                  ),
                ),
              ],
            )
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _SectionTitle(title: 'Status analytics'),
              const SizedBox(height: 12),
              if (store.wishlist.total + store.tasks.total == 0)
                const EmptyState(
                  title: 'Nothing to analyze yet',
                  subtitle: 'Add wishlist items, notes, or tasks to start tracking progress.',
                )
              else
                _AnalyticsCards(store: store),
              const SizedBox(height: 20),
              _SectionTitle(title: 'Weekly progress'),
              const SizedBox(height: 12),
              _WeeklyBar(values: store.weeklyCompleted.toList(growable: false)),
              const SizedBox(height: 20),
              _SectionTitle(title: 'Daily tasks'),
              const SizedBox(height: 12),
              const TasksScreenEmbedded(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _AnalyticsCards extends StatelessWidget {
  const _AnalyticsCards({required this.store});
  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PieCard(
          title: 'Wishlist',
          counts: store.wishlist.toMap(),
        ),
        const SizedBox(height: 12),
        _PieCard(
          title: 'Tasks',
          counts: store.tasks.toMap(),
        ),
        const SizedBox(height: 12),
        _CompletionCard(
          wishlistRate: store.wishlist.completionRate,
          tasksRate: store.tasks.completionRate,
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.wishlistRate, required this.tasksRate});
  final double wishlistRate;
  final double tasksRate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _Rate(
                label: 'Wishlist completion',
                value: wishlistRate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Rate(
                label: 'Tasks completion',
                value: tasksRate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.isNaN ? 0 : value,
            minHeight: 10,
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 8),
        Text('$percent%', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _PieCard extends StatelessWidget {
  const _PieCard({required this.title, required this.counts});
  final String title;
  final Map<ItemStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final sections = <PieChartSectionData>[];

    if (total == 0) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: '',
          radius: 18,
          color: Colors.white12,
        ),
      );
    } else {
      for (final entry in counts.entries) {
        if (entry.value == 0) continue;
        sections.add(
          PieChartSectionData(
            value: entry.value.toDouble(),
            title: '',
            radius: 18,
            color: _statusColor(entry.key),
          ),
        );
      }
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 128,
                height: 128,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 18,
                    sections: sections,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Legend(counts: counts),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ItemStatus s) => switch (s) {
        ItemStatus.completed => const Color(0xFF2ED47A),
        ItemStatus.onTheWay => const Color(0xFFFFC542),
        ItemStatus.notCompleted => const Color(0xFFFF4D4D),
        ItemStatus.pending => const Color(0xFF8A8FFF),
      };
}

class _Legend extends StatelessWidget {
  const _Legend({required this.counts});
  final Map<ItemStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    Widget row(ItemStatus s, String label) {
      final color = switch (s) {
        ItemStatus.completed => const Color(0xFF2ED47A),
        ItemStatus.onTheWay => const Color(0xFFFFC542),
        ItemStatus.notCompleted => const Color(0xFFFF4D4D),
        ItemStatus.pending => const Color(0xFF8A8FFF),
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Text('${counts[s] ?? 0}',
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        row(ItemStatus.pending, 'Pending'),
        row(ItemStatus.onTheWay, 'On the way'),
        row(ItemStatus.completed, 'Completed'),
        row(ItemStatus.notCompleted, 'Not completed'),
      ],
    );
  }
}

class _WeeklyBar extends StatelessWidget {
  const _WeeklyBar({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxY = (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b))
        .toDouble();
    final now = DateTime.now();
    DateTime dayForIndex(int i) =>
        DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= values.length) {
                        return const SizedBox.shrink();
                      }
                      final d = dayForIndex(i);
                      final label = '${d.month}/${d.day}';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final d = dayForIndex(group.x);
                    final label = '${d.month}/${d.day}';
                    return BarTooltipItem(
                      '$label\n',
                      Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()} completed',
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: List.generate(values.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i].toDouble(),
                      width: 12,
                      borderRadius: BorderRadius.circular(6),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              }),
              minY: 0,
              maxY: (maxY <= 0) ? 1 : (maxY + 1),
            ),
          ),
        ),
      ),
    );
  }
}

