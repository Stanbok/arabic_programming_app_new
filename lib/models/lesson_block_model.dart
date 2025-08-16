class LessonBlockModel {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> content;
  final Map<String, dynamic>? settings;
  final EvaluationModel? evaluation;
  final int order;

  LessonBlockModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.settings,
    this.evaluation,
    required this.order,
  });

  factory LessonBlockModel.fromJson(Map<String, dynamic> json) {
    return LessonBlockModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      content: json['content'],
      settings: json['settings'],
      evaluation: json['evaluation'] != null 
          ? EvaluationModel.fromJson(json['evaluation']) 
          : null,
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'content': content,
      'settings': settings,
      'evaluation': evaluation?.toJson(),
      'order': order,
    };
  }
}

class EvaluationModel {
  final String type; // exact, contains, regex, assertions, unit_tests, custom
  final dynamic expectedOutput;
  final String? pattern;
  final List<String>? testCases;
  final String? customScript;
  final String successMessage;
  final String failureMessage;

  EvaluationModel({
    required this.type,
    this.expectedOutput,
    this.pattern,
    this.testCases,
    this.customScript,
    required this.successMessage,
    required this.failureMessage,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      type: json['type'],
      expectedOutput: json['expectedOutput'],
      pattern: json['pattern'],
      testCases: json['testCases']?.cast<String>(),
      customScript: json['customScript'],
      successMessage: json['successMessage'],
      failureMessage: json['failureMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'expectedOutput': expectedOutput,
      'pattern': pattern,
      'testCases': testCases,
      'customScript': customScript,
      'successMessage': successMessage,
      'failureMessage': failureMessage,
    };
  }
}
