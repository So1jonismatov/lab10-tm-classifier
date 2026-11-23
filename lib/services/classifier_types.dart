class Prediction {
  const Prediction(this.label, this.confidence);
  final String label;
  final double confidence; // 0.0 to 1.0
}

class ClassifierLoadException implements Exception {
  const ClassifierLoadException(this.message);
  final String message;
  @override
  String toString() => message;
}
