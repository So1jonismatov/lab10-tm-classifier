import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/design_credit.dart';

// labels come from the classifier, not from reading the file again
class ModelScreen extends StatelessWidget {
  const ModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classifier = AppScope.of(context).classifier;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Model', style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        if (classifier == null)
          Text('The model is not loaded.', style: theme.textTheme.bodyLarge)
        else ...[
          Card(
            child: Column(
              children: [
                _Fact('Model file', classifier.modelPath.split('/').last),
                _Fact('Classes', '${classifier.labels.length}'),
                _Fact('Input', classifier.inputDescription),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Labels (labels.txt)', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final l in classifier.labels) Chip(label: Text(l))],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Design credit', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: const [
              _Fact('Design', DesignCredit.name),
              _Fact('Author', DesignCredit.author),
              _Fact('Link', DesignCredit.link),
              _Fact('Licence', DesignCredit.licence),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.name, this.value);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(name,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
