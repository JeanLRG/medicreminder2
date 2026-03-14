import 'package:hive/hive.dart';

part 'registro_tomada.g.dart';

@HiveType(typeId: 1)
class RegistroTomada extends HiveObject {

  @HiveField(0)
  DateTime dataHora;

  @HiveField(1)
  bool tomado;

  RegistroTomada({required this.dataHora, required this.tomado});
}
