// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 1;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      iconId: fields[2] as int,
      colorHex: fields[3] as String,
      frequency: (fields[4] as List).cast<int>(),
      creationDate: fields[5] as DateTime,
      completedDates: (fields[6] as List?)?.cast<DateTime>(),
      missedDates: (fields[7] as List?)?.cast<DateTime>(),
      type: fields[8] as HabitType,
      targetValue: fields[9] as int?,
      unit: fields[10] as String?,
      dailyValues: (fields[11] as Map?)?.cast<String, int>(),
      completionThreshold: fields[12] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconId)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.creationDate)
      ..writeByte(6)
      ..write(obj.completedDates)
      ..writeByte(7)
      ..write(obj.missedDates)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.targetValue)
      ..writeByte(10)
      ..write(obj.unit)
      ..writeByte(11)
      ..write(obj.dailyValues)
      ..writeByte(12)
      ..write(obj.completionThreshold);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 0;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitType.simple;
      case 1:
        return HabitType.measurable;
      default:
        return HabitType.simple;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.simple:
        writer.writeByte(0);
        break;
      case HabitType.measurable:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
