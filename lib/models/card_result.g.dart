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
    return CardResult(
      cardId: fields[0] as String,
      results: (fields[1] as Map).cast<Category, bool>(),
      timeTaken: fields[2] as Duration,
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
      ..write(obj.timeTaken);
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
