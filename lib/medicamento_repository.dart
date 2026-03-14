import 'package:hive_flutter/hive_flutter.dart';
import 'medicamento.dart';
import 'notification_service.dart';
import 'registro_tomada.dart';

class MedicamentoRepository {
  static const String _boxName = 'medicamentosBox';

  // Inicializa o Hive (Resolve erro da linha 17 do Provider)
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicamentoAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RegistroTomadaAdapter());
    }

    await Hive.openBox<Medicamento>(_boxName);
  }

  // Busca todos (Resolve erro da linha 23 do Provider)
  Future<List<Medicamento>> buscarTodos() async {
    final box = Hive.box<Medicamento>(_boxName);
    return box.values.toList();
  }

  // Salva no Hive (Resolve erro da linha 60 do Provider)
  Future<void> salvarMedicamento(Medicamento med) async {
    final box = Hive.box<Medicamento>(_boxName);
    await box.put(med.id, med);
  }

  Future<void> removerMedicamento(String id) async {
    final box = Hive.box<Medicamento>(_boxName);
    await box.delete(id);
  }

  Future<void> salvarUltimaVerificacao(DateTime data) async {
    final box = await Hive.openBox('config');
    await box.put('ultimaVerificacao', data.toIso8601String());
  }

  Future<DateTime?> obterUltimaVerificacao() async {
    final box = await Hive.openBox('config');
    final str = box.get('ultimaVerificacao');
    if (str == null) return null;
    return DateTime.parse(str);
  }


  // Atualiza (Resolve erro das linhas 91 e 120 do Provider)
  Future<void> atualizarMedicamento(Medicamento med) async {
    await med.save();
  }

  Future<void> reagendarTodosMedicamentos() async {
    final notificacao = NotificationService();

    // 1️⃣ Cancela tudo
    await notificacao.cancelarTodasNotificacoes();

    // 2️⃣ Busca todos medicamentos salvos
    final medicamentos = await buscarTodos();

    // 3️⃣ Reagenda um por um
    for (var med in medicamentos) {
      await notificacao.agendarMedicamento(
        id: med.id,
        nome: med.nome,
        horario: med.horario,
        diasDaSemana: med.diasDaSemana,
        // Se você já tiver intervaloHoras e datas no modelo, adiciona aqui
      );
    }
  }

}