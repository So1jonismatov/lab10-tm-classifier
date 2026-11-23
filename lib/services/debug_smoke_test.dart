import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'classifier.dart';

// smoke test with assets/model/sample.jpg (debug only)
Future<void> debugSmokeTest(Classifier classifier) async {
  if (!kDebugMode) return;
  try {
    final data = await rootBundle.load('assets/model/sample.jpg');
    final results = await classifier.classify(data.buffer.asUint8List());
    var sum = 0.0;
    for (final p in results) {
      sum += p.confidence;
      debugPrint('${p.label.padRight(14)} ${(p.confidence * 100).toStringAsFixed(1)} %');
    }
    debugPrint('smoke test: ${results.length} lines, top = ${results.first.label}, sum = ${sum.toStringAsFixed(3)}');
  } catch (e) {
    debugPrint('smoke test skipped (add assets/model/sample.jpg): $e');
  }
}
