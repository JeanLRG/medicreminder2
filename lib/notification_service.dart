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
    // 🔵 MODO INTERVALO DE HORAS
    // ==============================
    if (intervaloHoras != null) {
      DateTime inicio = dataInicio ?? DateTime.now();

      DateTime fim = usoContinuo
          ? inicio.add(const Duration(days: 365))
          : (dataFim ?? inicio.add(const Duration(days: 7)));

      DateTime horarioAtual =
      DateTime(inicio.year, inicio.month, inicio.day, hora, minuto);

      if (horarioAtual.isBefore(DateTime.now())) {
        horarioAtual = horarioAtual.add(Duration(hours: intervaloHoras));
      }

      int contador = 0;

      while (horarioAtual.isBefore(fim)) {
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
    }
  }


  // Função lógica para calcular quando será o próximo dia X às Y horas
  tz.TZDateTime _proximoHorarioNoDia(int diaSemana, int hora, int minuto) {
    final agora = tz.TZDateTime.now(tz.local);
    var agendado = tz.TZDateTime(tz.local, agora.year, agora.month, agora.day, hora, minuto);

    // Se o horário já passou hoje, ou o dia da semana é diferente, pula para o próximo
    // Nota: weekday no timezone é 1=Segunda, 7=Domingo
    while (agendado.weekday != diaSemana || agendado.isBefore(agora)) {
      agendado = agendado.add(const Duration(days: 1));
    }
    return agendado;
  }

  Future<void> cancelarTodasNotificacoes() async {
    await notificationsPlugin.cancelAll();
  }

  Future cancelarNotificacao(int id) async {
    await notificationsPlugin.cancel(id); // Corrigido de _notifications para notificationsPlugin
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