// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizResultModelAdapter extends TypeAdapter<QuizResultModel> {
  @override
  final int typeId = 7;

  @override
  QuizResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizResultModel(
      lessonId: fields[0] as String,
      totalQuestions: fields[1] as int,
      correctAnswers: fields[2] as int,
      wrongAnswers: fields[3] as int,
      skippedAnswers: fields[4] as int,
      timeTakenSeconds: fields[5] as int,
      completedAt: fields[6] as DateTime,
      questionResults: (fields[7] as List).cast<QuestionResult>(),
    );
  }

  @override
  void write(BinaryWriter writer, QuizResultModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.lessonId)
      ..writeByte(1)
      ..write(obj.totalQuestions)
      ..writeByte(2)
      ..write(obj.correctAnswers)
      ..writeByte(3)
      ..write(obj.wrongAnswers)
      ..writeByte(4)
      ..write(obj.skippedAnswers)
      ..writeByte(5)
      ..write(obj.timeTakenSeconds)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.questionResults);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionResultAdapter extends TypeAdapter<QuestionResult> {
  @override
  final int typeId = 8;

  @override
  QuestionResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionResult(
      questionId: fields[0] as String,
      questionText: fields[1] as String,
      userAnswer: fields[2] as String,
      correctAnswer: fields[3] as String,
      isCorrect: fields[4] as bool,
      isSkipped: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionResult obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.questionText)
      ..writeByte(2)
      ..write(obj.userAnswer)
      ..writeByte(3)
      ..write(obj.correctAnswer)
      ..writeByte(4)
      ..write(obj.isCorrect)
      ..writeByte(5)
      ..write(obj.isSkipped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
