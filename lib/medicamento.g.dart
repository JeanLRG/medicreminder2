// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicamento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicamentoAdapter extends TypeAdapter<Medicamento> {
  @override
  final int typeId = 0;

  @override
  Medicamento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicamento(
      id: fields[0] as String,
      nome: fields[1] as String,
      horario: fields[2] as String,
      quantidadeRestante: fields[12] as int,
      alertaMinimo: fields[13] as int,
      alertaEstoqueEnviado: fields[15] as bool,
      comprimidosPorDose: fields[14] as int,
      controlarEstoque: fields[16] as bool,
      quantidadeInicial: fields[17] as int,
      dosagem: fields[3] as String,
      diasDaSemana: (fields[4] as List).cast<int>(),
      tomado: fields[5] as bool,
      imagemPath: fields[6] as String?,
      intervaloHoras: fields[7] as int,
      usoContinuo: fields[8] as bool,
      dataInicio: fields[9] as DateTime?,
      dataFim: fields[10] as DateTime?,
      historico: (fields[11] as List?)?.cast<RegistroTomada>(),
    );
  }

  @override
  void write(BinaryWriter writer, Medicamento obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.horario)
      ..writeByte(3)
      ..write(obj.dosagem)
      ..writeByte(4)
      ..write(obj.diasDaSemana)
      ..writeByte(5)
      ..write(obj.tomado)
      ..writeByte(6)
      ..write(obj.imagemPath)
      ..writeByte(7)
      ..write(obj.intervaloHoras)
      ..writeByte(8)
      ..write(obj.usoContinuo)
      ..writeByte(9)
      ..write(obj.dataInicio)
      ..writeByte(10)
      ..write(obj.dataFim)
      ..writeByte(11)
      ..write(obj.historico)
      ..writeByte(12)
      ..write(obj.quantidadeRestante)
      ..writeByte(13)
      ..write(obj.alertaMinimo)
      ..writeByte(14)
      ..write(obj.comprimidosPorDose)
      ..writeByte(15)
      ..write(obj.alertaEstoqueEnviado)
      ..writeByte(16)
      ..write(obj.controlarEstoque)
      ..writeByte(17)
      ..write(obj.quantidadeInicial);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
