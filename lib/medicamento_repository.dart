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

  Future<void> salvarMetricas(int pontos, int streak, DateTime? ultimaTomada, DateTime? ultimoDiaCompleto, {int nivel = 1, List<String> badges = const []}) async {
    final box = await Hive.openBox('config');
    await box.put('pontos', pontos);
    await box.put('streak', streak);
    await box.put('nivel', nivel);
    await box.put('badges', badges);
    if (ultimaTomada != null) {
      await box.put('ultimaTomada', ultimaTomada.toIso8601String());
    }
    if (ultimoDiaCompleto != null) {
      await box.put('ultimoDiaCompleto', ultimoDiaCompleto.toIso8601String());
    }
  }

  Future<Map<String, dynamic>> obterMetricas() async {
    final box = await Hive.openBox('config');
    final pontos = box.get('pontos', defaultValue: 0);
    final streak = box.get('streak', defaultValue: 0);
    final nivel = box.get('nivel', defaultValue: 1);
    final List<dynamic> rawBadges = box.get('badges', defaultValue: []);
    final badges = rawBadges.cast<String>();
    
    final strUltimaTomada = box.get('ultimaTomada');
    DateTime? ultimaTomada = strUltimaTomada != null ? DateTime.tryParse(strUltimaTomada) : null;
    
    final strUltimoDia = box.get('ultimoDiaCompleto');
    DateTime? ultimoDiaCompleto = strUltimoDia != null ? DateTime.tryParse(strUltimoDia) : null;

    return {
      'pontos': pontos,
      'streak': streak,
      'nivel': nivel,
      'badges': badges,
      'ultimaTomada': ultimaTomada,
      'ultimoDiaCompleto': ultimoDiaCompleto,
    };
  }


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
        dosagem: med.dosagem,
        comprimidosPorDose: med.comprimidosPorDose,
        // Se você já tiver intervaloHoras e datas no modelo, adiciona aqui
      );
    }
  }

}