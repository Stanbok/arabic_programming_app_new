enum QuestionType {
  multipleChoice,
  reorderCode,
  findBug,
  fillBlank,
  trueFalse,
  matchPairs,
  codeOutput,
  completeCode,
}

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'اختيار من متعدد';
      case QuestionType.reorderCode:
        return 'ترتيب الكود';
      case QuestionType.findBug:
        return 'اكتشف الخطأ';
      case QuestionType.fillBlank:
        return 'املأ الفراغ';
      case QuestionType.trueFalse:
        return 'صح أو خطأ';
      case QuestionType.matchPairs:
        return 'توصيل الأزواج';
      case QuestionType.codeOutput:
        return 'نتيجة الكود';
      case QuestionType.completeCode:
        return 'أكمل الكود';
    }
  }

  String get englishName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.reorderCode:
        return 'reorder_code';
      case QuestionType.findBug:
        return 'find_bug';
      case QuestionType.fillBlank:
        return 'fill_blank';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.matchPairs:
        return 'match_pairs';
      case QuestionType.codeOutput:
        return 'code_output';
      case QuestionType.completeCode:
        return 'complete_code';
    }
  }

  static QuestionType fromString(String type) {
    switch (type) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'reorder_code':
        return QuestionType.reorderCode;
      case 'find_bug':
        return QuestionType.findBug;
      case 'fill_blank':
        return QuestionType.fillBlank;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'match_pairs':
        return QuestionType.matchPairs;
      case 'code_output':
        return QuestionType.codeOutput;
      case 'complete_code':
        return QuestionType.completeCode;
      default:
        return QuestionType.multipleChoice;
    }
  }
}
