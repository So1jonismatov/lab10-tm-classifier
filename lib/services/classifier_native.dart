import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'classifier_types.dart';
import 'labels.dart';

class Classifier {
  Classifier._(
    this._interpreter,
    this.labels,
    this.modelPath,
    this.inputSize, {
    required this.quantized,
    required this.inScale,
    required this.inZero,
    required this.outScale,
    required this.outZero,
  });

  final Interpreter _interpreter;
  final List<String> labels;
  final String modelPath;
  final int inputSize;

  // true for the quantized export (uint8)
  final bool quantized;
  final double inScale, outScale;
  final int inZero, outZero;

  // float export is model_unquant.tflite, quantized is model.tflite
  static const modelCandidates = [
    'assets/model/model_unquant.tflite',
    'assets/model/model.tflite',
  ];
  static const defaultLabelsPath = 'assets/model/labels.txt';

  String get inputDescription =>
      '$inputSize × $inputSize × 3 (${quantized ? 'uint8, quantized' : 'float32'})';

  // slow, only call once
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
        'Model file not found.\nExpected: ${modelPath ?? modelCandidates.join(' or ')}\n'
        'Export it from Teachable Machine (TensorFlow Lite) '
        'and declare the folder in pubspec.yaml.',
      );
    }

    final Interpreter interpreter;
    try {
      interpreter = await Interpreter.fromAsset(found, options: InterpreterOptions()..threads = 4);
    } catch (e) {
      throw ClassifierLoadException('The model file could not be read.\nFile: $found\n$e');
    }

    // check model and labels match
    final input = interpreter.getInputTensor(0);
    final output = interpreter.getOutputTensor(0);
    if (output.shape.last != labels.length) {
      interpreter.close();
      throw ClassifierLoadException(
        'Model has ${output.shape.last} outputs but $labelsPath has ${labels.length} labels.\n'
        'Both files must come from the same export.',
      );
    }
    final isFloat = input.type == TensorType.float32 && output.type == TensorType.float32;
    final isQuant = input.type == TensorType.uint8 && output.type == TensorType.uint8;
    if (!isFloat && !isQuant) {
      interpreter.close();
      throw ClassifierLoadException(
        'Unsupported tensor types (in: ${input.type}, out: ${output.type}).\n'
        'Export the model as TensorFlow Lite, floating point or quantized.',
      );
    }
    return Classifier._(
      interpreter,
      labels,
      found,
      input.shape[1],
      quantized: isQuant,
      inScale: input.params.scale,
      inZero: input.params.zeroPoint,
      outScale: output.params.scale,
      outZero: output.params.zeroPoint,
    );
  }

  // decode + crop + resize, runs in an isolate
  static Uint8List _toRgb(Uint8List bytes, int size) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Not a readable image');
    // same center crop as teachable machine, bakeOrientation fixes exif rotation
    final square = img.copyResizeCropSquare(img.bakeOrientation(decoded), size: size);
    return square.convert(format: img.Format.uint8, numChannels: 3).getBytes(order: img.ChannelOrder.rgb);
  }

  Future<List<Prediction>> classify(Uint8List bytes) async {
    final size = inputSize;
    final rgb = await Isolate.run(() => _toRgb(bytes, size));

    final List<double> scores;
    if (quantized) {
      // quantized: real = (q - zero) * scale
      final lut = Uint8List.fromList([
        for (var v = 0; v < 256; v++) ((v / 127.5 - 1) / inScale + inZero).round().clamp(0, 255),
      ]);
      final input = Uint8List(rgb.length);
      for (var i = 0; i < rgb.length; i++) {
        input[i] = lut[rgb[i]];
      }
      _interpreter.runInference([input]);
      final raw = _interpreter.getOutputTensor(0).copyTo(Uint8List(labels.length)) as Uint8List;
      final real = [for (var i = 0; i < labels.length; i++) (raw[i] - outZero) * outScale];
      // renormalize so it sums to 100%
      final total = real.fold<double>(0, (s, v) => s + v);
      scores = [for (final v in real) total > 0 ? v / total : v];
    } else {
      // float model, input in -1..1
      final input = Float32List(rgb.length);
      for (var i = 0; i < rgb.length; i++) {
        input[i] = rgb[i] / 127.5 - 1;
      }
      _interpreter.runInference([input.buffer.asUint8List()]);
      final raw = _interpreter.getOutputTensor(0).copyTo(Uint8List(labels.length * 4)) as Uint8List;
      scores = raw.buffer.asFloat32List(raw.offsetInBytes, labels.length).toList();
    }

    // pair with labels first, then sort
    return [for (var i = 0; i < labels.length; i++) Prediction(labels[i], math.max(0.0, scores[i]))]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  void close() => _interpreter.close();
}
