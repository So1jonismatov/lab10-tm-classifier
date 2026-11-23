import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import 'classifier_types.dart';
import 'labels.dart';

// web version: tflite_flutter needs dart:ffi, so in the browser the same
// model.tflite runs with tfjs-tflite (loaded in web/index.html)
@JS('tmLoad')
external JSPromise<JSString> _tmLoad(JSString url);

@JS('tmPredict')
external JSFloat32Array _tmPredict(JSUint8Array rgb, JSNumber size, JSBoolean asFloat);

class Classifier {
  Classifier._(this.labels, this.modelPath, this.inputSize, {required this.quantized});

  final List<String> labels;
  final String modelPath;
  final int inputSize;
  final bool quantized;

  static const modelCandidates = [
    'assets/model/model_unquant.tflite',
    'assets/model/model.tflite',
  ];
  static const defaultLabelsPath = 'assets/model/labels.txt';

  String get inputDescription =>
      '$inputSize × $inputSize × 3 (${quantized ? 'uint8, quantized' : 'float32'}, tfjs in browser)';

  static Future<Classifier> load({
    String? modelPath,
    String labelsPath = defaultLabelsPath,
  }) async {
    final String rawLabels;
    try {
      rawLabels = await rootBundle.loadString(labelsPath);
    } catch (_) {
      throw ClassifierLoadException(
        'Label file not found.\nExpected: $labelsPath\n'
        'Export it from Teachable Machine and declare the folder in pubspec.yaml.',
      );
    }
    final labels = parseLabels(rawLabels);
    if (labels.isEmpty) {
      throw ClassifierLoadException('Label file is empty.\nChecked: $labelsPath');
    }

    String? found;
    for (final candidate in modelPath == null ? modelCandidates : [modelPath]) {
      try {
        await rootBundle.load(candidate);
        found = candidate;
        break;
      } catch (_) {}
    }
    if (found == null) {
      throw ClassifierLoadException(
        'Model file not found.\nExpected: ${modelPath ?? modelCandidates.join(' or ')}',
      );
    }

    final Map<String, dynamic> info;
    try {
      // flutter web serves assets under assets/
      info = jsonDecode((await _tmLoad('assets/$found'.toJS).toDart).toDart) as Map<String, dynamic>;
    } catch (e) {
      throw ClassifierLoadException('The model file could not be read.\nFile: $found\n$e');
    }
    final outShape = (info['outShape'] as List).cast<num>();
    if (outShape.last != labels.length) {
      throw ClassifierLoadException(
        'Model has ${outShape.last} outputs but $labelsPath has ${labels.length} labels.\n'
        'Both files must come from the same export.',
      );
    }
    final inShape = (info['inShape'] as List).cast<num>();
    return Classifier._(
      labels,
      found,
      inShape[1].toInt(),
      quantized: info['inDtype'] != 'float32',
    );
  }

  Future<List<Prediction>> classify(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Not a readable image');
    final square = img.copyResizeCropSquare(img.bakeOrientation(decoded), size: inputSize);
    final rgb = square.convert(format: img.Format.uint8, numChannels: 3).getBytes(order: img.ChannelOrder.rgb);

    final raw = _tmPredict(rgb.toJS, inputSize.toJS, (!quantized).toJS).toDart;
    // quantized output is 0..255, so normalize so it sums to 100%
    final total = raw.fold<double>(0, (s, v) => s + math.max(0.0, v));
    final scores = [for (final v in raw) total > 0 ? math.max(0.0, v) / total : 0.0];

    return [for (var i = 0; i < labels.length; i++) Prediction(labels[i], scores[i])]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  void close() {}
}
