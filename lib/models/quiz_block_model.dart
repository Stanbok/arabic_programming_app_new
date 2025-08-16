class QuizBlockModel {
  final String id;
  final String type; // multiple_choice, reorder_code, find_bug, fill_blank, true_false, match_pairs, code_output
  final String question;
  final Map<String, dynamic> content;
  final EvaluationModel evaluation;
  final HintModel? hint;
  final int order;

  QuizBlockModel({
    required this.id,
    required this.type,
    required this.question,
    required this.content,
    required this.evaluation,
    this.hint,
    required this.order,
  });

  factory QuizBlockModel.fromJson(Map<String, dynamic> json) {
    return QuizBlockModel(
      id: json['id'],
      type: json['type'],
      question: json['question'],
      content: json['content'],
      evaluation: EvaluationModel.fromJson(json['evaluation']),
      hint: json['hint'] != null ? HintModel.fromJson(json['hint']) : null,
      order: json['order'],
    );
  }
}

class HintModel {
  final String id;
  final String type; // quick, strong
  final String content;
  final int gemsCost;
  final bool isConditional;
  final Map<String, dynamic>? conditions;

  HintModel({
    required this.id,
    required this.type,
    required this.content,
    required this.gemsCost,
    required this.isConditional,
    this.conditions,
  });

  factory HintModel.fromJson(Map<String, dynamic> json) {
    return HintModel(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      gemsCost: json['gemsCost'],
      isConditional: json['isConditional'],
      conditions: json['conditions'],
    );
  }
}
