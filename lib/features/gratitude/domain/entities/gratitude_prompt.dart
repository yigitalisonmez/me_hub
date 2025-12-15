import 'dart:math';

/// Categories for diversified prompts
enum PromptCategory {
  social, // Sosyal bağlara odaklanma
  past, // Geçmiş anılar
  challenge, // Zorluklardan öğrenme
  body, // Beden farkındalığı
  daily, // Günlük minnettarlık
  nature, // Doğa ve çevre
}

/// A gratitude prompt with category and localized content
class GratitudePrompt {
  final String id;
  final String content;
  final String contentTr; // Turkish translation
  final PromptCategory category;

  const GratitudePrompt({
    required this.id,
    required this.content,
    required this.contentTr,
    required this.category,
  });

  /// All available prompts - diversified to prevent habituation
  static const List<GratitudePrompt> allPrompts = [
    // Social - Sosyal
    GratitudePrompt(
      id: 'social_1',
      content: 'Who helped you or made you smile today?',
      contentTr: 'Bugün sana kim yardım etti veya seni gülümsetti?',
      category: PromptCategory.social,
    ),
    GratitudePrompt(
      id: 'social_2',
      content: 'What do you appreciate about someone who supports you?',
      contentTr: 'Hayatında sana destek olan biri için minnettar olduğun şey?',
      category: PromptCategory.social,
    ),
    GratitudePrompt(
      id: 'social_3',
      content: 'Which relationship in your life brings you the most joy?',
      contentTr: 'Hangi ilişki hayatına en çok neşe katıyor?',
      category: PromptCategory.social,
    ),

    // Past - Geçmiş
    GratitudePrompt(
      id: 'past_1',
      content: 'What do you have from the past that you no longer notice?',
      contentTr: 'Geçmişte sahip olduğun ama artık fark etmediğin bir şey ne?',
      category: PromptCategory.past,
    ),
    GratitudePrompt(
      id: 'past_2',
      content: 'Which memory from your childhood still makes you happy?',
      contentTr: 'Çocukluğundan hangi anı seni hala mutlu ediyor?',
      category: PromptCategory.past,
    ),
    GratitudePrompt(
      id: 'past_3',
      content: 'What skill or lesson from the past serves you today?',
      contentTr: 'Geçmişten hangi beceri veya ders bugün sana hizmet ediyor?',
      category: PromptCategory.past,
    ),

    // Challenge - Zorluklar
    GratitudePrompt(
      id: 'challenge_1',
      content: 'What positive outcome came from a difficult situation?',
      contentTr: 'Sana zorluk çıkaran bir durumun hangi pozitif sonucu oldu?',
      category: PromptCategory.challenge,
    ),
    GratitudePrompt(
      id: 'challenge_2',
      content: 'What did you learn from a failure?',
      contentTr: 'Başarısızlıktan ne öğrendin?',
      category: PromptCategory.challenge,
    ),
    GratitudePrompt(
      id: 'challenge_3',
      content: 'How did a past struggle make you stronger?',
      contentTr: 'Geçmişteki bir zorluk seni nasıl güçlendirdi?',
      category: PromptCategory.challenge,
    ),

    // Body - Beden
    GratitudePrompt(
      id: 'body_1',
      content: 'Which body function are you grateful for today?',
      contentTr:
          'Vücudunda sana iyi hizmet eden hangi fonksiyona şükrediyorsun?',
      category: PromptCategory.body,
    ),
    GratitudePrompt(
      id: 'body_2',
      content: 'What is the best feeling your body gave you today?',
      contentTr: 'Bedeninin bugün sana verdiği en güzel his ne?',
      category: PromptCategory.body,
    ),
    GratitudePrompt(
      id: 'body_3',
      content: 'What physical ability do you often take for granted?',
      contentTr: 'Hangi fiziksel yeteneğini sıklıkla hafife alıyorsun?',
      category: PromptCategory.body,
    ),

    // Daily - Günlük
    GratitudePrompt(
      id: 'daily_1',
      content: 'What surprised you in a good way today?',
      contentTr: 'Bugün seni iyi yönde şaşırtan ne oldu?',
      category: PromptCategory.daily,
    ),
    GratitudePrompt(
      id: 'daily_2',
      content: 'What small detail made you happy this week?',
      contentTr: 'Bu hafta seni mutlu eden en küçük detay ne?',
      category: PromptCategory.daily,
    ),
    GratitudePrompt(
      id: 'daily_3',
      content: 'What ordinary thing would you miss if it was gone?',
      contentTr: 'Kaybolsa özleyeceğin sıradan bir şey ne?',
      category: PromptCategory.daily,
    ),

    // Nature - Doğa
    GratitudePrompt(
      id: 'nature_1',
      content: 'What in nature brought you peace or joy recently?',
      contentTr: 'Doğada son zamanlarda sana huzur veya neşe veren ne oldu?',
      category: PromptCategory.nature,
    ),
    GratitudePrompt(
      id: 'nature_2',
      content: 'What weather or season do you appreciate?',
      contentTr: 'Hangi hava durumu veya mevsim seni mutlu ediyor?',
      category: PromptCategory.nature,
    ),
  ];

  /// Get a random prompt
  static GratitudePrompt getRandomPrompt() {
    final random = Random();
    return allPrompts[random.nextInt(allPrompts.length)];
  }

  /// Get a random prompt from a specific category
  static GratitudePrompt getRandomPromptByCategory(PromptCategory category) {
    final categoryPrompts = allPrompts
        .where((p) => p.category == category)
        .toList();
    if (categoryPrompts.isEmpty) return getRandomPrompt();
    final random = Random();
    return categoryPrompts[random.nextInt(categoryPrompts.length)];
  }

  /// Get prompts excluding recently used ones
  static GratitudePrompt getNovelPrompt(List<String> recentPromptIds) {
    final availablePrompts = allPrompts
        .where((p) => !recentPromptIds.contains(p.id))
        .toList();
    if (availablePrompts.isEmpty) return getRandomPrompt();
    final random = Random();
    return availablePrompts[random.nextInt(availablePrompts.length)];
  }
}

/// Available emotion tags for labeling gratitude items
class EmotionTags {
  static const List<String> all = [
    'Huzur', // Peace
    'Coşku', // Excitement
    'Güven', // Trust
    'Sevgi', // Love
    'Neşe', // Joy
    'Umut', // Hope
    'Minnet', // Gratitude
    'Şefkat', // Compassion
    'Hayranlık', // Admiration
    'Keyif', // Pleasure
    'Şükran', // Thankfulness
    'Bağlılık', // Connection
  ];

  /// Get emoji for emotion tag
  static String getEmoji(String tag) {
    switch (tag) {
      case 'Huzur':
        return '😌';
      case 'Coşku':
        return '🤩';
      case 'Güven':
        return '🤝';
      case 'Sevgi':
        return '❤️';
      case 'Neşe':
        return '😄';
      case 'Umut':
        return '🌟';
      case 'Minnet':
        return '🙏';
      case 'Şefkat':
        return '🤗';
      case 'Hayranlık':
        return '✨';
      case 'Keyif':
        return '😊';
      case 'Şükran':
        return '💛';
      case 'Bağlılık':
        return '🔗';
      default:
        return '💫';
    }
  }
}
