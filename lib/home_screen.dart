import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_medicamento_screen.dart';
import 'medicamento_provider.dart';
import 'medicamento.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'presentation/pages/gamification_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MedicamentoProvider>(context, listen: false)
            .verificarMudancaDeDia();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _mostrarDialogReabastecer(
    BuildContext context,
    MedicamentoProvider provider,
    Medicamento med,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryBlue, size: 28),
            const SizedBox(width: 10),
            const Expanded(child: Text("Reabastecer estoque")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              med.nome,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: "Quantos comprimidos?",
                suffixText: "comp.",
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final quantidade = int.tryParse(controller.text) ?? 0;
              if (quantidade > 0) {
                provider.reabastecerMedicamento(med, quantidade);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text("Estoque atualizado! +$quantidade comprimidos",
                            style: const TextStyle(fontSize: 17)),
                      ],
                    ),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              minimumSize: const Size(120, 52),
            ),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  Future<void> _animarETomar(int index, MedicamentoProvider provider) async {
    final conquistas = await provider.marcarStatus(index, true);
    _confettiController.play();

    final messages = [
      "Parabéns por cuidar da sua saúde!",
      "Continue assim! Você está ótimo!",
      "Muito bem, medicação em dia!",
      "Saúde em primeiro lugar!",
      "Perfeito! Você está no caminho certo!",
    ];
    messages.shuffle();

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messages.first,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    if (conquistas.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        _mostrarDialogConquistas(conquistas, provider);
      });
    }
  }

  void _mostrarDialogConquistas(
      List<String> conquistas, MedicamentoProvider provider) {
    List<Widget> itens = [];

    _addConquista(itens, conquistas, 'level_up',
        'Nível ${provider.nivel} Alcançado!', Icons.trending_up, AppTheme.accentBlue);
    _addConquista(itens, conquistas, 'primeira_tomada',
        'Primeira Tomada!', Icons.star_rounded, AppTheme.warningAmber);
    _addConquista(itens, conquistas, 'em_chamas',
        'Em Chamas — 3 dias!', Icons.local_fire_department_rounded, AppTheme.alertOrange);
    _addConquista(itens, conquistas, 'semana_perfeita',
        'Semana Perfeita — 7 dias!', Icons.emoji_events_rounded, Colors.purple);
    _addConquista(itens, conquistas, 'mestre_da_saude',
        'Mestre da Saúde — Nível 10!', Icons.diamond_rounded, Colors.cyan);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppTheme.warningAmber, size: 34),
            const SizedBox(width: 10),
            Text("Nova Conquista!", style: AppTheme.titleMedium),
          ],
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: itens),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GamificationScreen()));
            },
            child: const Text("Ver Progresso"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 52)),
            child: const Text("Oba! 🎉"),
          ),
        ],
      ),
    );
  }

  void _addConquista(List<Widget> list, List<String> conquistas, String id,
      String titulo, IconData icone, Color cor) {
    if (!conquistas.contains(id)) return;
    list.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: cor.withOpacity(0.18), shape: BoxShape.circle),
              child: Icon(icone, color: cor, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(titulo,
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirChatbot(BuildContext context, String nomeMedicamento) async {
    final nome = Uri.encodeComponent(nomeMedicamento);
    final Uri url = Uri.parse(
        "https://miguelbrondani.pythonanywhere.com/?medicamento=$nome");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o chatbot")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Consumer<MedicamentoProvider>(
              builder: (context, provider, child) {
                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // === HEADER GRADIENTE ===
                    SliverToBoxAdapter(
                      child: _buildHeader(provider),
                    ),

                    // === BARRA DE GAMIFICAÇÃO ===
                    if (provider.lista.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildGamificationBar(context, provider),
                      ),

                    // === LISTA DE MEDICAMENTOS ===
                    if (provider.lista.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildMedicCard(
                                context, provider, index),
                            childCount: provider.lista.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 25,
              minBlastForce: 12,
              emissionFrequency: 0.08,
              numberOfParticles: 25,
              gravity: 0.4,
              colors: const [
                AppTheme.successGreen, AppTheme.accentBlue,
                Colors.pink, AppTheme.alertOrange, Colors.purple
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMedicamentoScreen()),
        ).then((_) {
          if (context.mounted) {
            context.read<MedicamentoProvider>().carregarMedicamentos();
          }
        }),
        icon: const Icon(Icons.add_circle_outline, size: 28),
        label: const Text(
          'Adicionar Remédio',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader(MedicamentoProvider provider) {
    final agora = DateTime.now();
    final diasSemana = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final diaSemanaStr = diasSemana[agora.weekday - 1];
    final dataStr = '$diaSemanaStr, ${agora.day} de ${meses[agora.month - 1]}';

    // Contagem para progresso
    final totalHoje = provider.lista.where((m) => m.totalDosesHoje > 0).length;
    final tomadosHoje =
        provider.lista.where((m) => m.statusHoje == 'tomou').length;

    return Container(
      decoration: AppTheme.gradientHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha topo: data + botão progresso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dataStr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GamificationScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emoji_events_rounded,
                              color: Color(0xFFFFD54F), size: 22),
                          SizedBox(width: 6),
                          Text(
                            'Conquistas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Olá! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Aqui estão seus remédios de hoje',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Card de progresso do dia
              if (provider.lista.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Ícone de progresso
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: totalHoje > 0 &&
                                  tomadosHoje >= totalHoje
                              ? AppTheme.successGreen
                              : Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          totalHoje > 0 && tomadosHoje >= totalHoje
                              ? Icons.check_circle
                              : Icons.medication_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalHoje == 0
                                  ? 'Nenhum remédio hoje'
                                  : tomadosHoje >= totalHoje
                                      ? 'Todos tomados! 🎉'
                                      : '$tomadosHoje de $totalHoje tomados',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (totalHoje > 0) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: totalHoje == 0
                                      ? 0
                                      : tomadosHoje / totalHoje,
                                  minHeight: 10,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (totalHoje > 0)
                        Text(
                          '${provider.adesaoHoje.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // === BARRA DE GAMIFICAÇÃO COMPACTA ===
  Widget _buildGamificationBar(
      BuildContext context, MedicamentoProvider provider) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatChip(
              Icons.star_rounded,
              '${provider.pontos} pts',
              const Color(0xFFFFB300),
            ),
            Container(width: 1, height: 30, color: Colors.grey.shade200),
            _buildStatChip(
              Icons.local_fire_department_rounded,
              '${provider.streak} dias',
              AppTheme.alertOrange,
            ),
            Container(width: 1, height: 30, color: Colors.grey.shade200),
            _buildStatChip(
              Icons.trending_up_rounded,
              'Nível ${provider.nivel}',
              AppTheme.primaryBlue,
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // === ESTADO VAZIO ===
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum remédio\ncadastrado ainda',
              textAlign: TextAlign.center,
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Toque no botão abaixo\npara adicionar seu primeiro remédio',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicamentoScreen()),
              ).then((_) {
                if (context.mounted) {
                  context.read<MedicamentoProvider>().carregarMedicamentos();
                }
              }),
              icon: const Icon(Icons.add_circle_outline, size: 26),
              label: const Text('Adicionar Remédio'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(260, 68),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === CARD DO MEDICAMENTO ===
  Widget _buildMedicCard(
      BuildContext context, MedicamentoProvider provider, int index) {
    final med = provider.lista[index];
    final bool concluido =
        med.totalDosesHoje > 0 && med.dosesTomadasHoje >= med.totalDosesHoje;
    final bool isPulado = med.statusHoje == 'pulou';
    final bool naoAgendado = med.statusHoje == 'nao_agendado';
    final bool aindaPodeTomar = med.podeTomarAgora;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (concluido) {
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Tomado';
    } else if (isPulado) {
      statusColor = AppTheme.errorRed;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Pulado';
    } else if (naoAgendado) {
      statusColor = Colors.grey;
      statusIcon = Icons.access_time_rounded;
      statusLabel = 'Não é hoje';
    } else {
      statusColor = AppTheme.alertOrange;
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Pendente';
    }

    final double progressoEstoque = med.quantidadeInicial == 0
        ? 0
        : med.quantidadeRestante / med.quantidadeInicial;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(color: statusColor, width: 7),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto ou ícone do medicamento
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: med.imagemPath != null &&
                          File(med.imagemPath!).existsSync()
                      ? Image.file(
                          File(med.imagemPath!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: statusColor.withOpacity(0.1),
                          child: Icon(
                            Icons.medication_rounded,
                            size: 44,
                            color: statusColor,
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Botão reabastecer (se controla estoque)
                          if (med.controlarEstoque)
                            GestureDetector(
                              onTap: () => _mostrarDialogReabastecer(
                                  context, provider, med),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add_box_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Nome do medicamento
                      Text(
                        med.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: AppTheme.textDark,
                          decoration: concluido
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppTheme.successGreen,
                          decorationThickness: 2,
                        ),
                      ),

                      if (med.dosagem.isNotEmpty)
                        Text(
                          med.dosagem,
                          style: AppTheme.bodyMedium,
                        ),

                      const SizedBox(height: 6),

                      // Horário
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppTheme.accentBlue, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            med.horario,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Status de tempo
                      Row(
                        children: [
                          Icon(
                            concluido
                                ? Icons.check_circle_outline
                                : Icons.hourglass_top_rounded,
                            size: 18,
                            color: med.corStatus,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              med.statusTempo,
                              style: TextStyle(
                                color: med.corStatus,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress de doses (se tiver múltiplas doses)
          if (med.totalDosesHoje > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Tomados hoje: ${med.dosesTomadasHoje} de ${med.totalDosesHoje}',
                    style: TextStyle(
                      color: concluido
                          ? AppTheme.successGreen
                          : AppTheme.alertOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: med.progressoHoje,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    concluido ? AppTheme.successGreen : AppTheme.alertOrange,
                  ),
                ),
              ),
            ),
          ],

          // Estoque
          if (med.controlarEstoque) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        med.estoqueBaixo
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        size: 18,
                        color: med.estoqueBaixo
                            ? AppTheme.errorRed
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        med.estoqueBaixo
                            ? 'Poucos comprimidos! (${med.quantidadeRestante} restantes)'
                            : 'Estoque: ${med.quantidadeRestante} comprimidos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: med.estoqueBaixo
                              ? AppTheme.errorRed
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressoEstoque.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressoEstoque > 0.5
                            ? AppTheme.successGreen
                            : progressoEstoque > 0.2
                                ? AppTheme.alertOrange
                                : AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Próxima dose
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 17, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Próxima dose: ${med.proximaDoseRestante}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Divisor
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // === BOTÕES DE AÇÃO ===
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                // Botão principal — JÁ TOMEI!
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: aindaPodeTomar
                        ? () => _animarETomar(index, provider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          aindaPodeTomar ? AppTheme.successGreen : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 64),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 28),
                    label: Text(
                      concluido ? 'JÁ FOI TOMADO ✓' : 'JÁ TOMEI!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Botões secundários
                Row(
                  children: [
                    // Pular
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => provider.marcarStatus(index, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.alertOrange,
                          side: const BorderSide(
                              color: AppTheme.alertOrange, width: 2),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.skip_next_rounded, size: 22),
                        label: const Text(
                          'Pular',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Editar
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMedicamentoScreen(
                                medicamentoParaEditar: med),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<MedicamentoProvider>().carregarMedicamentos();
                          }
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(
                              color: AppTheme.primaryBlue, width: 2),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 22),
                        label: const Text(
                          'Editar',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Botões terciários: Excluir + Onde comprar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmarExcluir(context, provider, index),
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorRed, size: 22),
                      label: const Text(
                        'Excluir',
                        style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _abrirChatbot(context, med.nome),
                      icon: const Icon(Icons.search_rounded,
                          color: AppTheme.accentBlue, size: 22),
                      label: const Text(
                        'Onde encontrar?',
                        style: TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExcluir(
      BuildContext context, MedicamentoProvider provider, int index) async {
    final med = provider.lista[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 30),
            const SizedBox(width: 10),
            const Expanded(child: Text("Excluir remédio")),
          ],
        ),
        content: Text(
          'Tem certeza que deseja remover "${med.nome}" da sua lista?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar",
                style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              minimumSize: const Size(100, 52),
            ),
            child: const Text("Excluir",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      provider.removerMedicamento(index);
    }
  }
}