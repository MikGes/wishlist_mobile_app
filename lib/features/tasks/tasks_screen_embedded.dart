import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/models/task_item.dart';
import '../../domain/status.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import 'tasks_store.dart';

class TasksScreenEmbedded extends StatelessWidget {
  const TasksScreenEmbedded({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TasksStore>();
    final scheme = Theme.of(context).colorScheme;

    if (store.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
    }

    if (store.tasks.isEmpty) {
      return EmptyState(
        title: 'No tasks today',
        subtitle: 'Add a task to track its status and see it in your analytics.',
        action: FilledButton.icon(
          onPressed: () => _openCreate(context),
          icon: const Icon(Icons.add),
          label: const Text('Add task'),
        ),
      );
    }

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Column(
        children: [
          ListTile(
            title: const Text('Tasks'),
            trailing: IconButton(
              tooltip: 'Add task',
              onPressed: () => _openCreate(context),
              icon: const Icon(Icons.add),
            ),
          ),
          const Divider(height: 1),
          ...store.tasks.take(6).map((t) => _TaskRow(task: t)),
          if (store.tasks.length > 6)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '+ ${store.tasks.length - 6} more',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateTaskSheet(),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final store = context.read<TasksStore>();
    final fmt = DateFormat('EEE, MMM d');

    return ListTile(
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Due ${fmt.format(task.dueDate)}'),
      leading: StatusBadge(status: task.status),
      trailing: PopupMenuButton<ItemStatus>(
        tooltip: 'Update status',
        onSelected: (s) async {
          try {
            if (s == ItemStatus.notCompleted) {
              final reason = await _askReason(context);
              if (reason == null) return;
              await store.updateStatus(task, s, notCompletedReason: reason);
            } else {
              await store.updateStatus(task, s);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: ItemStatus.pending, child: Text('Pending')),
          PopupMenuItem(value: ItemStatus.onTheWay, child: Text('On the way')),
          PopupMenuItem(value: ItemStatus.completed, child: Text('Completed')),
          PopupMenuItem(value: ItemStatus.notCompleted, child: Text('Not completed')),
        ],
      ),
      onLongPress: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (ok == true) {
          await store.delete(task);
        }
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

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet();

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime _due = DateTime.now();

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
                  child: Text('New task', style: Theme.of(context).textTheme.titleLarge),
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
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Due: ${fmt.format(_due)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      initialDate: _due,
                    );
                    if (picked != null) setState(() => _due = picked);
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
                  await context.read<TasksStore>().add(
                        title: title,
                        description: _desc.text,
                        dueDate: _due,
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

