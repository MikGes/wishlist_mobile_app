import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../ui/widgets/empty_state.dart';
import 'feed_store.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FeedStore>();
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Feed'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => store.refresh(),
              icon: store.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        if (store.posts.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              title: 'No posts yet',
              subtitle: store.lastError == null
                  ? 'Tap refresh to fetch content.'
                  : 'Could not fetch posts.\n${store.lastError}',
              action: FilledButton.icon(
                onPressed: () => store.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList.separated(
              itemCount: store.posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = store.posts[i];
                final fmt = DateFormat('MMM d • HH:mm');
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
                                p.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                p.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fmt.format(p.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Text(p.content),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

