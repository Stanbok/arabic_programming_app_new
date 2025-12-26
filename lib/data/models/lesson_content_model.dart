/// Model representing the full content of a lesson
class LessonContentModel {
  final String id;
  final String title;
  final List<CardModel> cards;

  const LessonContentModel({
    required this.id,
    required this.title,
    required this.cards,
  });

  factory LessonContentModel.fromJson(Map<String, dynamic> json) {
    return LessonContentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      cards: (json['cards'] as List)
          .map((card) => CardModel.fromJson(card))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cards': cards.map((card) => card.toJson()).toList(),
    };
  }
}

/// Types of cards in a lesson
enum CardType { explanation, summary, quiz }

/// Model representing a single card in a lesson
class CardModel {
  final CardType type;
  final List<ContentBlock>? blocks;
  final QuizData? quizData;

  const CardModel({
    required this.type,
    this.blocks,
    this.quizData,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = CardType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => CardType.explanation,
    );

    List<ContentBlock>? blocks;
    QuizData? quizData;

    if (type == CardType.quiz) {
      quizData = QuizData.fromJson(json);
    } else {
      blocks = (json['blocks'] as List?)
          ?.map((block) => ContentBlock.fromJson(block))
          .toList();
    }

    return CardModel(
      type: type,
      blocks: blocks,
      quizData: quizData,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type.name};
    if (blocks != null) {
      map['blocks'] = blocks!.map((b) => b.toJson()).toList();
    }
    if (quizData != null) {
      map.addAll(quizData!.toJson());
    }
    return map;
  }
}

/// Types of content blocks
enum BlockType { text, code, bullets, note, warning, hint, image, video }

/// Model representing a content block within a card
class ContentBlock {
  final BlockType type;
  final String? content;
  final String? language; // For code blocks
  final List<String>? items; // For bullets
  final String? url; // For image/video blocks
  final String? caption; // For image/video blocks
  final String? thumbnail; // For video blocks

  const ContentBlock({
    required this.type,
    this.content,
    this.language,
    this.items,
    this.url,
    this.caption,
    this.thumbnail,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = BlockType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => BlockType.text,
    );

    return ContentBlock(
      type: type,
      content: json['content'] as String?,
      language: json['language'] as String?,
      items: (json['items'] as List?)?.cast<String>(),
      url: json['url'] as String?,
      caption: json['caption'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type.name};
    if (content != null) map['content'] = content;
    if (language != null) map['language'] = language;
    if (items != null) map['items'] = items;
    if (url != null) map['url'] = url;
    if (caption != null) map['caption'] = caption;
    if (thumbnail != null) map['thumbnail'] = thumbnail;
    return map;
  }
}

/// Quiz question types
enum QuizType {
  singleChoice,
  trueFalse,
  fillBlank,
  codeOutput,
  ordering,
  codeChoice,
  findBug,
  matching,
}

/// Model representing quiz data
class QuizData {
  final QuizType questionType;
  final String question;
  final List<String>? options; // For choice-based questions
  final int? correctIndex; // For single choice
  final bool? correctAnswer; // For true/false
  final String? correctText; // For fill blank
  final List<String>? correctOrder; // For ordering
  final Map<String, String>? matchingPairs; // For matching
  final String? codeSnippet; // For code-based questions
  final String? expectedOutput; // For code output
  final String? buggyCode; // For find bug
  final String? fixedCode; // For find bug
  final String explanation;

  const QuizData({
    required this.questionType,
    required this.question,
    this.options,
    this.correctIndex,
    this.correctAnswer,
    this.correctText,
    this.correctOrder,
    this.matchingPairs,
    this.codeSnippet,
    this.expectedOutput,
    this.buggyCode,
    this.fixedCode,
    required this.explanation,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    final typeStr = json['questionType'] as String;
    final questionType = _parseQuizType(typeStr);

    bool? correctAnswer;
    final rawCorrectAnswer = json['correctAnswer'];
    if (rawCorrectAnswer != null) {
      if (rawCorrectAnswer is bool) {
        correctAnswer = rawCorrectAnswer;
      } else if (rawCorrectAnswer is String) {
        correctAnswer = rawCorrectAnswer.toLowerCase() == 'true';
      } else if (rawCorrectAnswer is int) {
        correctAnswer = rawCorrectAnswer == 1;
      }
    }

    return QuizData(
      questionType: questionType,
      question: json['question'] as String,
      options: (json['options'] as List?)?.cast<String>(),
      correctIndex: json['correctIndex'] as int?,
      correctAnswer: correctAnswer,
      correctText: json['correctText'] as String?,
      correctOrder: (json['correctOrder'] as List?)?.cast<String>(),
      matchingPairs: (json['matchingPairs'] as Map?)?.cast<String, String>(),
      codeSnippet: json['codeSnippet'] as String?,
      expectedOutput: json['expectedOutput'] as String?,
      buggyCode: json['buggyCode'] as String?,
      fixedCode: json['fixedCode'] as String?,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  static QuizType _parseQuizType(String type) {
    switch (type) {
      case 'single_choice':
        return QuizType.singleChoice;
      case 'true_false':
        return QuizType.trueFalse;
      case 'fill_blank':
        return QuizType.fillBlank;
      case 'code_output':
        return QuizType.codeOutput;
      case 'ordering':
        return QuizType.ordering;
      case 'code_choice':
        return QuizType.codeChoice;
      case 'find_bug':
        return QuizType.findBug;
      case 'matching':
        return QuizType.matching;
      default:
        return QuizType.singleChoice;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'questionType': questionType.name,
      'question': question,
      if (options != null) 'options': options,
      if (correctIndex != null) 'correctIndex': correctIndex,
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      if (correctText != null) 'correctText': correctText,
      if (correctOrder != null) 'correctOrder': correctOrder,
      if (matchingPairs != null) 'matchingPairs': matchingPairs,
      if (codeSnippet != null) 'codeSnippet': codeSnippet,
      if (expectedOutput != null) 'expectedOutput': expectedOutput,
      if (buggyCode != null) 'buggyCode': buggyCode,
      if (fixedCode != null) 'fixedCode': fixedCode,
      'explanation': explanation,
    };
  }
}
