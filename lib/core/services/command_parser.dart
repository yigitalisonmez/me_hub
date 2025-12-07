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

  // ============================================================
  // WATER COMMAND PARSING
  // ============================================================

  /// Parse water-related commands
  static ParsedCommand? _parseWaterCommand(String text) {
    // Turkish number words to digits mapping
    final turkishNumbers = {
      'bir': 1,
      'iki': 2,
      'üç': 3,
      'dört': 4,
      'beş': 5,
      'altı': 6,
      'yedi': 7,
      'sekiz': 8,
      'dokuz': 9,
      'on': 10,
    };

    // English number words
    final englishNumbers = {
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
    };

    // Check for liters with number words: "iki litre", "two liters"
    for (final entry in {...turkishNumbers, ...englishNumbers}.entries) {
      if (RegExp(
        '${entry.key}\\s*(litre|liter|litres|liters|lt)',
        caseSensitive: false,
      ).hasMatch(text)) {
        return ParsedCommand(
          type: CommandType.addWater,
          parameters: {'amount': entry.value * 1000},
          rawText: text,
        );
      }
    }

    // Check for glasses with number words: "iki bardak", "two glasses"
    for (final entry in {...turkishNumbers, ...englishNumbers}.entries) {
      if (RegExp(
        '${entry.key}\\s*(bardak|glass|glasses|cup|cups)',
        caseSensitive: false,
      ).hasMatch(text)) {
        return ParsedCommand(
          type: CommandType.addWater,
          parameters: {'amount': entry.value * 250}, // 250ml per glass
          rawText: text,
        );
      }
    }

    // Check for liters with digits: "2 litre", "2 liters", "1.5 liter"
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

    // Check for multiple glasses with digits: "2 bardak", "3 glasses"
    final glassMatch = RegExp(
      r'(\d+)\s*(bardak|glass|glasses|cup|cups)',
      caseSensitive: false,
    ).firstMatch(text);

    if (glassMatch != null) {
      final count = int.tryParse(glassMatch.group(1) ?? '');
      if (count != null && count > 0 && count <= 20) {
        return ParsedCommand(
          type: CommandType.addWater,
          parameters: {'amount': count * 250},
          rawText: text,
        );
      }
    }

    // Check for bottles: "bir şişe", "a bottle", "one bottle"
    if (RegExp(
      r'(bir|one|a|1)\s*(şişe|bottle)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 500}, // Standard bottle = 500ml
        rawText: text,
      );
    }

    // Check for multiple bottles
    final bottleMatch = RegExp(
      r'(\d+)\s*(şişe|bottle|bottles)',
      caseSensitive: false,
    ).firstMatch(text);

    if (bottleMatch != null) {
      final count = int.tryParse(bottleMatch.group(1) ?? '');
      if (count != null && count > 0 && count <= 10) {
        return ParsedCommand(
          type: CommandType.addWater,
          parameters: {'amount': count * 500},
          rawText: text,
        );
      }
    }

    // Pattern: number + ml/milliliters
    final numberMatch = RegExp(
      r'(\d+)\s*(ml|mili|milliliter|milliliters|emel|m\.l\.?)?',
      caseSensitive: false,
    ).firstMatch(text);

    if (numberMatch != null) {
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
        'içiyorum',
      ];

      bool isWaterCommand = waterKeywords.any((k) => text.contains(k));

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

    // Pattern: "çeyrek litre" / "quarter liter" → 250ml
    if (RegExp(
      r'(çeyrek|quarter)\s*(litre|liter)?',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 250},
        rawText: text,
      );
    }

    // Pattern: "bir bardak" / "one glass" / "a glass" → 250ml
    if (RegExp(
      r'(bir|one|a|1)\s*(bardak|glass|cup)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 250},
        rawText: text,
      );
    }

    // Pattern: "biraz su" / "some water" → 200ml (small amount)
    if (RegExp(
      r'(biraz|some|a\s+little)\s*(su|water)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 200},
        rawText: text,
      );
    }

    // Default water without amount: "su içtim" / "drank water" → 250ml
    if (RegExp(
      r'(su\s*içtim|drank\s*water|had\s*water|water\s*please)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return ParsedCommand(
        type: CommandType.addWater,
        parameters: {'amount': 250},
        rawText: text,
      );
    }

    return null;
  }

  // ============================================================
  // TODO COMMAND PARSING
  // ============================================================

  /// Parse todo-related commands
  static ParsedCommand? _parseTodoCommand(String text) {
    final todoPatterns = [
      // English patterns
      RegExp(
        r'(?:add|new|create)\s+(?:task|todo|goal|reminder)\s*[:\s]*(.+)',
        caseSensitive: false,
      ),
      RegExp(r'remind\s+(?:me\s+)?(?:to\s+)?(.+)', caseSensitive: false),
      RegExp(r"don'?t\s+forget\s+(?:to\s+)?(.+)", caseSensitive: false),
      RegExp(r'(?:i\s+)?(?:need|have)\s+to\s+(.+)', caseSensitive: false),

      // Turkish: "yeni görev X"
      RegExp(
        r'yeni\s+(?:görev|iş|yapılacak)\s*[:\s]*(.+)',
        caseSensitive: false,
      ),
      // Turkish: "görev ekle X"
      RegExp(
        r'(?:görev|yapılacak|iş)\s+(?:ekle|oluştur)\s*[:\s]*(.+)',
        caseSensitive: false,
      ),
      // Turkish: "hatırlat X"
      RegExp(r'(?:hatırlat|hatırla)\s*[:\s]*(.+)', caseSensitive: false),
      // Turkish: "not al X"
      RegExp(r'not\s+(?:al|ekle)\s*[:\s]*(.+)', caseSensitive: false),
      // Turkish: "X'i unutma"
      RegExp(r"(.+)'?[iıuü]?\s*unutma", caseSensitive: false),
      // Turkish: "X yapmam lazım"
      RegExp(
        r'(.+)\s+(?:yapmam|yapmalıyım|yapmam\s+lazım|gerekiyor)',
        caseSensitive: false,
      ),

      // Generic: "ekle X"
      RegExp(r'(?:ekle|add)\s*[:\s]+(.+)', caseSensitive: false),
    ];

    for (final pattern in todoPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var title = match.group(1)?.trim();
        if (title != null && title.isNotEmpty) {
          // Clean up common trailing words
          title = title.replaceAll(
            RegExp(r'\s*(lütfen|please)$', caseSensitive: false),
            '',
          );
          title = title.trim();
          if (title.isNotEmpty) {
            return ParsedCommand(
              type: CommandType.addTodo,
              parameters: {'title': _capitalizeFirst(title)},
              rawText: text,
            );
          }
        }
      }
    }

    return null;
  }

  // ============================================================
  // MOOD COMMAND PARSING
  // ============================================================

  /// Parse mood-related commands
  static ParsedCommand? _parseMoodCommand(String text) {
    // Word-based mood mapping
    final moodWords = {
      // Very happy (9-10)
      'harika': 10, 'mükemmel': 10, 'muhteşem': 10, 'süper': 10,
      'amazing': 10,
      'fantastic': 10,
      'wonderful': 10,
      'excellent': 10,
      'perfect': 10,

      // Happy (7-8)
      'mutlu': 8, 'iyi': 7, 'güzel': 7, 'keyifli': 8, 'neşeli': 8,
      'happy': 8, 'good': 7, 'great': 8, 'fine': 7, 'cheerful': 8, 'joyful': 8,

      // Neutral (5-6)
      'normal': 5, 'fena değil': 6, 'idare eder': 5, 'şöyle böyle': 5,
      'okay': 5, 'ok': 5, 'so-so': 5, 'not bad': 6, 'alright': 6,

      // Sad (3-4)
      'üzgün': 3, 'kötü': 3, 'mutsuz': 3, 'keyifsiz': 4, 'hüzünlü': 3,
      'sad': 3, 'bad': 3, 'unhappy': 3, 'down': 4, 'low': 4,

      // Very sad (1-2)
      'berbat': 1, 'korkunç': 1, 'felaket': 1, 'çok kötü': 2,
      'terrible': 1, 'awful': 1, 'horrible': 1, 'very bad': 2, 'depressed': 2,

      // Tired/Stressed
      'yorgun': 4, 'stresli': 4, 'gergin': 4,
      'tired': 4, 'stressed': 4, 'exhausted': 3, 'anxious': 4,
    };

    // Check for mood words
    for (final entry in moodWords.entries) {
      if (text.contains(entry.key)) {
        return ParsedCommand(
          type: CommandType.setMood,
          parameters: {'score': entry.value},
          rawText: text,
        );
      }
    }

    // Turkish: "kendimi X hissediyorum"
    final feelingMatch = RegExp(
      r'(?:kendimi|bugün)\s+(.+?)\s*(?:hissediyorum|hissettim)',
      caseSensitive: false,
    ).firstMatch(text);

    if (feelingMatch != null) {
      final feeling = feelingMatch.group(1)?.toLowerCase().trim();
      if (feeling != null) {
        for (final entry in moodWords.entries) {
          if (feeling.contains(entry.key)) {
            return ParsedCommand(
              type: CommandType.setMood,
              parameters: {'score': entry.value},
              rawText: text,
            );
          }
        }
      }
    }

    // English: "I feel X" / "I'm feeling X"
    final iFeelMatch = RegExp(
      r"(?:i(?:'m)?\s+)?(?:feel(?:ing)?)\s+(.+)",
      caseSensitive: false,
    ).firstMatch(text);

    if (iFeelMatch != null) {
      final feeling = iFeelMatch.group(1)?.toLowerCase().trim();
      if (feeling != null) {
        for (final entry in moodWords.entries) {
          if (feeling.contains(entry.key)) {
            return ParsedCommand(
              type: CommandType.setMood,
              parameters: {'score': entry.value},
              rawText: text,
            );
          }
        }
      }
    }

    // Numeric patterns: "mood 7", "set mood 8", "ruh hali 6"
    final moodPatterns = [
      RegExp(
        r'(?:set\s+)?(?:mood|ruh\s*hali|feeling)\s*[:\s]*(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'(\d+)\s*(?:mood|ruh\s*hali)', caseSensitive: false),
      RegExp(r'(?:bugün|today)\s*(\d+)', caseSensitive: false),
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
