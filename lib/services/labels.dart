// "0 Mug\n1 Bottle" -> ['Mug', 'Bottle']
List<String> parseLabels(String raw) => [
      for (final line in raw.split(RegExp(r'\r\n|\r|\n')))
        if (line.trim().isNotEmpty) line.trim().replaceFirst(RegExp(r'^\d+\s+'), ''),
    ];
