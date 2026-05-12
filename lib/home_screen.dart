import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_medicamento_screen.dart';
import 'medicamento_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'presentation/pages/gamification_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _animarETomar(int index, MedicamentoProvider provider) async {
    final conquistas = await provider.marcarStatus(index, true);
    _confettiController.play();
    
    final messages = [
      "Parabéns por cuidar da sua saúde!",
      "Continue assim!",
      "Muito bem, medicação em dia!",
      "Saúde em primeiro lugar!",
      "Perfeito, você está no caminho certo!"
    ];
    messages.shuffle();
    
    // Esconder snackbar anterior se houver para não encavalar com os popups
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(messages.first, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (conquistas.isNotEmpty) {
      // Espera 1 segundo e meio para não fechar junto com a snackbar tão rápido
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        
        List<Widget> conquistasWidgets = [];
        
        if (conquistas.contains('level_up')) {
          conquistasWidgets.add(_buildConquistaItem('Nível ${provider.nivel} Alcançado!', Icons.trending_up, Colors.blue));
        }
        if (conquistas.contains('primeira_tomada')) {
          conquistasWidgets.add(_buildConquistaItem('1ª Tomada', Icons.star_rounded, Colors.amber));
        }
        if (conquistas.contains('em_chamas')) {
          conquistasWidgets.add(_buildConquistaItem('Em Chamas (3 dias)', Icons.local_fire_department_rounded, Colors.orange));
        }
        if (conquistas.contains('semana_perfeita')) {
          conquistasWidgets.add(_buildConquistaItem('Semana Perfeita (7 dias)', Icons.emoji_events_rounded, Colors.purple));
        }
        if (conquistas.contains('mestre_da_saude')) {
          conquistasWidgets.add(_buildConquistaItem('Mestre da Saúde (Nv. 10)', Icons.diamond_rounded, Colors.cyan));
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                SizedBox(width: 10),
                Text("Nova Conquista!"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: conquistasWidgets,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen()));
                },
                child: const Text("Ver Progresso"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Oba!"),
              ),
            ],
          ),
        );
      });
    }
  }

  Widget _buildConquistaItem(String titulo, IconData icone, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: cor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> abrirChatbot(BuildContext context, String nomeMedicamento) async {
    final nome = Uri.encodeComponent(nomeMedicamento);

    final Uri url = Uri.parse(
      "https://miguelbrondani.pythonanywhere.com/?medicamento=$nome",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o chatbot")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicamentoProvider>(context, listen: false)
          .verificarMudancaDeDia();
    });

    void _mostrarDialogReabastecer(
        BuildContext context,
        MedicamentoProvider provider,
        med,
        ) {
      final controller = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Reabastecer estoque"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantidade de comprimidos",
                suffixText: "comp.",
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantidade = int.tryParse(controller.text) ?? 0;

                  if (quantidade > 0) {
                    provider.reabastecerMedicamento(med, quantidade);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Estoque atualizado! +$quantidade comprimidos",
                        ),
                      ),
                    );
                  }

                  Navigator.pop(context);
                },
                child: const Text("Confirmar"),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '💊 Meus Medicamentos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
            tooltip: "Meu Progresso",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GamificationScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Consumer<MedicamentoProvider>(
            builder: (context, provider, child) {
          if (provider.lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum medicamento cadastrado',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("⭐ ${provider.pontos} pontos", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("🔥 ${provider.streak} dias seguidos", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          "📊 Seu Progresso Hoje",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${provider.adesaoHoje.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: provider.adesaoHoje < 50 ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              provider.adesaoHoje < 50 ? "😐" : provider.adesaoHoje < 80 ? "🙂" : "😁",
                              style: const TextStyle(fontSize: 40),
                            ),
                          ],
                        ),
                        if (provider.adesaoHoje == 100)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Parabéns! Todos tomados!",
                              style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: provider.lista.length,
                  itemBuilder: (context, index) {
                    final med = provider.lista[index];
                    final bool concluido = med.totalDosesHoje > 0 && med.dosesTomadasHoje >= med.totalDosesHoje;
                    final bool isPulado = med.statusHoje == 'pulou';
                    final bool aindaPodeTomar = med.podeTomarAgora;
                    final double progressoEstoque = med.quantidadeInicial == 0
                        ? 0
                        : med.quantidadeRestante / med.quantidadeInicial;

                    return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          elevation: 4,
                          clipBehavior: Clip.antiAlias,
                          color: concluido
                              ? Colors.green.withOpacity(0.05)
                              : isPulado
                              ? Colors.red.withOpacity(0.05)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ✅ FOTO AUMENTADA (DE 60 PARA 80)
                                    med.imagemPath != null && File(med.imagemPath!).existsSync()
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(med.imagemPath!),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : CircleAvatar(
                                      radius: 40, // ✅ Aumentado para manter proporção
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: const Icon(Icons.local_pharmacy, size: 40),
                                    ),

                                    const SizedBox(width: 16), // ✅ Espaço levemente maior

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.nome,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 26, // ✅ Nome GIGANTE
                                              decoration: med.progressoHoje == 1
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          Text(
                                            '⏰ Horário: ${med.horario}',
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                          ),

                                          if (med.controlarEstoque)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Estoque: ${med.quantidadeRestante} un.",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: med.estoqueBaixo ? Colors.red : Colors.blueGrey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: LinearProgressIndicator(
                                                      value: progressoEstoque,
                                                      minHeight: 8,
                                                      color: progressoEstoque > 0.5
                                                          ? Colors.green
                                                          : progressoEstoque > 0.2 ? Colors.orange : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          Text(
                                            med.statusTempo,
                                            style: TextStyle(
                                              color: med.corStatus,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          if (med.estoqueBaixo)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Poucos comprimidos!",
                                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          const SizedBox(height: 8),

                                          LinearProgressIndicator(
                                            value: med.progressoHoje,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(10),
                                          ),

                                          const SizedBox(height: 6),

                                          Text(
                                            "Próxima dose ${med.proximaDoseRestante ?? '--'}",
                                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                                          ),

                                          if (med.totalDosesHoje > 1 || concluido)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: concluido ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "✔️ Tomados hoje: ${med.dosesTomadasHoje} de ${med.totalDosesHoje}",
                                                style: TextStyle(
                                                  color: med.progressoHoje == 1
                                                      ? Colors.green
                                                      : Colors.orange[800],
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                          const SizedBox(height: 12),

                                          // AÇÕES DO CARD
                                          const SizedBox(height: 16),
                                          
                                          // BOTÃO PRINCIPAL (GIGANTE)
                                          SizedBox(
                                            width: double.infinity,
                                            height: 60,
                                            child: ElevatedButton.icon(
                                              onPressed: aindaPodeTomar
                                                  ? () => _animarETomar(index, provider)
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              icon: const Icon(Icons.check_circle_outline, size: 30),
                                              label: const Text(
                                                "JÁ TOMEI!",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // BOTÕES SECUNDÁRIOS
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => provider.marcarStatus(index, false),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.orange,
                                                    side: const BorderSide(color: Colors.orange, width: 2),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                  icon: const Icon(Icons.skip_next),
                                                  label: const Text(
                                                    "PULAR",
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // BOTÕES DE GERENCIAMENTO (Editar/Excluir)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AddMedicamentoScreen(
                                                      medicamentoParaEditar: med,
                                                    ),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                                label: const Text("Editar", style: TextStyle(color: Colors.blue, fontSize: 16)),
                                              ),
                                              TextButton.icon(
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text("🗑️ Excluir medicamento"),
                                                      content: const Text("Tem certeza que deseja remover este medicamento da sua lista?", style: TextStyle(fontSize: 18)),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text("Cancelar", style: TextStyle(fontSize: 18)),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: const Text("Excluir", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    provider.removerMedicamento(index);
                                                  }
                                                },
                                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                                label: const Text("Excluir", style: TextStyle(color: Colors.red, fontSize: 16)),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          Center(
                                            child: TextButton.icon(
                                              onPressed: () => abrirChatbot(context, med.nome),
                                              icon: const Icon(Icons.location_on, color: Colors.blue, size: 24),
                                              label: const Text(
                                                "📍 Onde comprar?",
                                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (med.controlarEstoque)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.add_box, color: Colors.blue, size: 36),
                                    tooltip: "Adicionar caixas",
                                    onPressed: () => _mostrarDialogReabastecer(context, provider, med),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                  },
                ),
              ),
            ],
          );
        },
      ),
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2,
          maxBlastForce: 20,
          minBlastForce: 10,
          emissionFrequency: 0.1,
          numberOfParticles: 20,
          gravity: 0.5,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ),
    ],
  ),
  floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMedicamentoScreen()),
        ),
        icon: const Icon(Icons.add_circle, size: 28),
        label: const Text('➕ Adicionar Remédio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}