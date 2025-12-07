/// Enum for command types that can be parsed from voice input
enum CommandType { addWater, addTodo, setMood, unknown }

/// Parsed command with type and extracted parameters
class ParsedCommand {
  final CommandType type;
  final Map<String, dynamic> parameters;
  final String rawText;

  ParsedCommand({
    required this.type,
    required this.parameters,
    required this.rawText,
  });

  @override
  String toString() => 'ParsedCommand(type: $type, params: $parameters)';
}

/// Parser for converting speech text into actionable commands
class CommandParser {
  /// Parse the recognized text into a command
  static ParsedCommand parse(String text) {
    final lowerText = text.toLowerCase().trim();

    // Try to parse water command
    final waterResult = _parseWaterCommand(lowerText);
    if (waterResult != null) return waterResult;

    // Try to parse todo command
    final todoResult = _parseTodoCommand(lowerText);
    if (todoResult != null) return todoResult;

    // Try to parse mood command
    final moodResult = _parseMoodCommand(lowerText);
    if (moodResult != null) return moodResult;

    // Unknown command
    return ParsedCommand(
      type: CommandType.unknown,
      parameters: {},
      rawText: text,
    );
  }

  /// Parse water-related commands
  static ParsedCommand? _parseWaterCommand(String text) {
    // First check for liters: "2 litre", "2 liters", "2 liter"
    // Must check this BEFORE ml to avoid "2" being matched alone
    final literMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(litre|liter|liters|litres|lt)',
      caseSensitive: false,
    ).firstMatch(text);

    if (literMatch != null) {
      final literStr = literMatch.group(1)?.replaceAll(',', '.') ?? '';
      final liters = double.tryParse(literStr);
      if (liters != null && liters > 0 && liters <= 10) {
        final amountMl = (liters * 1000).toInt();
        return ParsedCommand(
          type: CommandType.addWater,
          parameters: {'amount': amountMl},
          rawText: text,
        );
      }
    }

    // Pattern: number + ml/milliliters/mililiter/emel
    // Examples: "500 ml", "add 500 ml", "I drank 500 ml", "500 eMeL içtim"
    final numberMatch = RegExp(
      r'(\d+)\s*(ml|mili|milliliter|milliliters|emel|m\.l\.?)?',
      caseSensitive: false,
    ).firstMatch(text);

    if (numberMatch != null) {
      // Check if this is likely a water command
      final waterKeywords = [
        'ml',
        'mili',
        'milliliter',
        'milliliters',
        'emel',
        'water',
        'su',
        'drank',
        'drink',
        'içtim',
        'iç',
      ];

      bool isWaterCommand = waterKeywords.any((k) => text.contains(k));

      // Also accept plain numbers if there's a unit
      if (isWaterCommand || numberMatch.group(2) != null) {
        final amount = int.tryParse(numberMatch.group(1) ?? '');
        if (amount != null && amount > 0 && amount <= 5000) {
          return ParsedCommand(
            type: CommandType.addWater,
            parameters: {'amount': amount},
            rawText: text,
          );
        }
      }
    }

    // Pattern: "yarım litre" / "half liter" → 500ml
    if (RegExp(
      r'(yarım|half)\s*(litre|liter)?',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 500},
        rawText: text,
      );
    }

    // Pattern: "bir bardak" / "one glass" / "a glass" → use default glass size
    if (RegExp(
      r'(bir|one|a|1)\s*(bardak|glass|cup)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 250}, // Default glass size
        rawText: text,
      );
    }

    return null;
  }

  /// Parse todo-related commands
  static ParsedCommand? _parseTodoCommand(String text) {
    // Patterns for adding todo:
    // "add task ..." / "add todo ..." / "new task ..."
    // "görev ekle ..." / "yapılacak ekle ..."

    final todoPatterns = [
      RegExp(
        r'(?:add|new|create)\s+(?:task|todo|goal)\s*[:\s]*(.+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:görev|yapılacak|iş)\s+(?:ekle|oluştur)\s*[:\s]*(.+)',
        caseSensitive: false,
      ),
      RegExp(r'(?:ekle|add)\s*[:\s]+(.+)', caseSensitive: false),
    ];

    for (final pattern in todoPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final title = match.group(1)?.trim();
        if (title != null && title.isNotEmpty) {
          return ParsedCommand(
            type: CommandType.addTodo,
            parameters: {'title': _capitalizeFirst(title)},
            rawText: text,
          );
        }
      }
    }

    return null;
  }

  /// Parse mood-related commands
  static ParsedCommand? _parseMoodCommand(String text) {
    // Patterns for setting mood:
    // "mood 7" / "set mood 8" / "ruh hali 6" / "feeling 9"

    final moodPatterns = [
      RegExp(
        r'(?:set\s+)?(?:mood|ruh\s*hali|feeling)\s*[:\s]*(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'(\d+)\s*(?:mood|ruh\s*hali)', caseSensitive: false),
    ];

    for (final pattern in moodPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final score = int.tryParse(match.group(1) ?? '');
        if (score != null && score >= 1 && score <= 10) {
          return ParsedCommand(
            type: CommandType.setMood,
            parameters: {'score': score},
            rawText: text,
          );
        }
      }
    }

    return null;
  }

  /// Capitalize first letter of a string
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
