import 'package:flutter_test/flutter_test.dart';

// Importe o seu arquivo medicamento.dart (ajuste o caminho se necessário)
import '../lib/medicamento.dart';
import '../lib/registro_tomada.dart';

void main() {
  // O 'group' serve para organizar testes que falam sobre o mesmo assunto
  group('Lógica de Doses Diárias (totalDosesHoje)', () {
    //CRIA UM MEDICAMENTO FAKE PARA TESTAR A FUNCAO TOTALDOSESHOJE
    //DEFINE QUE O MEDICAMENTO DEVE SER TOMADO A CADA 8 HORAS
    //VERIFICA SE O SISTEMA CALCULA CORRRETAMENTE QUE 24HR/ 8 = 3 DOSES DIARIAS
    test('Deve calcular 3 doses diárias se o intervalo for de 8 horas', () {
      // 1. Preparação (Setup)
      final medicamento = Medicamento(
        id: '1',
        nome: 'Paracetamol',
        horario: '08:00',
        quantidadeRestante: 10,
        alertaMinimo: 2,
        alertaEstoqueEnviado: false,
        comprimidosPorDose: 1,
        controlarEstoque: false,
        quantidadeInicial: 10,
        intervaloHoras: 8, // Tomado de 8 em 8 horas
        tipoAgendamento: "intervalo_horas",
      );

      // 2. Ação e Asserção (Equivalente ao assertEquals)
      // 24 / 8 = 3 doses por dia
      expect(medicamento.totalDosesHoje, equals(3));
    });

  //DEFINE QUE DEVE SER APENAS DOSE POR DIA intervaloHoras = 0
  //VERIFICAR SE O SISTEMA ENTENDE QUE  intervaloHoras = 0 SIGNIFICA 1 DOSE DIARIA
    test('Deve retornar 1 dose diária se for horário fixo (intervalo 0)', () {
      final medicamento = Medicamento(
        id: '2',
        nome: 'Vitamina C',
        horario: '08:00',
        quantidadeRestante: 10,
        alertaMinimo: 2,
        alertaEstoqueEnviado: false,
        comprimidosPorDose: 1,
        controlarEstoque: false,
        quantidadeInicial: 10,
        intervaloHoras: 0, // Horário fixo
      );

      // Apenas 1 dose no dia
      expect(medicamento.totalDosesHoje, equals(1));
    });
  });

//Se o usuário  quiser controlar o estoque, 
//envie avisos de que o remedio ta acabando
  group('Controle de Estoque (estoqueBaixo e dosesRestantes)', () {
    test(
        'Deve retornar true (estoque baixo) quando doses restantes forem <= alerta minimo',
        () {
      final medicamento = Medicamento(
        id: '3',
        nome: 'Aspirina',
        horario: '10:00',
        quantidadeRestante: 4, // 4 comprimidos sobrando no frasco
        comprimidosPorDose: 2, // Toma 2 por vez (logo, restam 2 doses)
        alertaMinimo: 2, // Alerta dispara quando restar 2 doses ou menos
        controlarEstoque: true, // Controle ativado
        alertaEstoqueEnviado: false,
        quantidadeInicial: 20,
      );

      // Equivalente ao assertTrue
      expect(medicamento.estoqueBaixo, isTrue);
    });

//garantir que o aplicativo obedece quando o usuário diz 
//"não quero controlar o estoque deste remédio".
    test(
        'Deve retornar false para estoque baixo se o controle de estoque estiver desativado',
        () {
      final medicamento = Medicamento(
        id: '4',
        nome: 'Aspirina',
        horario: '10:00',
        quantidadeRestante: 4,
        comprimidosPorDose: 2,
        alertaMinimo: 2,//dose acabando
        controlarEstoque: false, // Controle DESATIVADO
        alertaEstoqueEnviado: false,
        quantidadeInicial: 20,
      );

      // Mesmo com poucos comprimidos, a flag deve impedir o aviso (Equivalente ao assertFalse)
      expect(medicamento.estoqueBaixo, isFalse);
    });
  });

//simula um erro  onde o usuário cadastra que precisa tomar 0 comprimidos por dose
//evita divisao por zerpo
  group('Prevenção de Erros (Casos Extremos)', () {
    test('Deve evitar divisão por zero no cálculo de doses restantes', () {
      final medicamento = Medicamento(
        id: '5',
        nome: 'Remédio Teste',
        horario: '12:00',
        quantidadeRestante: 10,
        comprimidosPorDose: 0, // ERRO DO USUÁRIO: cadastrou 0 por acidente
        alertaMinimo: 2,
        controlarEstoque: true,
        alertaEstoqueEnviado: false,
        quantidadeInicial: 10,
      );

      // Se a proteção if (comprimidosPorDose == 0) não existisse na classe,
      // o teste falharia lançando uma exceção de divisão por zero.
      expect(medicamento.dosesRestantes, equals(0));
    });
  });

  // Verifica se o progresso diário e o status do medicamento estão corretos
  group('Progresso e Status Diário', () {
    test('Deve calcular corretamente as doses tomadas hoje e o progresso', () {
      final hoje = DateTime.now();
      final medicamento = Medicamento(
        id: '6',
        nome: 'Vitamina D',
        horario: '10:00',
        quantidadeRestante: 30,
        alertaMinimo: 5,
        alertaEstoqueEnviado: false,
        comprimidosPorDose: 1,
        controlarEstoque: false,
        quantidadeInicial: 30,
        intervaloHoras: 12, // 2 doses diárias
        tipoAgendamento: "intervalo_horas",
        historico: [
          RegistroTomada(dataHora: hoje, tomado: true), // 1 dose tomada hoje
        ],
      );

      expect(medicamento.totalDosesHoje, equals(2));
      expect(medicamento.dosesTomadasHoje, equals(1));
      expect(medicamento.progressoHoje, equals(0.5)); // 1/2 = 50%
      expect(medicamento.statusHoje, equals('pendente')); // Ainda falta 1
    });

    test('Deve retornar status "tomou" quando todas as doses do dia forem tomadas', () {
      final hoje = DateTime.now();
      final medicamento = Medicamento(
        id: '7',
        nome: 'Antibiótico',
        horario: '08:00',
        quantidadeRestante: 20,
        alertaMinimo: 5,
        alertaEstoqueEnviado: false,
        comprimidosPorDose: 1,
        controlarEstoque: false,
        quantidadeInicial: 20,
        intervaloHoras: 12, // 2 doses diárias
        tipoAgendamento: "intervalo_horas",
        historico: [
          RegistroTomada(dataHora: DateTime(hoje.year, hoje.month, hoje.day, 1, 0), tomado: true),
          RegistroTomada(dataHora: DateTime(hoje.year, hoje.month, hoje.day, 13, 0), tomado: true),
        ],
      );

      expect(medicamento.statusHoje, equals('tomou'));
    });
  });

  // Testa as formatações de tempo e cálculo de se dá para tomar agora
  group('Lógica de proximaDoseRestante e statusTempo', () {
    test('Deve retornar "Finalizado" se não há próxima dose (dataFim já passou)', () {
      final medicamento = Medicamento(
        id: '9',
        nome: 'Remédio Antigo',
        horario: '10:00',
        quantidadeRestante: 10,
        alertaMinimo: 2,
        alertaEstoqueEnviado: false,
        comprimidosPorDose: 1,
        controlarEstoque: false,
        quantidadeInicial: 10,
        intervaloHoras: 0,
        dataFim: DateTime.now().subtract(const Duration(days: 1)), // Terminou ontem
      );

      expect(medicamento.proximaDoseRestante, equals("Finalizado"));
    });
  });

  group('Lógica de podeTomarAgora', () {
    test('Deve retornar false se o estoque acabou e controla estoque está ativado', () {
      final medicamento = Medicamento(
        id: '10',
        nome: 'Paracetamol',
        horario: '08:00',
        quantidadeRestante: 0, // Sem estoque
        comprimidosPorDose: 1,
        alertaMinimo: 2,
        alertaEstoqueEnviado: false,
        controlarEstoque: true, // Controle Ativado
        quantidadeInicial: 10,
      );

      expect(medicamento.podeTomarAgora, isFalse);
    });

    test('Deve retornar false se já tomou todas as doses do dia', () {
      final hoje = DateTime.now();
      final medicamento = Medicamento(
        id: '11',
        nome: 'Vitamina',
        horario: '08:00',
        quantidadeRestante: 10,
        comprimidosPorDose: 1,
        alertaMinimo: 2,
        alertaEstoqueEnviado: false,
        controlarEstoque: false,
        quantidadeInicial: 10,
        intervaloHoras: 0, // 1 dose por dia
        historico: [
           RegistroTomada(dataHora: hoje, tomado: true),
        ]
      );

      expect(medicamento.podeTomarAgora, isFalse);
    });
  });

  group('Lógica de Intervalo de Dias e Horário', () {
    test('Deve aplicar o horário cadastrado para a data de início (futura)', () {
      final inicioFuturo = DateTime.now().add(const Duration(days: 2));
      final medicamento = Medicamento(
        id: '12',
        nome: 'Remédio Intervalo Dias',
        horario: '12:00',
        quantidadeRestante: 10,
        alertaMinimo: 2,
        alertaEstoqueEnviado: false,
        comprimidosPorDose: 1,
        controlarEstoque: false,
        quantidadeInicial: 10,
        intervaloDias: 2,
        tipoAgendamento: 'intervalo_dias',
        dataInicio: DateTime(inicioFuturo.year, inicioFuturo.month, inicioFuturo.day), // 00:00:00
      );

      final proxima = medicamento.proximaDose;
      expect(proxima, isNotNull);
      expect(proxima!.hour, equals(12));
      expect(proxima.minute, equals(0));
    });
  });
}
