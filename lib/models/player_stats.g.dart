// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 7;

  @override
  PlayerStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerStats(
      totalCardsPlayed: fields[0] as int,
      totalCorrect: fields[1] as int,
      bestStreak: fields[2] as int,
      categoryStats: (fields[3] as Map).cast<Category, CategoryStats>(),
      currentDifficulty: (fields[4] as Map).cast<Category, Difficulty>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.totalCardsPlayed)
      ..writeByte(1)
      ..write(obj.totalCorrect)
      ..writeByte(2)
      ..write(obj.bestStreak)
      ..writeByte(3)
      ..write(obj.categoryStats)
      ..writeByte(4)
      ..write(obj.currentDifficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
