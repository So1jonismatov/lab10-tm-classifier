import 'package:flutter/material.dart';

import '../services/classifier.dart';
import '../theme/app_theme.dart';

String percent(double confidence) => '${(confidence * 100).toStringAsFixed(1)} %';

class LabelRow extends StatelessWidget {
  const LabelRow({super.key, required this.prediction, required this.emphasised});

  final Prediction prediction;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = (emphasised ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(prediction.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: LinearProgressIndicator(
                value: prediction.confidence.clamp(0.0, 1.0),
                minHeight: emphasised ? 10 : 6,
                color: emphasised ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(percent(prediction.confidence), style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
