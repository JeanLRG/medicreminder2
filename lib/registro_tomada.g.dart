// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registro_tomada.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegistroTomadaAdapter extends TypeAdapter<RegistroTomada> {
  @override
  final int typeId = 1;

  @override
  RegistroTomada read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegistroTomada(
      dataHora: fields[0] as DateTime,
      tomado: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RegistroTomada obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dataHora)
      ..writeByte(1)
      ..write(obj.tomado);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistroTomadaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
