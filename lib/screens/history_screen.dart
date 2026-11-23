import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/history_tile.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final history = state.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: Text('History', style: theme.textTheme.headlineMedium),
        ),
        Expanded(
          child: history.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  title: 'No classifications yet',
                  message: 'Take a photo, pick one from the gallery or download an image. It will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => HistoryTile(
                    entry: history[i],
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => ResultScreen(entry: history[i]))),
                  ),
                ),
        ),
      ],
    );
  }
}
