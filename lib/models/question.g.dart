// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 0;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      category: fields[1] as Category,
      textSv: fields[2] as String,
      textEn: fields[3] as String,
      optionsSv: (fields[4] as List<dynamic>).map((e) => e as String).toList(),
      optionsEn: (fields[5] as List<dynamic>).map((e) => e as String).toList(),
      correctIndex: fields[6] as int,
      difficulty: fields[7] as Difficulty,
      funFactSv: fields[8] as String?,
      funFactEn: fields[9] as String?,
      generatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.textSv)
      ..writeByte(3)
      ..write(obj.textEn)
      ..writeByte(4)
      ..write(obj.optionsSv)
      ..writeByte(5)
      ..write(obj.optionsEn)
      ..writeByte(6)
      ..write(obj.correctIndex)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.funFactSv)
      ..writeByte(9)
      ..write(obj.funFactEn)
      ..writeByte(10)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
