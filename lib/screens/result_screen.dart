import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/label_row.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxImageHeight = MediaQuery.sizeOf(context).height / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Chip(
              avatar: Icon(entry.source.icon, size: 18, color: theme.colorScheme.onSecondaryContainer),
              label: Text(entry.source.label),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxImageHeight),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                      child: Image.memory(entry.bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < entry.predictions.length; i++)
                LabelRow(prediction: entry.predictions[i], emphasised: i == 0),
              const SizedBox(height: AppSpacing.md),
              Text(
                'On-device inference: ${entry.inference.inMilliseconds} ms',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
