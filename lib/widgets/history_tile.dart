import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'label_row.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          child: Image.memory(entry.bytes, width: 56, height: 56, fit: BoxFit.cover, cacheWidth: 112),
        ),
        title: Text(entry.top.label, style: theme.textTheme.titleMedium),
        subtitle: Text(percent(entry.top.confidence)),
        trailing: Tooltip(
          message: entry.source.label,
          child: Icon(entry.source.icon, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
