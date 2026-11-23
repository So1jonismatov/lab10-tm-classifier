import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'classifier_types.dart';
import 'labels.dart';

// web version: tflite_flutter needs dart:ffi, so in the browser we only load
// the labels to show the UI. Classifying works on Android/iOS.
class Classifier {
  Classifier._(this.labels, this.modelPath);

  final List<String> labels;
  final String modelPath;
  final int inputSize = 224;
  final bool quantized = true;

  static const modelCandidates = [
    'assets/model/model_unquant.tflite',
    'assets/model/model.tflite',
  ];
  static const defaultLabelsPath = 'assets/model/labels.txt';

  String get inputDescription => '$inputSize × $inputSize × 3 (runs on Android/iOS only)';

  static Future<Classifier> load({
    String? modelPath,
    String labelsPath = defaultLabelsPath,
  }) async {
    final String rawLabels;
    try {
      rawLabels = await rootBundle.loadString(labelsPath);
    } catch (_) {
      throw ClassifierLoadException('Label file not found.\nExpected: $labelsPath');
    }
    final labels = parseLabels(rawLabels);
    if (labels.isEmpty) {
      throw ClassifierLoadException('Label file is empty.\nChecked: $labelsPath');
    }
    for (final candidate in modelPath == null ? modelCandidates : [modelPath]) {
      try {
        await rootBundle.load(candidate);
        return Classifier._(labels, candidate);
      } catch (_) {}
    }
    throw ClassifierLoadException(
      'Model file not found.\nExpected: ${modelPath ?? modelCandidates.join(' or ')}',
    );
  }

  Future<List<Prediction>> classify(Uint8List bytes) async =>
      throw UnsupportedError('The model only runs on the phone app (Android/iOS), not in the browser.');

  void close() {}
}
