import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_medicamento_screen.dart';
import 'medicamento_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          'Meus Medicamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<MedicamentoProvider>(
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Adesão de Hoje",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${provider.adesaoHoje.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: provider.adesaoHoje < 50 ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: provider.adesaoHoje / 100,
                          ),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 12,
                                backgroundColor: Colors.grey[200],
                                color: provider.adesaoHoje < 50
                                    ? Colors.red
                                    : provider.adesaoHoje < 80
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            );
                          },
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
                    final bool concluido = med.dosesTomadasHoje >= med.totalDosesHoje;
                    final bool isPulado = med.statusHoje == 'pulou';
                    final bool aindaPodeTomar = med.podeTomarAgora;
                    final double progressoEstoque = med.quantidadeInicial == 0
                        ? 0
                        : med.quantidadeRestante / med.quantidadeInicial;

                    return Dismissible(
                      key: ValueKey(med.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Excluir medicamento"),
                            content: const Text("Tem certeza que deseja remover este medicamento?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Excluir"),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => provider.removerMedicamento(index),
                      child: AnimatedContainer(
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
                                    med.imagemPath != null
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
                                              fontSize: 20, // ✅ Nome um pouco maior
                                              decoration: med.progressoHoje == 1
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            'Horário: ${med.horario}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                                            Text(
                                              "Tomado: ${med.dosesTomadasHoje}/${med.totalDosesHoje}",
                                              style: TextStyle(
                                                color: med.progressoHoje == 1
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                          const SizedBox(height: 12),

                                          const SizedBox(height: 12),

                                          // ✅ SEÇÃO DE BOTÕES ATUALIZADA
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: aindaPodeTomar
                                                      ? () => provider.marcarStatus(index, true)
                                                      : null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                  ),
                                                  child: const Text(
                                                    "TOMAR",
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () => provider.marcarStatus(index, false),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                  ),
                                                  child: const Text(
                                                    "PULAR",
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 6),

                                              IconButton(
                                                icon: const Icon(Icons.edit_note, size: 28),
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AddMedicamentoScreen(
                                                      medicamentoParaEditar: med,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          Center(
                                            child: TextButton.icon(
                                              onPressed: () => abrirChatbot(context, med.nome),
                                              icon: const Icon(Icons.location_on, color: Colors.blue),
                                              label: const Text(
                                                "Encontre o medicamento aqui!",
                                                style: TextStyle(fontWeight: FontWeight.w600),
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
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueGrey, size: 24),
                                    tooltip: "Adicionar comprimidos",
                                    onPressed: () => _mostrarDialogReabastecer(context, provider, med),
                                  ),
                                ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddMedicamentoScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo Remédio'),
      ),
    );
  }
}