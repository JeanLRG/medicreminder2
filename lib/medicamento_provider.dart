import 'package:flutter/material.dart';
import 'medicamento.dart';
import 'medicamento_repository.dart';
import 'notification_service.dart';
import 'registro_tomada.dart';
import 'dart:async';

class MedicamentoProvider extends ChangeNotifier {
  final MedicamentoRepository _repository = MedicamentoRepository();
  final NotificationService _notifications = NotificationService();

  List<Medicamento> _lista = [];
  DateTime _ultimaVerificacao = DateTime.now();
  Timer? _timer;

  int _pontos = 0;
  int _streak = 0;
  DateTime? _ultimoDiaCompleto;
  DateTime? _ultimaTomadaGlobal;
  int _nivel = 1;
  List<String> _badges = [];

  int get pontos => _pontos;
  int get streak => _streak;
  int get nivel => _nivel;
  List<String> get badges => _badges;

  int get xpProximoNivel => 100 + (_nivel - 1) * 50;

  int get xpAtualNoNivel {
    int pontosRestantes = _pontos;
    int nivelCalc = 1;
    while (true) {
      int xpNecessario = 100 + (nivelCalc - 1) * 50;
      if (pontosRestantes >= xpNecessario) {
        pontosRestantes -= xpNecessario;
        nivelCalc++;
      } else {
        return pontosRestantes;
      }
    }
  }

  MedicamentoProvider() {
    _inicializar();
    // Atualiza contagens regressivas na UI a cada minuto
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Medicamento> get lista => _lista;

  double get adesaoHoje {
    if (_lista.isEmpty) return 0;
    int totalHoje = 0;
    int tomadosHoje = 0;
    final agora = DateTime.now();

    for (var med in _lista) {
      if (med.usoContinuo ||
          (med.dataInicio != null &&
              (med.dataFim == null || agora.isBefore(med.dataFim!)))) {
        if (med.totalDosesHoje > 0) {
          totalHoje++;
          if (med.statusHoje == 'tomou') tomadosHoje++;
        }
      }
    }
    return totalHoje == 0 ? 0 : (tomadosHoje / totalHoje) * 100;
  }

  // --- INICIALIZAÇÃO ---

  Future<void> _inicializar() async {
    try {
      await _repository.init();
      await carregarMedicamentos();

      final ultima = await _repository.obterUltimaVerificacao();
      _ultimaVerificacao = ultima ?? DateTime.now();

      final metricas = await _repository.obterMetricas();
      _pontos = metricas['pontos'] ?? 0;
      _streak = metricas['streak'] ?? 0;
      _badges = List<String>.from(metricas['badges'] ?? []);
      _ultimaTomadaGlobal = metricas['ultimaTomada'];
      _ultimoDiaCompleto = metricas['ultimoDiaCompleto'];

      // Recalcular nível de acordo com a curva de XP
      int pontosTemp = _pontos;
      int nivelCalculado = 1;
      while (true) {
        int xpNecessario = 100 + (nivelCalculado - 1) * 50;
        if (pontosTemp >= xpNecessario) {
          pontosTemp -= xpNecessario;
          nivelCalculado++;
        } else {
          break;
        }
      }
      _nivel = nivelCalculado;

      // Zerar streak se parou de usar por mais de 48h
      if (_ultimaTomadaGlobal != null) {
        if (DateTime.now().difference(_ultimaTomadaGlobal!).inHours > 48) {
          _streak = 0;
          await _repository.salvarMetricas(
            _pontos, _streak, _ultimaTomadaGlobal, _ultimoDiaCompleto,
            nivel: _nivel, badges: _badges,
          );
        }
      }

      await verificarMudancaDeDia();
    } catch (e) {
      debugPrint("Erro na inicialização: $e");
    }
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE DADOS ---

  Future<void> carregarMedicamentos() async {
    _lista = await _repository.buscarTodos();
    notifyListeners();
  }

  Future<void> verificarMudancaDeDia() async {
    final agora = DateTime.now();
    if (agora.year != _ultimaVerificacao.year ||
        agora.month != _ultimaVerificacao.month ||
        agora.day != _ultimaVerificacao.day) {
      _ultimaVerificacao = agora;
      await _repository.salvarUltimaVerificacao(agora);
      notifyListeners();
    }
  }

  Future<void> adicionarNovo(
    String nome,
    String horario,
    List<int> dias,
    String dosagem, {
    String? imagemPath,
    int intervaloHoras = 0,
    int intervaloDias = 0,
    bool usoContinuo = true,
    DateTime? dataInicio,
    DateTime? dataFim,
    int comprimidosPorDose = 1,
    bool controlarEstoque = false,
    int quantidadeInicial = 0,
    String tipoAgendamento = "horario",
    DateTime? proximaDataEspecifica,
  }) async {
    final novo = Medicamento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      horario: horario,
      diasDaSemana: dias,
      dosagem: dosagem,
      imagemPath: imagemPath,
      controlarEstoque: controlarEstoque,
      intervaloHoras: intervaloHoras,
      intervaloDias: intervaloDias,
      usoContinuo: usoContinuo,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tipoAgendamento: tipoAgendamento,
      proximaDataEspecifica: proximaDataEspecifica,
      historico: [],
      quantidadeInicial: quantidadeInicial,
      comprimidosPorDose: comprimidosPorDose,
      quantidadeRestante: quantidadeInicial,
      alertaMinimo: 1,
      alertaEstoqueEnviado: false,
    );

    await _repository.salvarMedicamento(novo);
    await carregarMedicamentos();
    await _repository.reagendarTodosMedicamentos();
  }

  Future<void> editarMedicamento(Medicamento med) async {
    await _repository.atualizarMedicamento(med);
    await _repository.reagendarTodosMedicamentos();
    notifyListeners();
  }

  Future<void> reabastecerMedicamento(
      Medicamento med, int quantidadeAdicionada) async {
    if (quantidadeAdicionada <= 0) return;
    med.quantidadeRestante += quantidadeAdicionada;
    med.alertaEstoqueEnviado = false;
    await _repository.atualizarMedicamento(med);
    notifyListeners();
  }

  Future<List<String>> marcarStatus(int index, bool tomou) async {
    List<String> conquistasAlcancadas = [];

    final med = _lista[index];
    final agora = DateTime.now();

    final tomadasHoje = med.historico
        .where((r) =>
            r.tomado == true &&
            r.dataHora.year == agora.year &&
            r.dataHora.month == agora.month &&
            r.dataHora.day == agora.day)
        .length;

    if (tomou && tomadasHoje >= med.totalDosesHoje) {
      debugPrint("Limite de doses diárias atingido para ${med.nome}");
      return conquistasAlcancadas;
    }

    med.historico.add(RegistroTomada(dataHora: agora, tomado: tomou));

    if (tomou && med.controlarEstoque) {
      if (med.quantidadeRestante < med.comprimidosPorDose) {
        debugPrint("Estoque insuficiente para ${med.nome}");
        return conquistasAlcancadas;
      }
      med.quantidadeRestante -= med.comprimidosPorDose;
      if (med.quantidadeRestante < 0) med.quantidadeRestante = 0;
    }

    if (med.controlarEstoque &&
        med.estoqueBaixo &&
        !med.alertaEstoqueEnviado) {
      await _notifications.notificarEstoqueBaixo(med.nome);
      med.alertaEstoqueEnviado = true;
    }

    await _repository.atualizarMedicamento(med);
    await _notifications.cancelarNotificacoesMedicamento(med.id);

    if (tomou) {
      if (_ultimaTomadaGlobal != null &&
          agora.difference(_ultimaTomadaGlobal!).inHours > 48) {
        _streak = 0;
      }

      _pontos += 10;
      _ultimaTomadaGlobal = agora;

      // Verifica se completou o dia
      final todosTomados = _lista.isNotEmpty &&
          _lista.every((m) => m.statusHoje == 'tomou');

      if (todosTomados) {
        final hoje = DateTime.now();
        if (_ultimoDiaCompleto == null ||
            _ultimoDiaCompleto!.day != hoje.day ||
            _ultimoDiaCompleto!.month != hoje.month ||
            _ultimoDiaCompleto!.year != hoje.year) {
          _pontos += 50;
          _streak++;
          _ultimoDiaCompleto = hoje;
        }
      }

      conquistasAlcancadas = _verificarNivelEBadges();

      await _repository.salvarMetricas(
        _pontos, _streak, _ultimaTomadaGlobal, _ultimoDiaCompleto,
        nivel: _nivel, badges: _badges,
      );
    }

    notifyListeners();
    return conquistasAlcancadas;
  }

  Future<void> removerMedicamento(int index) async {
    final med = _lista[index];
    await _repository.removerMedicamento(med.id);
    await carregarMedicamentos();
    await _repository.reagendarTodosMedicamentos();
  }

  List<String> _verificarNivelEBadges() {
    List<String> novosBadges = [];
    int nivelAnterior = _nivel;

    int pontosTemp = _pontos;
    int novoNivel = 1;
    while (true) {
      int xpNecessario = 100 + (novoNivel - 1) * 50;
      if (pontosTemp >= xpNecessario) {
        pontosTemp -= xpNecessario;
        novoNivel++;
      } else {
        break;
      }
    }
    _nivel = novoNivel;

    if (_nivel > nivelAnterior) novosBadges.add('level_up');

    if (!_badges.contains('primeira_tomada') && _pontos > 0) {
      _badges.add('primeira_tomada');
      novosBadges.add('primeira_tomada');
    }
    if (!_badges.contains('em_chamas') && _streak >= 3) {
      _badges.add('em_chamas');
      novosBadges.add('em_chamas');
    }
    if (!_badges.contains('semana_perfeita') && _streak >= 7) {
      _badges.add('semana_perfeita');
      novosBadges.add('semana_perfeita');
    }
    if (!_badges.contains('mestre_da_saude') && _nivel >= 10) {
      _badges.add('mestre_da_saude');
      novosBadges.add('mestre_da_saude');
    }
    if (!_badges.contains('quinzena_perfeita') && _streak >= 15) {
      _badges.add('quinzena_perfeita');
      novosBadges.add('quinzena_perfeita');
    }
    if (!_badges.contains('mes_perfeito') && _streak >= 30) {
      _badges.add('mes_perfeito');
      novosBadges.add('mes_perfeito');
    }
    if (!_badges.contains('veterano') && _nivel >= 25) {
      _badges.add('veterano');
      novosBadges.add('veterano');
    }
    if (!_badges.contains('lenda') && _nivel >= 50) {
      _badges.add('lenda');
      novosBadges.add('lenda');
    }

    return novosBadges;
  }
}