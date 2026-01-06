// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryStatsAdapter extends TypeAdapter<CategoryStats> {
  @override
  final int typeId = 5;

  @override
  CategoryStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryStats(
      attempted: fields[0] as int,
      correct: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryStats obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.attempted)
      ..writeByte(1)
      ..write(obj.correct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
