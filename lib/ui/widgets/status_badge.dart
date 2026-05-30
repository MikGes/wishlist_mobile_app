import 'package:flutter/material.dart';

import '../../domain/status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ItemStatus.completed => ('Completed', const Color(0xFF2ED47A)),
      ItemStatus.onTheWay => ('On the way', const Color(0xFFFFC542)),
      ItemStatus.notCompleted => ('Not completed', const Color(0xFFFF4D4D)),
      ItemStatus.pending => ('Pending', const Color(0xFF8A8FFF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

