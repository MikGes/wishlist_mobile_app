import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/wishlist_item.dart';
import '../../domain/status.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import 'wishlist_store.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WishlistStore>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Wishlist'),
          actions: [
            IconButton(
              tooltip: 'Filters',
              onPressed: () => _openFilters(context),
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              tooltip: 'Add item',
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverToBoxAdapter(
            child: _ActiveFilters(store: store),
          ),
        ),
        if (store.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (store.items.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              title: 'Your wishlist is empty',
              subtitle: 'Add items with a scheduled date. You’ll get a reminder on that day.',
              action: FilledButton.icon(
                onPressed: () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: store.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _WishlistCard(item: store.items[i]),
          ),
      ],
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateWishlistSheet(),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => const _FiltersSheet(),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.store});
  final WishlistStore store;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (store.filterStatus != null) {
      chips.add(
        InputChip(
          label: Text('Status: ${_label(store.filterStatus!)}'),
          onDeleted: () {
            store.setFilters(status: null, date: store.filterDate);
          },
        ),
      );
    }
    if (store.filterDate != null) {
      final fmt = DateFormat('MMM d, yyyy');
      chips.add(
        InputChip(
          label: Text('Date: ${fmt.format(store.filterDate!)}'),
          onDeleted: () {
            store.setFilters(status: store.filterStatus, date: null);
          },
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  String _label(ItemStatus s) => switch (s) {
        ItemStatus.pending => 'Pending',
        ItemStatus.onTheWay => 'On the way',
        ItemStatus.completed => 'Completed',
        ItemStatus.notCompleted => 'Not completed',
      };
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({required this.item});
  final WishlistItem item;

  @override
  Widget build(BuildContext context) {
    final store = context.read<WishlistStore>();
    final fmt = DateFormat('EEE, MMM d');
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled: ${fmt.format(item.scheduledDate)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (item.description != null) ...[
              const SizedBox(height: 10),
              Text(item.description!),
            ],
            if (item.status == ItemStatus.notCompleted &&
                (item.notCompletedReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              Text(
                'Reason: ${item.notCompletedReason}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final s = await _pickStatus(context, item.status);
                    if (!context.mounted) return;
                    if (s == null) return;
                    try {
                      if (s == ItemStatus.notCompleted) {
                        final reason = await _askReason(context);
                        if (!context.mounted) return;
                        if (reason == null) return;
                        await store.updateStatus(item, s, notCompletedReason: reason);
                      } else {
                        await store.updateStatus(item, s);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Status'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete item?'),
                        content: Text('Delete "${item.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await store.delete(item);
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<ItemStatus?> _pickStatus(BuildContext context, ItemStatus current) {
    return showModalBottomSheet<ItemStatus>(
      context: context,
      builder: (_) {
        Widget tile(ItemStatus s, String label) => ListTile(
              title: Text(label),
              trailing: s == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, s),
            );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Update status')),
              tile(ItemStatus.pending, 'Pending'),
              tile(ItemStatus.onTheWay, 'On the way'),
              tile(ItemStatus.completed, 'Completed'),
              tile(ItemStatus.notCompleted, 'Not completed'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reason required'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Why not completed?'),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == null || res.trim().isEmpty) return null;
    return res.trim();
  }
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.read<WishlistStore>();
    final fmt = DateFormat('MMM d, yyyy');
    var tempStatus = store.filterStatus;
    var tempDate = store.filterDate;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemStatus?>(
              initialValue: tempStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: ItemStatus.pending, child: Text('Pending')),
                DropdownMenuItem(value: ItemStatus.onTheWay, child: Text('On the way')),
                DropdownMenuItem(value: ItemStatus.completed, child: Text('Completed')),
                DropdownMenuItem(value: ItemStatus.notCompleted, child: Text('Not completed')),
              ],
              onChanged: (v) => tempStatus = v,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled date'),
              subtitle: Text(tempDate == null ? 'Any' : fmt.format(tempDate)),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    initialDate: tempDate ?? DateTime.now(),
                  );
                  if (picked != null) tempDate = picked;
                },
                child: const Text('Pick'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      store.clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      store.setFilters(status: tempStatus, date: tempDate);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
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

class _CreateWishlistSheet extends StatefulWidget {
  const _CreateWishlistSheet();

  @override
  State<_CreateWishlistSheet> createState() => _CreateWishlistSheetState();
}

class _CreateWishlistSheetState extends State<_CreateWishlistSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final fmt = DateFormat('EEE, MMM d');

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('New wishlist item', style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Notes (price, location, priority...)'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Scheduled: ${fmt.format(_date)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final title = _title.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title is required')),
                    );
                    return;
                  }
                  await context.read<WishlistStore>().add(
                        title: title,
                        description: _desc.text,
                        scheduledDate: _date,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

