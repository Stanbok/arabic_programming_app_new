class LessonModel {
  final String id;
  final String pathId;
  final String title;
  final int orderIndex;
  final String thumbnailUrl;
  final List<LessonCard> cards;
  final List<QuizQuestion> quiz;
  final int xpReward;
  final int gemsReward;

  LessonModel({
    required this.id,
    required this.pathId,
    required this.title,
    required this.orderIndex,
    required this.thumbnailUrl,
    required this.cards,
    required this.quiz,
    required this.xpReward,
    required this.gemsReward,
  });

  factory LessonModel.fromMap(Map<String, dynamic> map, String id) {
    return LessonModel(
      id: id,
      pathId: map['pathId'] ?? '',
      title: map['title'] ?? '',
      orderIndex: map['orderIndex'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      cards: (map['content']?['cards'] as List<dynamic>?)
              ?.map((c) => LessonCard.fromMap(c))
              .toList() ?? [],
      quiz: (map['quiz']?['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromMap(q))
              .toList() ?? [],
      xpReward: map['xpReward'] ?? 300,
      gemsReward: map['gemsReward'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pathId': pathId,
      'title': title,
      'orderIndex': orderIndex,
      'thumbnailUrl': thumbnailUrl,
      'content': {
        'cards': cards.map((c) => c.toMap()).toList(),
      },
      'quiz': {
        'questions': quiz.map((q) => q.toMap()).toList(),
      },
      'xpReward': xpReward,
      'gemsReward': gemsReward,
    };
  }
}

class LessonCard {
  final String type; // 'text', 'code', 'mixed', 'quiz_start'
  final String title;
  final String body;
  final String? codeExample;
  final List<String>? bulletPoints;

  LessonCard({
    required this.type,
    required this.title,
    required this.body,
    this.codeExample,
    this.bulletPoints,
  });

  factory LessonCard.fromMap(Map<String, dynamic> map) {
    return LessonCard(
      type: map['type'] ?? 'text',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      codeExample: map['codeExample'],
      bulletPoints: (map['bulletPoints'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      if (codeExample != null) 'codeExample': codeExample,
      if (bulletPoints != null) 'bulletPoints': bulletPoints,
    };
  }
}

class QuizQuestion {
  final String question;
  final String? code;
  final List<String> answers;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    this.code,
    required this.answers,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      code: map['code'],
      answers: (map['answers'] as List<dynamic>?)?.cast<String>() ?? [],
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      if (code != null) 'code': code,
      'answers': answers,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}
