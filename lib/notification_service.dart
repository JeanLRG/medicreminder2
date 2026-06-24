import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  // Instância única (Singleton) para garantir que não criamos vários gestores
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // 1. Configurar Fusos Horários (Brasil)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    if (Platform.isAndroid) {
      final androidImplementation = notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();

      // Pede permissão para notificações e alarmes exatos
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }

    // 2. Configurar o Ícone (ic_launcher é o padrão gerado pelo plugin)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // 3. Inicializar o Plugin
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Usuário clicou na notificação: ${details.payload}");
      },
    );

    // 4. Criar Canal de Notificação (Obrigatório para Android 8.0+)
    if (Platform.isAndroid) {
      // Acessa a implementação específica do Android corretamente
      final androidPlugin = notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // Na versão 17+, o método correto é requestNotificationsPermission
      // ou requestPermission dependendo do exato sub-pacote, mas o padrão atual é:
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<void> notificarAteResponder({
    required int id,
    required String titulo,
    required String corpo,
    int intervaloMinutos = 5,
  }) async {
    await notificationsPlugin.zonedSchedule( // Corrigido de _notifications para notificationsPlugin
      id,
      titulo,
      corpo,
      tz.TZDateTime.now(tz.local).add(Duration(minutes: intervaloMinutos)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lembrete_persistente',
          'Lembretes Persistentes',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Adicionado
      matchDateTimeComponents: null,
    );
  }

  Future<void> notificarEstoqueBaixo(String nome) async {
    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/1000,
      "Estoque baixo",
      "Medicamento $nome está acabando",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'estoque_channel',
          'Avisos de Estoque',
          importance: Importance.max,
          priority: Priority.high,
        )
      )
    );
  }


  Future<void> agendarMedicamento({
    required String id,
    required String nome,
    required String horario,

    // 🔵 Modo Intervalo
    int? intervaloHoras,
    int? intervaloDias,
    String tipoAgendamento = "horario",
    DateTime? proximaDataEspecifica,
    bool usoContinuo = false,
    DateTime? dataInicio,
    DateTime? dataFim,

    // 🟢 Modo Dias da Semana
    List<int>? diasDaSemana,

    // 🟣 Dados da Dose
    String dosagem = "",
    int comprimidosPorDose = 1,
  }) async {
    final partes = horario.split(':');
    final hora = int.parse(partes[0]);
    final minuto = int.parse(partes[1]);

    final textoDose = comprimidosPorDose > 1 ? "$comprimidosPorDose comprimidos" : "1 comprimido";
    final textoDosagem = dosagem.isNotEmpty ? " ($dosagem)" : "";
    final descDose = "$textoDose$textoDosagem";

    int baseId = id.hashCode.abs();

    // ==============================
    // 🟣 MODO DATA ESPECÍFICA
    // ==============================
    if (tipoAgendamento == "data_especifica" && proximaDataEspecifica != null) {
      DateTime horarioAlvo = DateTime(
        proximaDataEspecifica.year,
        proximaDataEspecifica.month,
        proximaDataEspecifica.day,
        hora,
        minuto,
      );

      if (horarioAlvo.isAfter(DateTime.now())) {
        await notificationsPlugin.zonedSchedule(
          baseId + 10000,
          'Hora do Remédio: $nome',
          'Não esqueça de tomar $descDose',
          tz.TZDateTime.from(horarioAlvo, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicamento_vfinal_channel',
              'Lembretes Críticos',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
    // ==============================
    // 🟢 MODO INTERVALO DE DIAS
    // ==============================
    else if (tipoAgendamento == "intervalo_dias" && intervaloDias != null && intervaloDias > 0) {
      DateTime inicio = dataInicio ?? DateTime.now();
      DateTime fim = usoContinuo
          ? inicio.add(const Duration(days: 90))
          : (dataFim ?? inicio.add(const Duration(days: 30)));

      DateTime horarioAtual =
          DateTime(inicio.year, inicio.month, inicio.day, hora, minuto);

      if (horarioAtual.isBefore(DateTime.now())) {
        final hoje = DateTime.now();
        final hojeApenas = DateTime(hoje.year, hoje.month, hoje.day);
        final inicioApenas = DateTime(inicio.year, inicio.month, inicio.day);
        int diasPassados = hojeApenas.difference(inicioApenas).inDays;

        if (diasPassados > 0) {
          int diasParaAdicionar = ((diasPassados ~/ intervaloDias) + 1) * intervaloDias;
          horarioAtual = DateTime(inicio.year, inicio.month, inicio.day, hora, minuto)
              .add(Duration(days: diasParaAdicionar));
        } else {
          horarioAtual = horarioAtual.add(Duration(days: intervaloDias));
        }
      }

      int contador = 0;
      const int maxNotifications = 30;

      while (horarioAtual.isBefore(fim) && contador < maxNotifications) {
        await notificationsPlugin.zonedSchedule(
          baseId + contador + 5000,
          'Hora do Remédio: $nome',
          'Não esqueça de tomar $descDose',
          tz.TZDateTime.from(horarioAtual, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicamento_vfinal_channel',
              'Lembretes Críticos',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        horarioAtual = horarioAtual.add(Duration(days: intervaloDias));
        contador++;
      }
    }
    // ==============================
    // 🔵 MODO INTERVALO DE HORAS
    // ==============================
    else if ((tipoAgendamento == "intervalo_horas" || (intervaloHoras != null && intervaloHoras > 0)) &&
        intervaloHoras != null &&
        intervaloHoras > 0) {
      DateTime inicio = dataInicio ?? DateTime.now();
      DateTime fim = usoContinuo
          ? inicio.add(const Duration(days: 30))
          : (dataFim ?? inicio.add(const Duration(days: 7)));

      DateTime horarioAtual =
          DateTime(inicio.year, inicio.month, inicio.day, hora, minuto);

      if (horarioAtual.isBefore(DateTime.now())) {
        horarioAtual = horarioAtual.add(Duration(hours: intervaloHoras));
      }

      int contador = 0;
      const int maxNotifications = 30;

      while (horarioAtual.isBefore(fim) && contador < maxNotifications) {
        await notificationsPlugin.zonedSchedule(
          baseId + contador,
          'Hora do Remédio: $nome',
          'Não esqueça de tomar $descDose',
          tz.TZDateTime.from(horarioAtual, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicamento_vfinal_channel',
              'Lembretes Críticos',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        horarioAtual = horarioAtual.add(Duration(hours: intervaloHoras));
        contador++;
      }
    }
    // ==============================
    // 🟡 MODO DIAS ESPECÍFICOS / DIÁRIO
    // ==============================
    else if (diasDaSemana != null && diasDaSemana.isNotEmpty) {
      for (int dia in diasDaSemana) {
        int idUnico = (baseId % 10000) * 10 + dia;

        await notificationsPlugin.zonedSchedule(
          idUnico,
          'É hora do seu remédio',
          '$nome\n$descDose - Agora às $horario',
          _proximoHorarioNoDia(dia, hora, minuto),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medicamento_vfinal_channel',
              'Lembretes Críticos',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      // Agendamento diário padrão
      final agora = tz.TZDateTime.now(tz.local);
      var agendado = tz.TZDateTime(tz.local, agora.year, agora.month, agora.day, hora, minuto);
      if (agendado.isBefore(agora)) {
        agendado = agendado.add(const Duration(days: 1));
      }
      await notificationsPlugin.zonedSchedule(
        baseId,
        'Hora do Remédio: $nome',
        'Não esqueça de tomar $descDose',
        agendado,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicamento_vfinal_channel',
            'Lembretes Críticos',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // Função lógica para calcular quando será o próximo dia X às Y horas
  tz.TZDateTime _proximoHorarioNoDia(int diaSemana, int hora, int minuto) {
    final agora = tz.TZDateTime.now(tz.local);
    var agendado = tz.TZDateTime(tz.local, agora.year, agora.month, agora.day, hora, minuto);

    while (agendado.weekday != diaSemana || agendado.isBefore(agora)) {
      agendado = agendado.add(const Duration(days: 1));
    }
    return agendado;
  }

  Future<void> cancelarTodasNotificacoes() async {
    await notificationsPlugin.cancelAll();
  }

  Future<void> cancelarNotificacao(int id) async {
    await notificationsPlugin.cancel(id);
  }

  Future<void> cancelarNotificacoesMedicamento(String id) async {
    int baseId = id.hashCode.abs();
    // Cancela notificações semanais
    for (int dia = 1; dia <= 7; dia++) {
      int idUnico = (baseId % 10000) * 10 + dia;
      await notificationsPlugin.cancel(idUnico);
    }
    // Cancela notificações de intervalo de horas
    for (int contador = 0; contador < 30; contador++) {
      await notificationsPlugin.cancel(baseId + contador);
    }
    // Cancela notificações de intervalo de dias
    for (int contador = 0; contador < 30; contador++) {
      await notificationsPlugin.cancel(baseId + contador + 5000);
    }
    // Cancela notificação de data específica
    await notificationsPlugin.cancel(baseId + 10000);
    // Cancela ID base
    await notificationsPlugin.cancel(baseId);
  }

  // BOTÃO DE TESTE RÁPIDO: Dispara em 5 segundos
  Future<void> testarNotificacao() async {
    await notificationsPlugin.zonedSchedule(
      999,
      'Teste de Notificação ✅',
      'Se estás a ver isto, o sistema de alertas está pronto!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicamento_vfinal_channel',
          'Lembretes Críticos',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }


}