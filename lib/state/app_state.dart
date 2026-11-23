import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/classifier.dart';
import '../services/debug_smoke_test.dart';
import '../services/image_sources.dart';

enum PhotoSource {
  camera('Camera', Icons.photo_camera_outlined),
  gallery('Gallery', Icons.photo_library_outlined),
  download('Download', Icons.cloud_download_outlined),
  drawing('Drawing', Icons.draw_outlined);

  const PhotoSource(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum LoadStatus { loading, ready, failed }

class HistoryEntry {
  const HistoryEntry({
    required this.bytes,
    required this.predictions,
    required this.source,
    required this.time,
    required this.inference,
  });
  final Uint8List bytes;
  final List<Prediction> predictions;
  final PhotoSource source;
  final DateTime time;
  final Duration inference;

  Prediction get top => predictions.first;
}

class AppState extends ChangeNotifier {
  AppState({this.sources = const _DefaultSources()});

  final ImageSourcesLike sources;

  Classifier? _classifier;
  LoadStatus status = LoadStatus.loading;
  String? loadError;
  bool busy = false;
  final List<HistoryEntry> history = [];

  Classifier? get classifier => _classifier;
  HistoryEntry? get latest => history.isEmpty ? null : history.first;

  Future<void> load() async {
    if (_classifier != null) return;
    status = LoadStatus.loading;
    loadError = null;
    notifyListeners();
    try {
      _classifier = await Classifier.load();
      status = LoadStatus.ready;
      await debugSmokeTest(_classifier!);
    } on ClassifierLoadException catch (e) {
      status = LoadStatus.failed;
      loadError = e.message;
    } catch (e) {
      status = LoadStatus.failed;
      loadError = 'Unexpected error while loading the model.\n$e';
    }
    notifyListeners();
  }

  // returns null if cancelled
  Future<HistoryEntry?> classifyFrom(
    PhotoSource source,
    Future<Uint8List?> Function() getBytes,
  ) async {
    final classifier = _classifier;
    if (classifier == null) throw const ImageSourceException('The model is not loaded.');
    busy = true;
    notifyListeners();
    try {
      final bytes = await getBytes();
      if (bytes == null) return null;
      final watch = Stopwatch()..start();
      final predictions = await classifier.classify(bytes);
      watch.stop();
      final top = predictions.first;
      debugPrint('classify: ${source.label}, ${watch.elapsedMilliseconds} ms -> ${top.label} '
          '${(top.confidence * 100).toStringAsFixed(1)}%');
      final entry = HistoryEntry(
        bytes: bytes,
        predictions: predictions,
        source: source,
        time: DateTime.now(),
        inference: watch.elapsed,
      );
      history.insert(0, entry);
      return entry;
    } on FormatException {
      throw const FormatException('That file is not a readable image.');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void closeClassifier() {
    _classifier?.close();
    _classifier = null;
  }

  @override
  void dispose() {
    closeClassifier();
    super.dispose();
  }
}

abstract interface class ImageSourcesLike {
  Future<Uint8List?> fromCamera();
  Future<Uint8List?> fromGallery();
  Future<Uint8List> fromUrl(String url);
}

class _DefaultSources implements ImageSourcesLike {
  const _DefaultSources();
  static final _impl = ImageSources();
  @override
  Future<Uint8List?> fromCamera() => _impl.fromCamera();
  @override
  Future<Uint8List?> fromGallery() => _impl.fromGallery();
  @override
  Future<Uint8List> fromUrl(String url) => _impl.fromUrl(url);
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
