// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizCardAdapter extends TypeAdapter<QuizCard> {
  @override
  final int typeId = 3;

  @override
  QuizCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizCard(
      id: fields[0] as String,
      questions: (fields[1] as List).cast<Question>(),
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuizCard obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.questions)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
