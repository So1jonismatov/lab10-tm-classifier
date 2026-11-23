import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'shell_screen.dart';

// also the loading screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final classes = state.classifier?.labels ?? const <String>[];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.center_focus_strong_outlined, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Teach It, Ship It', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Recognises my own objects from a photo, fully offline, '
                    'with a model I trained myself.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  switch (state.status) {
                    LoadStatus.loading => const _Loading(),
                    LoadStatus.failed => _LoadError(message: state.loadError ?? '', onRetry: state.load),
                    LoadStatus.ready => Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [for (final c in classes) Chip(label: Text(c))],
                      ),
                  },
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.status == LoadStatus.ready
                          ? () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(builder: (_) => const ShellScreen()),
                              )
                          : null,
                      child: const Text('Get started'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.sm),
          Text('Loading the model…', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: AppSpacing.sm),
              Text('The model could not be loaded',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onErrorContainer)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: TextStyle(color: scheme.onErrorContainer)),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
