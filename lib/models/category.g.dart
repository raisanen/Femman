// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Category.nowThen;
      case 1:
        return Category.entertainment;
      case 2:
        return Category.nearFar;
      case 3:
        return Category.sportMisc;
      case 4:
        return Category.scienceTech;
      default:
        return Category.nowThen;
    }
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    switch (obj) {
      case Category.nowThen:
        writer.writeByte(0);
        break;
      case Category.entertainment:
        writer.writeByte(1);
        break;
      case Category.nearFar:
        writer.writeByte(2);
        break;
      case Category.sportMisc:
        writer.writeByte(3);
        break;
      case Category.scienceTech:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
