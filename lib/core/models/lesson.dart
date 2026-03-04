import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson.g.dart';
part 'lesson.freezed.dart';

@freezed
class ContentBlock with _$ContentBlock {
  const factory ContentBlock.text(String value) = TextBlock;
  const factory ContentBlock.code(String value) = CodeBlock;
  const factory ContentBlock.tip(String value) = TipBlock;
  const factory ContentBlock.warning(String value) = WarningBlock;
  const factory ContentBlock.interactive(Map<String, dynamic> payload) = InteractiveExampleBlock;
  const factory ContentBlock.list(List<String> items) = ListBlock;
  const factory ContentBlock.image(String url) = ImageBlock;
  const factory ContentBlock.video(String url) = VideoBlock;

  factory ContentBlock.fromJson(Map<String, dynamic> json) => _$ContentBlockFromJson(json);
}

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String unitId,
    required String title,
    required List<ContentBlock> content,
    String? quizId,
  }) = _Lesson;

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);
}
