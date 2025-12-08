/// Enum for command types that can be parsed from voice input
enum CommandType {
  addWater,
  setWaterTarget,
  addTodo,
  completeTodo,
  setMood,
  startTimer,
  navigate,
  queryStatus,
  undoLast,
  other,
  unknown,
}

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

/// Simplified Command Parser
/// NLP handles intent classification, this just extracts entities
class CommandParser {
  // ============================================================
  // MAIN ENTRY POINTS
  // ============================================================

  /// Parse without NLP (fallback, uses keyword detection)
  static ParsedCommand parse(String text) {
    final lower = text.toLowerCase().trim();

    // Quick keyword-based intent detection
    if (_hasWaterKeywords(lower)) {
      return _extractWater(lower, text);
    } else if (_hasTodoKeywords(lower)) {
      return _extractTodo(lower, text);
    } else if (_hasMoodKeywords(lower)) {
      return _extractMood(lower, text);
    } else if (_hasTimerKeywords(lower)) {
      return _extractTimer(lower, text);
    }

    return ParsedCommand(
      type: CommandType.unknown,
      parameters: {},
      rawText: text,
    );
  }

  /// Parse with NLP intent hint (preferred, more accurate)
  static ParsedCommand parseWithIntent(String text, String intent) {
    final lower = text.toLowerCase().trim();

    switch (intent) {
      case 'water_add':
        return _extractWater(lower, text);
      case 'water_target':
        return _extractWaterTarget(lower, text);
      case 'todo_add':
        return _extractTodo(lower, text);
      case 'todo_complete':
        return _extractTodoComplete(lower, text);
      case 'mood_set':
        return _extractMood(lower, text);
      case 'timer_start':
        return _extractTimer(lower, text);
      case 'navigation':
        return ParsedCommand(
          type: CommandType.navigate,
          parameters: {'target': _extractNavTarget(lower)},
          rawText: text,
        );
      case 'query_status':
        return ParsedCommand(
          type: CommandType.queryStatus,
          parameters: {},
          rawText: text,
        );
      case 'undo_last':
        return ParsedCommand(
          type: CommandType.undoLast,
          parameters: {},
          rawText: text,
        );
      default:
        return ParsedCommand(
          type: CommandType.other,
          parameters: {},
          rawText: text,
        );
    }
  }

  // ============================================================
  // KEYWORD DETECTION (for fallback parsing)
  // ============================================================

  static bool _hasWaterKeywords(String text) {
    return RegExp(
      r'(su|water|ml|litre|liter|bardak|glass|içtim|drank)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _hasTodoKeywords(String text) {
    return RegExp(
      r'(hatırlat|remind|ekle|add|görev|task|yapılacak|todo|unutma)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _hasMoodKeywords(String text) {
    return RegExp(
      r'(mood|ruh|mutlu|üzgün|happy|sad|iyi|kötü|hissediyorum|feel)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _hasTimerKeywords(String text) {
    return RegExp(
      r'(timer|zamanlayıcı|dakika|minute|odaklan|focus|pomodoro)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  // ============================================================
  // ENTITY EXTRACTION
  // ============================================================

  /// Extract water amount (default: 250ml)
  static ParsedCommand _extractWater(String lower, String raw) {
    // Find number
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    int amount = 250; // default

    if (numMatch != null) {
      amount = int.tryParse(numMatch.group(1)!) ?? 250;
      // If litre mentioned, multiply
      if (lower.contains('litre') || lower.contains('liter')) {
        amount = (amount * 1000).clamp(0, 5000);
      }
    } else {
      // Word-based amounts
      if (lower.contains('yarım') || lower.contains('half'))
        amount = 500;
      else if (lower.contains('çeyrek') || lower.contains('quarter'))
        amount = 250;
      else if (lower.contains('bardak') ||
          lower.contains('glass') ||
          lower.contains('cup'))
        amount = 250;
    }

    return ParsedCommand(
      type: CommandType.addWater,
      parameters: {'amount': amount.clamp(50, 5000)},
      rawText: raw,
    );
  }

  /// Extract water target
  static ParsedCommand _extractWaterTarget(String lower, String raw) {
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    int target = 2000; // default

    if (numMatch != null) {
      target = int.tryParse(numMatch.group(1)!) ?? 2000;
      if (lower.contains('litre') || lower.contains('liter')) {
        target *= 1000;
      }
    }

    return ParsedCommand(
      type: CommandType.setWaterTarget,
      parameters: {'target': target.clamp(500, 10000)},
      rawText: raw,
    );
  }

  /// Extract todo task title
  static ParsedCommand _extractTodo(String lower, String raw) {
    print('🔧 _extractTodo input: "$lower"');

    // Remove trigger words to get the task
    String task = lower
        .replaceAll(
          RegExp(
            r'\s*(hatırlat|hatırla|remind|remind me to|remind me|ekle|add|add task|yeni görev|new task|görev ekle|not al|yapılacak ekle|unutma|don.?t forget)\s*',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\s*(lütfen|please|bana|me|to|bir|a)\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    print('🔧 After trigger removal: "$task"');

    // Clean Turkish suffixes
    task = task
        .replaceAll(RegExp(r'(ma|me)y[ıiuü]$', caseSensitive: false), '')
        .replaceAll(RegExp(r"'?[yns]?[ıiuü]$", caseSensitive: false), '')
        .trim();

    print('🔧 After suffix cleanup: "$task"');

    if (task.isEmpty || task.length < 2) {
      return ParsedCommand(
        type: CommandType.unknown,
        parameters: {},
        rawText: raw,
      );
    }

    return ParsedCommand(
      type: CommandType.addTodo,
      parameters: {'title': _capitalize(task)},
      rawText: raw,
    );
  }

  /// Extract completed todo task
  static ParsedCommand _extractTodoComplete(String lower, String raw) {
    // Remove past tense verbs to get the task
    String task = lower
        .replaceAll(
          RegExp(
            r'(yaptım|ettim|bitirdim|tamamladım|hallettim|topladım|temizledim|düzenledim|hazırladım|finished|completed|done|did)',
            caseSensitive: false,
          ),
          '',
        )
        // Remove possessive/accusative suffixes
        .replaceAll(RegExp(r"'?[ıiuü]m[ıiuü]?$", caseSensitive: false), '')
        .replaceAll(RegExp(r"'?[yns]?[ıiuü]$", caseSensitive: false), '')
        .replaceAll(
          RegExp(r'^(i\s+)?', caseSensitive: false),
          '',
        ) // Remove "I" at start
        .trim();

    if (task.isEmpty || task.length < 2) {
      return ParsedCommand(
        type: CommandType.unknown,
        parameters: {},
        rawText: raw,
      );
    }

    return ParsedCommand(
      type: CommandType.completeTodo,
      parameters: {'title': _capitalize(task)},
      rawText: raw,
    );
  }

  /// Extract mood score
  static ParsedCommand _extractMood(String lower, String raw) {
    // Direct number
    final numMatch = RegExp(r'\b(\d+)\b').firstMatch(lower);
    if (numMatch != null) {
      final score = int.tryParse(numMatch.group(1)!) ?? 5;
      return ParsedCommand(
        type: CommandType.setMood,
        parameters: {'score': score.clamp(1, 10)},
        rawText: raw,
      );
    }

    // Word-based mood detection
    final moodWords = {
      // Very happy (9-10)
      'harika': 10, 'muhteşem': 10, 'mükemmel': 10, 'süper': 10, 'müthiş': 10,
      'efsane': 10, 'şahane': 9, 'amazing': 10, 'awesome': 10, 'fantastic': 10,
      'wonderful': 10, 'excellent': 10, 'perfect': 10,
      // Happy (7-8)
      'mutlu': 8, 'iyi': 7, 'güzel': 7, 'keyifli': 8, 'neşeli': 8,
      'happy': 8, 'good': 7, 'great': 8, 'fine': 7, 'cheerful': 8,
      // Neutral (5-6)
      'normal': 5, 'fena değil': 6, 'idare eder': 5, 'şöyle böyle': 5,
      'okay': 5, 'ok': 5, 'so-so': 5, 'not bad': 6, 'alright': 6,
      // Sad (3-4)
      'üzgün': 3, 'kötü': 3, 'mutsuz': 3, 'keyifsiz': 4,
      'sad': 3, 'bad': 3, 'unhappy': 3, 'down': 4, 'low': 4,
      // Very sad (1-2)
      'berbat': 1, 'korkunç': 1, 'felaket': 1,
      'terrible': 1, 'awful': 1, 'horrible': 1,
      // Energy/Stress
      'yorgun': 4, 'stresli': 4, 'tired': 4, 'stressed': 4,
      'enerjik': 8, 'heyecanlı': 8, 'energetic': 8, 'excited': 8,
      'sakin': 6, 'huzurlu': 7, 'calm': 6, 'peaceful': 7,
    };

    // Find matching mood word (longer phrases first)
    final sorted = moodWords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sorted) {
      if (lower.contains(entry.key)) {
        return ParsedCommand(
          type: CommandType.setMood,
          parameters: {'score': entry.value},
          rawText: raw,
        );
      }
    }

    // Default neutral
    return ParsedCommand(
      type: CommandType.setMood,
      parameters: {'score': 5},
      rawText: raw,
    );
  }

  /// Extract timer duration
  static ParsedCommand _extractTimer(String lower, String raw) {
    // Find number
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    int minutes = 25; // default pomodoro

    if (numMatch != null) {
      minutes = int.tryParse(numMatch.group(1)!) ?? 25;
      // If hours mentioned, multiply
      if (lower.contains('saat') || lower.contains('hour')) {
        minutes *= 60;
      }
    }

    return ParsedCommand(
      type: CommandType.startTimer,
      parameters: {'minutes': minutes.clamp(1, 180)},
      rawText: raw,
    );
  }

  /// Extract navigation target
  static String _extractNavTarget(String text) {
    if (text.contains('su') || text.contains('water')) return 'water';
    if (text.contains('görev') ||
        text.contains('todo') ||
        text.contains('task'))
      return 'tasks';
    if (text.contains('rutin') || text.contains('routine')) return 'routines';
    if (text.contains('mood') || text.contains('ruh')) return 'mood';
    if (text.contains('ayar') || text.contains('setting')) return 'settings';
    return 'home';
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
