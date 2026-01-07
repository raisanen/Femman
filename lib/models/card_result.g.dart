// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardResultAdapter extends TypeAdapter<CardResult> {
  @override
  final int typeId = 4;

  @override
  CardResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Handle web platform where Hive returns Map<dynamic, dynamic>
    final resultsMap = fields[1] as Map;
    final results = <Category, bool>{};
    for (final entry in resultsMap.entries) {
      final category = entry.key as Category;
      final isCorrect = entry.value as bool;
      results[category] = isCorrect;
    }
    
    return CardResult(
      cardId: fields[0] as String,
      results: results,
      timeTaken: Duration(milliseconds: fields[2] as int),
    );
  }

  @override
  void write(BinaryWriter writer, CardResult obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.cardId)
      ..writeByte(1)
      ..write(obj.results)
      ..writeByte(2)
      ..write(obj.timeTakenMilliseconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
