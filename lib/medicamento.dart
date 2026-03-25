import 'package:hive/hive.dart';
import 'registro_tomada.dart';
import 'package:flutter/material.dart';

part 'medicamento.g.dart';

@HiveType(typeId: 0)
class Medicamento extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  String horario;

  @HiveField(3)
  String dosagem;

  @HiveField(4)
  List<int> diasDaSemana;

  @HiveField(5)
  bool tomado;

  @HiveField(6)
  String? imagemPath;

  @HiveField(7)
  int intervaloHoras; // 0 = horário específico

  @HiveField(8)
  bool usoContinuo;

  @HiveField(9)
  DateTime? dataInicio;

  @HiveField(10)
  DateTime? dataFim;

  @HiveField(11)
  List<RegistroTomada> historico;

  @HiveField(12)
  int quantidadeRestante;

  @HiveField(13)
  int alertaMinimo;

  @HiveField(14)
  int comprimidosPorDose;

  bool get estoqueBaixo {
    if (!controlarEstoque) return false;
    return dosesRestantes <= alertaMinimo;
  }

  @HiveField(15)
  bool alertaEstoqueEnviado;

  @HiveField(16)
  bool controlarEstoque;

  @HiveField(17)
  int quantidadeInicial;

  @HiveField(18)
  int intervaloDias;


  Medicamento({
    required this.id,
    required this.nome,
    required this.horario,
    required this.quantidadeRestante,
    required this.alertaMinimo,
    required this.alertaEstoqueEnviado,
    required this.comprimidosPorDose,
    required this.controlarEstoque,
    required this.quantidadeInicial,
    this.dosagem = '',
    this.diasDaSemana = const [],
    this.tomado = false,
    this.imagemPath,
    this.intervaloHoras = 0,
    this.intervaloDias = 0,
    this.usoContinuo = true,
    this.dataInicio,
    this.dataFim,
    List<RegistroTomada>? historico,
  }) : historico = historico ?? [];

  // =============================================================
  // GETTERS DE LÓGICA DE TEMPO
  // =============================================================

  DateTime? get proximaDose {
    final agora = DateTime.now();

    // Se tem data fim e já passou → o tratamento encerrou
    if (dataFim != null && agora.isAfter(dataFim!)) return null;

    // CASO INTERVALO EM DIAS
    if (intervaloDias > 0 && dataInicio != null) {
      int diasPassados = agora.difference(dataInicio!).inDays;
      int proximoMultiplo = ((diasPassados ~/ intervaloDias) + 1) * intervaloDias;
      return dataInicio!.add(Duration(days: proximoMultiplo));
    }

    // CASO 1 — INTERVALO (Ex: 8 em 8 horas)
    if (intervaloHoras > 0) {
      if (historico.isEmpty) return dataInicio ?? agora;

      // Ordena uma cópia para não alterar a lista original do Hive acidentalmente
      final copiaHistorico = List<RegistroTomada>.from(historico);
      copiaHistorico.sort((a, b) => b.dataHora.compareTo(a.dataHora));

      final ultima = copiaHistorico.first.dataHora;
      return ultima.add(Duration(hours: intervaloHoras));
    }

    // CASO 2 — HORÁRIO FIXO (Ex: 08:00)
    try {
      final partes = horario.split(":");
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);

      // Se diasDaSemana estiver vazio, assume-se uso diário (1 a 7)
      final diasValidos = diasDaSemana.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : diasDaSemana;

      for (int i = 0; i <= 7; i++) {
        final diaTeste = agora.add(Duration(days: i));

        if (diasValidos.contains(diaTeste.weekday)) {
          final dataCalculada = DateTime(
            diaTeste.year,
            diaTeste.month,
            diaTeste.day,
            hora,
            minuto,
          );

          if (dataCalculada.isAfter(agora)) {
            // Garante que a dose sugerida não ultrapassa o fim do tratamento
            if (dataFim != null && dataCalculada.isAfter(dataFim!)) return null;
            return dataCalculada;
          }
        }
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  String get statusHoje {
    final hoje = DateTime.now();

    final registrosHoje = historico.where((r) =>
    r.dataHora.year == hoje.year &&
        r.dataHora.month == hoje.month &&
        r.dataHora.day == hoje.day
    ).toList();

    if (registrosHoje.isEmpty) return 'pendente';

    final tomadas = registrosHoje.where((r) => r.tomado).length;
    final puladas = registrosHoje.where((r) => !r.tomado).length;

    if (tomadas >= totalDosesHoje) return 'tomou';
    if (puladas >= totalDosesHoje) return 'pulou';

    return 'pendente';
  }



  String get proximaDoseRestante {
    final proxima = proximaDose;
    if (proxima == null) return "Finalizado";

    final agora = DateTime.now();
    final diff = proxima.difference(agora);

    if (diff.isNegative) return "Disponível agora";

    final h = diff.inHours;
    final m = diff.inMinutes % 60;

    return h > 0 ? "em ${h}h ${m}m" : "em ${m}min";
  }

  int get totalDosesHoje {
    if (intervaloDias > 0) {
      final hoje = DateTime.now();
      if (dataInicio == null) return 0;
      final diasDesdeInicio = hoje.difference(dataInicio!).inDays;
      return (diasDesdeInicio % intervaloDias == 0) ? 1 : 0;
    }

    if (intervaloHoras <= 0) return 1;
    if (intervaloHoras > 24) return 1;
    return (24 / intervaloHoras).floor();
  }

  int get dosesTomadasHoje {
    final hoje = DateTime.now();

    return historico.where((r) =>
    r.tomado &&
        r.dataHora.year == hoje.year &&
        r.dataHora.month == hoje.month &&
        r.dataHora.day == hoje.day
    ).length;
  }

  double get progressoHoje {
    if (totalDosesHoje == 0) return 0.0;
    return dosesTomadasHoje / totalDosesHoje;
  }

  int get dosesRestantes {
    if (comprimidosPorDose == 0) return 0;
    return (quantidadeRestante / comprimidosPorDose).floor();
  }

  bool get podeTomarAgora {
    if (intervaloDias > 0) {
      final hoje = DateTime.now();
      if (dataInicio == null) return false;
      final diasDesdeInicio = hoje.difference(dataInicio!).inDays;
      if (diasDesdeInicio % intervaloDias != 0) return false;
    }

    if (controlarEstoque && quantidadeRestante < comprimidosPorDose) {
      return false;
    }
    if (dosesTomadasHoje >= totalDosesHoje) return false;

    final agora = DateTime.now();

    //Caso intervalo
    if (intervaloHoras > 0) {
      if (historico.isEmpty) return true;

      final ultima = historico.where((r) => r.tomado).map((r) => r.dataHora)
          .fold<DateTime?>(null, (prev, e) => prev == null || e.isAfter(prev) ? e : prev);

      if (ultima == null) return true;

      final proxima = ultima.add(Duration(hours: intervaloHoras));
      return agora.isAfter(proxima.subtract(Duration(hours: 2)));
    }

    //Caso horário fixo
    try {
      final partes = horario.split(":");
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);

      final hoje = DateTime.now();

      final horarioHoje = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
        hora,
        minuto,
      );

      final inicioJanela = horarioHoje.subtract(Duration(hours: 2));
      final fimJanela = horarioHoje.add(Duration(hours: 4));

      return agora.isAfter(inicioJanela) && agora.isBefore(fimJanela);
    } catch (_) {
      return false;
    }
  }


  String get statusTempo {
    final proxima= proximaDose;
    if (proxima == null) return "Tratamento finalizado";

    final agora = DateTime.now();
    final diff = proxima.difference(agora);

    if (diff.inMinutes.abs() <= 30) {
      if (diff.isNegative) {
        return "Atrasado ${diff.inMinutes.abs()} min";
      } else {
        return "Horário próximo";
      }
    }

    if (diff.isNegative) {
      return "Atrasado ${diff.inHours.abs()}h";
    }

    return "Falta ${diff.inHours}h ${diff.inMinutes % 60}m";
  }


  Color get corStatus {
    switch (statusHoje) {
      case 'pendente':
        return Colors.orange;
      case 'tomado':
        return Colors.green;
      case 'pulou':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }



}