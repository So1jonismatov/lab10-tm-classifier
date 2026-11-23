import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/image_sources.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/history_tile.dart';
import 'draw_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _run(
    BuildContext context,
    PhotoSource source,
    Future<Uint8List?> Function() getBytes,
  ) async {
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final entry = await state.classifyFrom(source, getBytes);
      if (entry != null) {
        await navigator.push(MaterialPageRoute<void>(builder: (_) => ResultScreen(entry: entry)));
      }
    } on ImageSourceException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  Future<void> _askUrl(BuildContext context) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download an image'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Image address', hintText: 'https://…'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Download')),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.trim().isEmpty || !context.mounted) return;
    final sources = AppScope.of(context).sources;
    await _run(context, PhotoSource.download, () => sources.fromUrl(url));
  }

  Future<void> _draw(BuildContext context) => _run(
        context,
        PhotoSource.drawing,
        () => Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(builder: (_) => const DrawScreen()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final sources = state.sources;
    final latest = state.latest;
    final disabled = state.busy;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Read a digit', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Pick where the picture comes from.', style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: disabled ? null : () => _run(context, PhotoSource.camera, sources.fromCamera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take a photo'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: disabled ? null : () => _run(context, PhotoSource.gallery, sources.fromGallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: disabled ? null : () => _askUrl(context),
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Download an image'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: disabled ? null : () => _draw(context),
              icon: const Icon(Icons.draw_outlined),
              label: const Text('Draw a digit'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Most recent', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (latest == null)
              Text(
                'Nothing classified yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              HistoryTile(
                entry: latest,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => ResultScreen(entry: latest))),
              ),
          ],
        ),
        if (state.busy)
          Positioned.fill(
            child: ColoredBox(
              color: theme.colorScheme.scrim.withValues(alpha: 0.32),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
