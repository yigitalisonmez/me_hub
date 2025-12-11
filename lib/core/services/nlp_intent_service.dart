import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'command_parser.dart';

/// NLP Intent + Entity Service (Dual-Head Model v2)
/// Outputs both intent classification AND entity extraction
class NlpIntentService {
  static NlpIntentService? _instance;

  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, int> _vocab = {};
  Map<int, String> _entities = {};

  // Output indices (detected at runtime based on shape)
  int _intentOutputIdx = 0;
  int _entityOutputIdx = 1;
  int _numIntents = 10;
  int _numEntities = 251;

  static const int _maxLength = 32; // Must match training
  static const String _modelPath = 'assets/ml/zen_flow_v2.tflite';
  static const String _vocabPath = 'assets/ml/vocab.txt';
  static const String _labelsPath = 'assets/ml/labels.txt';
  static const String _entitiesPath = 'assets/ml/entities.json';

  NlpIntentService._();

  static NlpIntentService get instance {
    _instance ??= NlpIntentService._();
    return _instance!;
  }

  bool get isInitialized => _interpreter != null;

  /// Initialize the NLP model
  Future<bool> initialize() async {
    if (isInitialized) {
      print('✅ NLP already initialized');
      return true;
    }

    print('🔄 Initializing Dual-Head NLP model v2...');

    try {
      // Load model
      print('  → Loading TFLite model...');
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      print('  → Model loaded successfully');

      // Load vocabulary
      print('  → Loading vocabulary...');
      final vocabString = await rootBundle.loadString(_vocabPath);
      final vocabLines = vocabString.split('\n');
      for (int i = 0; i < vocabLines.length; i++) {
        final word = vocabLines[i].trim();
        if (word.isNotEmpty) {
          _vocab[word] = i;
        }
      }
      print('  → Vocabulary: ${_vocab.length} words');

      // Load labels
      print('  → Loading labels...');
      final labelsString = await rootBundle.loadString(_labelsPath);
      _labels = labelsString
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _numIntents = _labels.length;
      print('  → Labels: $_labels');

      // Load entities
      print('  → Loading entities...');
      final entitiesString = await rootBundle.loadString(_entitiesPath);
      final entitiesJson = json.decode(entitiesString) as Map<String, dynamic>;
      _entities = entitiesJson.map(
        (k, v) => MapEntry(int.parse(k), v.toString()),
      );
      _numEntities = _entities.length;
      print('  → Entities: $_numEntities');

      // Detect output order from model
      final outputTensors = _interpreter!.getOutputTensors();
      if (outputTensors.length >= 2) {
        final shape0 = outputTensors[0].shape;
        final shape1 = outputTensors[1].shape;

        // Intent has fewer classes (10) than entities (251)
        if (shape0.last == _numIntents) {
          _intentOutputIdx = 0;
          _entityOutputIdx = 1;
        } else {
          _intentOutputIdx = 1;
          _entityOutputIdx = 0;
        }
        print('  → Intent output index: $_intentOutputIdx');
        print('  → Entity output index: $_entityOutputIdx');
      }

      print('✅ NLP Model v2 initialized!');
      return true;
    } catch (e, stack) {
      print('❌ Failed to initialize NLP model: $e');
      print('Stack trace: $stack');
      return false;
    }
  }

  /// Tokenize text to integer array
  List<int> _tokenize(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = cleaned.split(' ');

    final tokens = <int>[];
    for (final word in words) {
      if (word.isEmpty) continue;
      final index = _vocab[word] ?? 1; // 1 = [UNK]
      tokens.add(index);
    }

    // Pad or truncate to maxLength
    while (tokens.length < _maxLength) {
      tokens.add(0);
    }

    return tokens.take(_maxLength).toList();
  }

  /// Process command with dual-head model
  /// Returns ParsedCommand with both intent and entity
  Future<ParsedCommand> processCommand(String text) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 Input: "$text"');

    if (!isInitialized) {
      final ok = await initialize();
      if (!ok) {
        print('⚠️ NLP not initialized, using fallback');
        return CommandParser.parse(text);
      }
    }

    try {
      // Tokenize
      final tokens = _tokenize(text);
      final input = [tokens];

      // Prepare outputs
      final intentOutput = List.generate(
        1,
        (_) => List.filled(_numIntents, 0.0),
      );
      final entityOutput = List.generate(
        1,
        (_) => List.filled(_numEntities, 0.0),
      );

      // Run inference with multiple outputs
      final outputs = {
        _intentOutputIdx: intentOutput,
        _entityOutputIdx: entityOutput,
      };
      _interpreter!.runForMultipleInputs([input], outputs);

      // Parse intent
      final intentProbs = intentOutput[0];
      int intentIdx = 0;
      double intentConf = intentProbs[0];
      for (int i = 1; i < intentProbs.length; i++) {
        if (intentProbs[i] > intentConf) {
          intentConf = intentProbs[i];
          intentIdx = i;
        }
      }
      var intent = _labels[intentIdx];

      // HEURISTIC: Fix "ruh hali" ambiguity
      // If intent is query_status but text contains mood adjectives, switch to mood_set
      if (intent == 'query_status' && _containsMoodAdjective(text)) {
        print(
          '⚠️ Heuristic override: query_status -> mood_set (found adjective)',
        );
        intent = 'mood_set';
      }

      // Parse entity
      final entityProbs = entityOutput[0];
      int entityIdx = 0;
      double entityConf = entityProbs[0];
      for (int i = 1; i < entityProbs.length; i++) {
        if (entityProbs[i] > entityConf) {
          entityConf = entityProbs[i];
          entityIdx = i;
        }
      }
      final entity = _entities[entityIdx] ?? '';

      print('🧠 NLP RESULT:');
      print('   Intent: $intent (${(intentConf * 100).toStringAsFixed(1)}%)');
      print('   Entity: $entity (${(entityConf * 100).toStringAsFixed(1)}%)');

      // Build command based on intent
      final command = _buildCommand(intent, entity, text, intentConf);
      print('📦 Command: ${command.type} | ${command.parameters}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return command;
    } catch (e) {
      print('❌ NLP error: $e');
      print('⚠️ Falling back to regex parser');
      return CommandParser.parse(text);
    }
  }

  /// Check if text contains mood adjectives
  bool _containsMoodAdjective(String text) {
    final lower = text.toLowerCase();
    return lower.contains('iyi') ||
        lower.contains('kötü') ||
        lower.contains('harika') ||
        lower.contains('berbat') ||
        lower.contains('mutlu') ||
        lower.contains('üzgün') ||
        lower.contains('good') ||
        lower.contains('bad') ||
        lower.contains('great') ||
        lower.contains('sad');
  }

  /// Map mood adjectives to score (1-10)
  int? _mapMoodAdjectiveToScore(String text) {
    final lower = text.toLowerCase();

    // High (8-10)
    if (lower.contains('harika') ||
        lower.contains('müthiş') ||
        lower.contains('süper') ||
        lower.contains('bomba') ||
        lower.contains('great') ||
        lower.contains('awesome') ||
        lower.contains('amazing') ||
        lower.contains('excellent'))
      return 10;

    if (lower.contains('mutlu') ||
        lower.contains('happy') ||
        lower.contains('keyifli') ||
        lower.contains('joy'))
      return 9;

    // Good (6-7)
    if (lower.contains('iyi') ||
        lower.contains('good') ||
        lower.contains('güzel') ||
        lower.contains('fine'))
      return 7;

    // Neutral (5)
    if (lower.contains('normal') ||
        lower.contains('idare') ||
        lower.contains('okay') ||
        lower.contains('so so'))
      return 5;

    // Low (3-4)
    if (lower.contains('kötü') ||
        lower.contains('bad') ||
        lower.contains('keyifsiz') ||
        lower.contains('mutsuz') ||
        lower.contains('unhappy') ||
        lower.contains('sad'))
      return 3;

    // Very Low (1-2)
    if (lower.contains('berbat') ||
        lower.contains('terrible') ||
        lower.contains('korkunç') ||
        lower.contains('awful') ||
        lower.contains('rezalet') ||
        lower.contains('depressed'))
      return 1;

    return null;
  }

  /// Build ParsedCommand from NLP outputs
  ParsedCommand _buildCommand(
    String intent,
    String entity,
    String rawText,
    double confidence,
  ) {
    // Low confidence fallback
    if (confidence < 0.5) {
      return CommandParser.parse(rawText);
    }

    switch (intent) {
      case 'water_add':
        // Use regex to extract number, fallback to entity, then default
        final amount =
            _extractNumberFromText(rawText) ?? int.tryParse(entity) ?? 250;
        return ParsedCommand(
          type: CommandType.addWater,
          parameters: {'amount': amount},
          rawText: rawText,
        );

      case 'water_target':
        final target =
            _extractNumberFromText(rawText) ?? int.tryParse(entity) ?? 2000;
        return ParsedCommand(
          type: CommandType.setWaterTarget,
          parameters: {'target': target},
          rawText: rawText,
        );

      case 'todo_add':
        // Always use original text to preserve language
        final title = _extractTaskFromText(rawText);
        return ParsedCommand(
          type: CommandType.addTodo,
          parameters: {'title': title},
          rawText: rawText,
        );

      case 'todo_complete':
        // Always use original text to preserve language
        final title = _extractCompletedTaskFromText(rawText);
        return ParsedCommand(
          type: CommandType.completeTodo,
          parameters: {'title': title},
          rawText: rawText,
        );

      case 'mood_set':
        final score =
            _extractNumberFromText(rawText) ??
            _mapMoodAdjectiveToScore(rawText) ??
            int.tryParse(entity) ??
            5;
        return ParsedCommand(
          type: CommandType.setMood,
          parameters: {'score': score.clamp(1, 10)},
          rawText: rawText,
        );

      case 'timer_start':
        final minutes =
            _extractNumberFromText(rawText) ?? int.tryParse(entity) ?? 25;
        return ParsedCommand(
          type: CommandType.startTimer,
          parameters: {'minutes': minutes},
          rawText: rawText,
        );

      case 'navigation':
        return ParsedCommand(
          type: CommandType.navigate,
          parameters: {'target': entity.isNotEmpty ? entity : 'home'},
          rawText: rawText,
        );

      case 'query_status':
        return ParsedCommand(
          type: CommandType.queryStatus,
          parameters: {'topic': entity},
          rawText: rawText,
        );

      case 'undo_last':
        return ParsedCommand(
          type: CommandType.undoLast,
          parameters: {'type': entity},
          rawText: rawText,
        );

      default:
        return ParsedCommand(
          type: CommandType.other,
          parameters: {},
          rawText: rawText,
        );
    }
  }

  /// Extract number from text (e.g. "3200 ml" -> 3200)
  int? _extractNumberFromText(String text) {
    final lower = text.toLowerCase();

    // Handle "10 üzerinden X" (Turkish)
    final trMatch = RegExp(r'10\s*üzerinden\s*(\d+)').firstMatch(lower);
    if (trMatch != null) {
      return int.tryParse(trMatch.group(1)!);
    }

    // Handle "X out of 10" (English)
    final enMatch = RegExp(r'(\d+)\s*out\s*of\s*10').firstMatch(lower);
    if (enMatch != null) {
      return int.tryParse(enMatch.group(1)!);
    }

    // Look for digits
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    // Look for text numbers (simple ones)
    if (lower.contains('bir') || lower.contains('one')) return 1;
    if (lower.contains('iki') || lower.contains('two')) return 2;
    if (lower.contains('üç') || lower.contains('three')) return 3;
    if (lower.contains('dört') || lower.contains('four')) return 4;
    if (lower.contains('beş') || lower.contains('five')) return 5;
    if (lower.contains('altı') || lower.contains('six')) return 6;
    if (lower.contains('yedi') || lower.contains('seven')) return 7;
    if (lower.contains('sekiz') || lower.contains('eight')) return 8;
    if (lower.contains('dokuz') || lower.contains('nine')) return 9;
    if (lower.contains('on') || lower.contains('ten')) return 10;

    return null;
  }

  /// Extract task title from raw text for todo_add
  String _extractTaskFromText(String text) {
    final lower = text.toLowerCase();
    // Remove common trigger words (TR + EN)
    var task = lower
        .replaceAll(
          RegExp(
            r'\s*(hatırlat|hatırla|remind|remind me to|ekle|add|unutma|don.?t forget)\s*',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s*(me|to|bana|bir)\s*$', caseSensitive: false),
          '',
        )
        // Remove Turkish verb suffixes
        .replaceAll(RegExp(r'(ma|me)y[ıiuü]$', caseSensitive: false), '')
        .trim();
    return _capitalize(task);
  }

  /// Extract task title from raw text for todo_complete (past tense)
  String _extractCompletedTaskFromText(String text) {
    final lower = text.toLowerCase();
    // Remove past tense verbs (TR + EN)
    var task = lower
        .replaceAll(
          RegExp(
            r'\s*(yaptım|ettim|bitirdim|tamamladım|hallettim|topladım|temizledim|düzenledim|hazırladım|finished|completed|done|did)\s*',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'^(i\s+)?', caseSensitive: false),
          '',
        ) // Remove "I" at start
        // Remove possessive/accusative suffixes
        .replaceAll(RegExp(r"'?[ıiuü]m[ıiuü]?$", caseSensitive: false), '')
        .replaceAll(RegExp(r"'?[yns]?[ıiuü]$", caseSensitive: false), '')
        .trim();
    return _capitalize(task);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

/// Result of intent classification (legacy, kept for compatibility)
class IntentResult {
  final String intent;
  final double confidence;
  final Map<String, double> allProbabilities;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.allProbabilities,
  });

  bool isConfident(double threshold) => confidence >= threshold;
  double get confidencePercent => confidence * 100;
}
