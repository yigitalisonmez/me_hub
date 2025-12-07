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

/// Abstract strategy for parsing a specific type of command
abstract class CommandStrategy {
  /// Try to parse the text into a command. Returns null if not matching.
  ParsedCommand? tryParse(String text);
}

/// Parser for converting speech text into actionable commands
/// Uses Strategy Pattern for extensibility
class CommandParser {
  /// List of strategies in priority order
  static final List<CommandStrategy> _strategies = [
    WaterCommandStrategy(),
    TodoCommandStrategy(),
    MoodCommandStrategy(),
  ];

  /// Parse the recognized text into a command
  static ParsedCommand parse(String text) {
    final lowerText = text.toLowerCase().trim();

    // Try each strategy in order
    for (final strategy in _strategies) {
      final result = strategy.tryParse(lowerText);
      if (result != null) return result;
    }

    // Unknown command
    return ParsedCommand(
      type: CommandType.unknown,
      parameters: {},
      rawText: text,
    );
  }

  /// Register a new command strategy (for extensibility)
  static void registerStrategy(CommandStrategy strategy) {
    _strategies.add(strategy);
  }
}

// ============================================================
// UTILITY: Turkish Suffix Handling
// ============================================================

/// Helper class for Turkish language suffix variations
class TurkishSuffix {
  /// Create a regex pattern that matches Turkish word with possible suffixes
  /// Example: turkishWord('bardak') matches: bardak, bardağ, bardağı, bardağa, bardakı...
  static String word(String root) {
    // Handle consonant softening (sert ünsüz yumuşaması)
    // k→ğ, t→d, p→b, ç→c
    final softened = root
        .replaceAll(RegExp(r'k$'), '[kğ]')
        .replaceAll(RegExp(r't$'), '[td]')
        .replaceAll(RegExp(r'p$'), '[pb]')
        .replaceAll(RegExp(r'ç$'), '[çc]');

    // Allow optional vowel suffixes
    return '$softened[aeiıouüğ]*';
  }

  /// Turkish number words to digits mapping
  static const Map<String, int> numbers = {
    'bir': 1, 'iki': 2, 'üç': 3, 'dört': 4, 'beş': 5,
    'altı': 6, 'yedi': 7, 'sekiz': 8, 'dokuz': 9, 'on': 10,
    'yarım': 0, // Special case, handled separately
  };

  /// English number words
  static const Map<String, int> englishNumbers = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'half': 0, // Special case
  };
}

// ============================================================
// WATER COMMAND STRATEGY
// ============================================================

class WaterCommandStrategy implements CommandStrategy {
  // Flexible patterns for Turkish words with suffixes
  final _litrePat = TurkishSuffix.word('litre');
  final _bardakPat = TurkishSuffix.word('bardak');
  final _sisePat = TurkishSuffix.word('şişe');
  final _suPat = TurkishSuffix.word('su');

  @override
  ParsedCommand? tryParse(String text) {
    // Check for liters with Turkish number words
    for (final entry in TurkishSuffix.numbers.entries) {
      if (entry.value > 0 &&
          RegExp(
            '${entry.key}\\s*$_litrePat',
            caseSensitive: false,
          ).hasMatch(text)) {
        return _water(entry.value * 1000, text);
      }
    }

    // Check for liters with English number words
    for (final entry in TurkishSuffix.englishNumbers.entries) {
      if (entry.value > 0 &&
          RegExp(
            '${entry.key}\\s*(litre|liter|liters|litres|lt)',
            caseSensitive: false,
          ).hasMatch(text)) {
        return _water(entry.value * 1000, text);
      }
    }

    // Check for glasses with Turkish number words
    for (final entry in TurkishSuffix.numbers.entries) {
      if (entry.value > 0 &&
          RegExp(
            '${entry.key}\\s*$_bardakPat',
            caseSensitive: false,
          ).hasMatch(text)) {
        return _water(entry.value * 250, text);
      }
    }

    // Check for glasses with English number words
    for (final entry in TurkishSuffix.englishNumbers.entries) {
      if (entry.value > 0 &&
          RegExp(
            '${entry.key}\\s*(glass|glasses|cup|cups)',
            caseSensitive: false,
          ).hasMatch(text)) {
        return _water(entry.value * 250, text);
      }
    }

    // Liters with digits: "2 litre", "1.5 liter"
    final literMatch = RegExp(
      '(\\d+(?:[.,]\\d+)?)\\s*($_litrePat|liter|liters|litres|lt)',
      caseSensitive: false,
    ).firstMatch(text);

    if (literMatch != null) {
      final literStr = literMatch.group(1)?.replaceAll(',', '.') ?? '';
      final liters = double.tryParse(literStr);
      if (liters != null && liters > 0 && liters <= 10) {
        return _water((liters * 1000).toInt(), text);
      }
    }

    // Glasses with digits: "2 bardak", "3 glasses"
    final glassMatch = RegExp(
      '(\\d+)\\s*($_bardakPat|glass|glasses|cup|cups)',
      caseSensitive: false,
    ).firstMatch(text);

    if (glassMatch != null) {
      final count = int.tryParse(glassMatch.group(1) ?? '');
      if (count != null && count > 0 && count <= 20) {
        return _water(count * 250, text);
      }
    }

    // Bottles: "bir şişe", "2 bottles"
    if (RegExp(
      '(bir|one|a|1)\\s*($_sisePat|bottle)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _water(500, text);
    }

    final bottleMatch = RegExp(
      '(\\d+)\\s*($_sisePat|bottle|bottles)',
      caseSensitive: false,
    ).firstMatch(text);

    if (bottleMatch != null) {
      final count = int.tryParse(bottleMatch.group(1) ?? '');
      if (count != null && count > 0 && count <= 10) {
        return _water(count * 500, text);
      }
    }

    // ML with digits
    final mlMatch = RegExp(
      r'(\d+)\s*(ml|mili|milliliter|milliliters|emel|m\.l\.?)?',
      caseSensitive: false,
    ).firstMatch(text);

    if (mlMatch != null) {
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

      if (isWaterCommand || mlMatch.group(2) != null) {
        final amount = int.tryParse(mlMatch.group(1) ?? '');
        if (amount != null && amount > 0 && amount <= 5000) {
          return _water(amount, text);
        }
      }
    }

    // "yarım litre" / "half liter" → 500ml
    if (RegExp(
      '(yarım|half)\\s*($_litrePat|liter)?',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _water(500, text);
    }

    // "çeyrek litre" / "quarter liter" → 250ml
    if (RegExp(
      '(çeyrek|quarter)\\s*($_litrePat|liter)?',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _water(250, text);
    }

    // "bir bardak" / "one glass" → 250ml
    if (RegExp(
      '(bir|one|a|1)\\s*($_bardakPat|glass|cup)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _water(250, text);
    }

    // "biraz su" / "some water" → 200ml
    if (RegExp(
      '(biraz|some|a\\s+little)\\s*($_suPat|water)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _water(200, text);
    }

    // Default: "su içtim" / "drank water" → 250ml
    if (RegExp(
      '($_suPat\\s*içtim|drank\\s*water|had\\s*water)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _water(250, text);
    }

    return null;
  }

  ParsedCommand _water(int amount, String text) {
    return ParsedCommand(
      type: CommandType.addWater,
      parameters: {'amount': amount},
      rawText: text,
    );
  }
}

// ============================================================
// TODO COMMAND STRATEGY
// ============================================================

class TodoCommandStrategy implements CommandStrategy {
  // Turkish word patterns with suffixes
  final _gorevPat = TurkishSuffix.word('görev');
  final _isPat = TurkishSuffix.word('iş');

  @override
  ParsedCommand? tryParse(String text) {
    final todoPatterns = [
      // English patterns
      RegExp(
        r'(?:add|new|create)\s+(?:task|todo|goal|reminder)\s*[:\s]*(.+)',
        caseSensitive: false,
      ),
      RegExp(r'remind\s+(?:me\s+)?(?:to\s+)?(.+)', caseSensitive: false),
      RegExp(r"don'?t\s+forget\s+(?:to\s+)?(.+)", caseSensitive: false),
      RegExp(r'(?:i\s+)?(?:need|have)\s+to\s+(.+)', caseSensitive: false),

      // Turkish: "yeni görev X" (with suffix support)
      RegExp(
        'yeni\\s+($_gorevPat|$_isPat|yapılacak)\\s*[:\\s]*(.+)',
        caseSensitive: false,
      ),
      // Turkish: "görev ekle X"
      RegExp(
        '($_gorevPat|yapılacak|$_isPat)\\s+(?:ekle|oluştur)\\s*[:\\s]*(.+)',
        caseSensitive: false,
      ),
      // Turkish: "hatırlat X"
      RegExp(r'(?:hatırlat|hatırla)\s*[:\s]*(.+)', caseSensitive: false),
      // Turkish: "not al X"
      RegExp(r'not\s+(?:al|ekle)\s*[:\s]*(.+)', caseSensitive: false),
      // Turkish: "X'i unutma" / "X'ı unutma"
      RegExp(r"(.+)'?[iıuüaeoö]?\s*unutma", caseSensitive: false),
      // Turkish: "X yapmam lazım"
      RegExp(
        r'(.+)\s+(?:yapmam|yapmalıyım|yapmam\s+lazım|yapmam\s+gerek|gerekiyor)',
        caseSensitive: false,
      ),
      // Turkish: "X yapacağım" / "X yapıcam"
      RegExp(r'(.+)\s+(?:yapacağım|yapıcam|yaparım)', caseSensitive: false),

      // Generic: "ekle X"
      RegExp(r'(?:ekle|add)\s*[:\s]+(.+)', caseSensitive: false),
    ];

    for (final pattern in todoPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        // Get the last capturing group (in case of multiple groups)
        var title = match.group(match.groupCount)?.trim();
        if (title != null && title.isNotEmpty) {
          // Clean up common trailing/leading words
          title = _cleanTitle(title);
          if (title.isNotEmpty && title.length > 1) {
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

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\s*(lütfen|please)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(bir|bir\s+tane)\s+', caseSensitive: false), '')
        .trim();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// ============================================================
// MOOD COMMAND STRATEGY
// ============================================================

class MoodCommandStrategy implements CommandStrategy {
  /// Word-based mood mapping (Turkish & English)
  static const Map<String, int> _moodWords = {
    // Very happy (9-10)
    'harika': 10, 'mükemmel': 10, 'muhteşem': 10, 'süper': 10, 'enfes': 10,
    'amazing': 10,
    'fantastic': 10,
    'wonderful': 10,
    'excellent': 10,
    'perfect': 10,

    // Happy (7-8)
    'mutlu': 8, 'iyi': 7, 'güzel': 7, 'keyifli': 8, 'neşeli': 8, 'sevinçli': 8,
    'happy': 8, 'good': 7, 'great': 8, 'fine': 7, 'cheerful': 8, 'joyful': 8,

    // Neutral (5-6)
    'normal': 5, 'fena değil': 6, 'idare eder': 5, 'şöyle böyle': 5, 'orta': 5,
    'okay': 5, 'ok': 5, 'so-so': 5, 'not bad': 6, 'alright': 6, 'meh': 5,

    // Sad (3-4)
    'üzgün': 3,
    'kötü': 3,
    'mutsuz': 3,
    'keyifsiz': 4,
    'hüzünlü': 3,
    'moral bozuk': 3,
    'sad': 3, 'bad': 3, 'unhappy': 3, 'down': 4, 'low': 4, 'upset': 4,

    // Very sad (1-2)
    'berbat': 1, 'korkunç': 1, 'felaket': 1, 'çok kötü': 2, 'rezalet': 1,
    'terrible': 1, 'awful': 1, 'horrible': 1, 'very bad': 2, 'depressed': 2,

    // Tired/Stressed
    'yorgun': 4, 'stresli': 4, 'gergin': 4, 'bitkin': 3, 'bezgin': 3,
    'tired': 4, 'stressed': 4, 'exhausted': 3, 'anxious': 4, 'overwhelmed': 3,

    // Energetic/Excited
    'enerjik': 8, 'heyecanlı': 8, 'coşkulu': 9,
    'energetic': 8, 'excited': 8, 'pumped': 9,

    // Calm/Peaceful
    'sakin': 6, 'huzurlu': 7, 'rahat': 7,
    'calm': 6, 'peaceful': 7, 'relaxed': 7,
  };

  @override
  ParsedCommand? tryParse(String text) {
    // Check for mood words (longer phrases first to avoid partial matches)
    final sortedMoods = _moodWords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedMoods) {
      if (text.contains(entry.key)) {
        return _mood(entry.value, text);
      }
    }

    // Turkish: "kendimi X hissediyorum"
    final feelingMatchTR = RegExp(
      r'(?:kendimi|bugün)\s+(.+?)\s*(?:hissediyorum|hissettim|hissederim)',
      caseSensitive: false,
    ).firstMatch(text);

    if (feelingMatchTR != null) {
      final feeling = feelingMatchTR.group(1)?.toLowerCase().trim();
      if (feeling != null) {
        for (final entry in sortedMoods) {
          if (feeling.contains(entry.key)) {
            return _mood(entry.value, text);
          }
        }
      }
    }

    // English: "I feel X" / "I'm feeling X"
    final feelingMatchEN = RegExp(
      r"(?:i(?:'m)?\s+)?(?:feel(?:ing)?)\s+(.+)",
      caseSensitive: false,
    ).firstMatch(text);

    if (feelingMatchEN != null) {
      final feeling = feelingMatchEN.group(1)?.toLowerCase().trim();
      if (feeling != null) {
        for (final entry in sortedMoods) {
          if (feeling.contains(entry.key)) {
            return _mood(entry.value, text);
          }
        }
      }
    }

    // Numeric patterns
    final moodPatterns = [
      RegExp(
        r'(?:set\s+)?(?:mood|ruh\s*hali|feeling)\s*[:\s]*(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'(\d+)\s*(?:mood|ruh\s*hali|puan)', caseSensitive: false),
      RegExp(r'(?:bugün|today)\s*(\d+)', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:üzerinden|out\s*of)\s*10', caseSensitive: false),
    ];

    for (final pattern in moodPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final score = int.tryParse(match.group(1) ?? '');
        if (score != null && score >= 1 && score <= 10) {
          return _mood(score, text);
        }
      }
    }

    return null;
  }

  ParsedCommand _mood(int score, String text) {
    return ParsedCommand(
      type: CommandType.setMood,
      parameters: {'score': score},
      rawText: text,
    );
  }
}
