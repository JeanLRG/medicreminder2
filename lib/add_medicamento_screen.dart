import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'medicamento.dart';
import 'medicamento_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class AddMedicamentoScreen extends StatefulWidget {
  final Medicamento? medicamentoParaEditar;

  const AddMedicamentoScreen({super.key, this.medicamentoParaEditar});

  @override
  State<AddMedicamentoScreen> createState() => _AddMedicamentoScreenState();
}

class _AddMedicamentoScreenState extends State<AddMedicamentoScreen> {
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();

  bool controlarEstoque = false;

  final quantidadeController = TextEditingController();
  final doseController = TextEditingController(text: "1");
  final _intervaloDiasController = TextEditingController();

  TimeOfDay? _horarioSelecionado;
  List<int> diasSelecionados = [];
  final List<String> nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  File? _imagemSelecionada;
  final ImagePicker _picker = ImagePicker();

  int _intervaloHoras = 0; // 0 é horário fixo
  int _intervaloDias = 0;
  String _tipoAgendamento = "horario";
  bool _usoContinuo = true;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  DateTime? _proximaDataEspecifica;

  bool get isEditing => widget.medicamentoParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final med = widget.medicamentoParaEditar!;
      _nomeController.text = med.nome;
      _dosagemController.text = med.dosagem;
      diasSelecionados = List.from(med.diasDaSemana);

      final partes = med.horario.split(':');
      _horarioSelecionado = TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      );

      if (med.imagemPath != null) {
        _imagemSelecionada = File(med.imagemPath!);
      }
      
      _usoContinuo = med.usoContinuo;
      _intervaloHoras = med.intervaloHoras;
      _intervaloDias = med.intervaloDias;
      _tipoAgendamento = med.tipoAgendamento;

      if (_intervaloHoras > 0 && _tipoAgendamento == "horario") {
        _tipoAgendamento = "intervalo_horas";
      } else if (_intervaloDias > 0 && _tipoAgendamento == "horario") {
        _tipoAgendamento = "intervalo_dias";
      } else if (med.proximaDataEspecifica != null && _tipoAgendamento == "horario") {
        _tipoAgendamento = "data_especifica";
      }

      _proximaDataEspecifica = med.proximaDataEspecifica;
      if (_intervaloDias > 0) {
        _intervaloDiasController.text = _intervaloDias.toString();
      }

      _dataInicio = med.dataInicio;
      _dataFim = med.dataFim;

      controlarEstoque = med.controlarEstoque;
      quantidadeController.text = med.quantidadeInicial.toString();
      doseController.text = med.comprimidosPorDose.toString();
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? novoHorario = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado ?? TimeOfDay.now(),
    );
    if (novoHorario != null) {
      setState(() => _horarioSelecionado = novoHorario);
    }
  }

  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataInicio = data);
  }

  Future<void> _selecionarDataFim() async {
    if (_dataInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data de início primeiro")),
      );
      return;
    }
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio!.add(const Duration(days: 1)),
      firstDate: _dataInicio!,
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataFim = data);
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
      if (imagem != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}_${imagem.name}';
        final String novoCaminho = '${directory.path}/$nomeArquivo';
        
        await imagem.saveTo(novoCaminho);
        
        setState(() => _imagemSelecionada = File(novoCaminho));
      }
    } catch (e) {
      debugPrint("Erro ao selecionar/salvar imagem: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao carregar a imagem. Tente outra foto.")),
        );
      }
    }
  }

  void _toggleDia(int index) {
    setState(() {
      final dia = index + 1;
      if (diasSelecionados.contains(dia)) {
        diasSelecionados.remove(dia);
      } else {
        diasSelecionados.add(dia);
      }
    });
  }

  Future<void> abrirChatbot(String nomeMedicamento) async {
    final Uri url = Uri.parse(
      "https://miguelbrondani.pythonanywhere.com/?medicamento=$nomeMedicamento",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o chatbot');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '✏️ Editar Remédio 💊' : '➕ Adicionar Remédio 💊',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nomeController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: '💊 Nome do remédio',
                labelStyle: TextStyle(fontSize: 20),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dosagemController,
              style: const TextStyle(fontSize: 22),
              decoration: const InputDecoration(
                labelText: '⚖️ Qual a quantidade? (ex: 1 comprimido)',
                labelStyle: TextStyle(fontSize: 18),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),
            const Text("📅 Como você vai tomar?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Vou tomar para sempre", style: TextStyle(fontSize: 18)),
                    value: true,
                    groupValue: _usoContinuo,
                    onChanged: (val) => setState(() => _usoContinuo = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Tem dia para acabar", style: TextStyle(fontSize: 18)),
                    value: false,
                    groupValue: _usoContinuo,
                    onChanged: (val) => setState(() => _usoContinuo = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _tipoAgendamento,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 18, color: Colors.black),
              items: const [
                DropdownMenuItem(value: "horario", child: Text("Horário específico (ex: 08:00)")),
                DropdownMenuItem(value: "intervalo_horas", child: Text("Intervalo em horas (ex: de 8h em 8h)")),
                DropdownMenuItem(value: "intervalo_dias", child: Text("Intervalo em dias (ex: a cada 2 dias)")),
                DropdownMenuItem(value: "data_especifica", child: Text("Data específica")),
              ],
              onChanged: (value) => setState(() => _tipoAgendamento = value!),
            ),

            if (_tipoAgendamento == "data_especifica") ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2100),
                    );

                    if (data != null) {
                      setState(() {
                        _proximaDataEspecifica = data;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _proximaDataEspecifica == null
                    ? "📅 Selecionar data"
                    : "📅 Data: ${_proximaDataEspecifica!.day.toString().padLeft(2, '0')}/${_proximaDataEspecifica!.month.toString().padLeft(2, '0')}/${_proximaDataEspecifica!.year}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ],

            if (_tipoAgendamento == "intervalo_horas") ...[
              const SizedBox(height: 15),
              const Text("⏳ De quantas em quantas horas?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _intervaloHoras == 0 ? 8 : _intervaloHoras,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 18, color: Colors.black),
                items: const [
                  DropdownMenuItem(value: 4, child: Text("A cada 4 horas")),
                  DropdownMenuItem(value: 6, child: Text("A cada 6 horas")),
                  DropdownMenuItem(value: 8, child: Text("A cada 8 horas")),
                  DropdownMenuItem(value: 12, child: Text("A cada 12 horas")),
                ],
                onChanged: (value) => setState(() => _intervaloHoras = value!),
              ),
            ],

            if (_tipoAgendamento == "intervalo_dias") ...[
              const SizedBox(height: 15),
              TextField(
                controller: _intervaloDiasController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: "📅 A cada quantos dias?",
                  labelStyle: TextStyle(fontSize: 18),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _intervaloDias = int.tryParse(value) ?? 0);
                },
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selecionarHora,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _horarioSelecionado == null
                      ? 'Escolher horário'
                      : '⏰ Horário: ${_horarioSelecionado!.format(context)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            
            if (_tipoAgendamento == "horario") ...[
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(7, (index) {
                  final dia = index + 1;
                  final selecionado = diasSelecionados.contains(dia);
                  return FilterChip(
                    label: Text(nomesDias[index]),
                    selected: selecionado,
                    onSelected: (_) => _toggleDia(index),
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: selecionado ? Colors.white : Colors.black),
                  );
                }),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selecionarDataInicio,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _dataInicio == null
                          ? "📅 Início"
                          : "${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                if (!_usoContinuo) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selecionarDataFim,
                      icon: const Icon(Icons.event_busy),
                      label: Text(
                        _dataFim == null
                            ? "📅 Fim"
                            : "${_dataFim!.day}/${_dataFim!.month}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 25),
            GestureDetector(
              onTap: _selecionarImagem,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _imagemSelecionada != null && _imagemSelecionada!.existsSync()
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.blue),
                    SizedBox(height: 10),
                    Text("📸 Tocar para adicionar foto", style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            SwitchListTile(
              title: const Text("📦 Avisar quando estiver acabando?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              value: controlarEstoque,
              activeColor: Colors.blue,
              onChanged: (v) {
                setState(() {
                  controlarEstoque = v;
                });
              },
            ),

            if (controlarEstoque) ...[
              TextField(
                controller: quantidadeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Quantos comprimidos você tem agora?',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: doseController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Quantos comprimidos vai tomar por vez?',
                  labelStyle: TextStyle(fontSize: 16),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 80, // Botão ainda maior
              child: ElevatedButton.icon(
                onPressed: _salvarMedicamento,
                icon: const Icon(Icons.save, size: 30),
                label: const Text(' SALVAR REMÉDIO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bordas um pouco mais arredondadas
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarMedicamento() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Digite o nome do remédio")));
      return;
    }
    if (_tipoAgendamento == "horario") {
      _intervaloHoras = 0;
      _intervaloDias = 0;
      _proximaDataEspecifica = null;
    } else if (_tipoAgendamento == "intervalo_horas") {
      _intervaloDias = 0;
      _proximaDataEspecifica = null;
      if (_intervaloHoras == 0) _intervaloHoras = 8;
    } else if (_tipoAgendamento == "intervalo_dias") {
      _intervaloHoras = 0;
      _proximaDataEspecifica = null;
    } else if (_tipoAgendamento == "data_especifica") {
      _intervaloHoras = 0;
      _intervaloDias = 0;
      if (_proximaDataEspecifica != null) {
        diasSelecionados = [_proximaDataEspecifica!.weekday];
      }
    }

    if (_horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um horário")));
      return;
    }
    
    if (_tipoAgendamento == "horario" && diasSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione pelo menos um dia da semana")),
      );
      return;
    }
    
    if (_tipoAgendamento == "data_especifica" && _proximaDataEspecifica == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data específica")),
      );
      return;
    }
    
    if (_tipoAgendamento == "intervalo_dias" && _intervaloDias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe a cada quantos dias tomará o remédio")),
      );
      return;
    }

    final horaFormatada = "${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}";

    final provider = context.read<MedicamentoProvider>();

    if (!_usoContinuo && _dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data de fim")),
      );
      return;
    }

    if (isEditing) {
      final med = widget.medicamentoParaEditar!;
      med.nome = _nomeController.text;
      med.dosagem = _dosagemController.text;
      med.horario = horaFormatada;
      med.diasDaSemana = diasSelecionados;
      med.imagemPath = _imagemSelecionada?.path;
      med.intervaloHoras = _intervaloHoras;
      med.intervaloDias = _intervaloDias;
      med.usoContinuo = _usoContinuo;
      med.dataInicio = _dataInicio;
      med.dataFim = _dataFim;
      med.controlarEstoque = controlarEstoque;
      med.quantidadeInicial = int.tryParse(quantidadeController.text) ?? 0;
      med.comprimidosPorDose = int.tryParse(doseController.text) ?? 1;
      med.tipoAgendamento = _tipoAgendamento;
      med.proximaDataEspecifica = _proximaDataEspecifica;
      await provider.editarMedicamento(med);
    } else {
      await provider.adicionarNovo(
        _nomeController.text,
        horaFormatada,
        diasSelecionados,
        _dosagemController.text,
        imagemPath: _imagemSelecionada?.path,
        intervaloHoras: _intervaloHoras,
        intervaloDias: _intervaloDias,
        usoContinuo: _usoContinuo,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        controlarEstoque: controlarEstoque,
        comprimidosPorDose: int.tryParse(doseController.text) ?? 1,
        quantidadeInicial: int.tryParse(quantidadeController.text) ?? 0,
        tipoAgendamento: _tipoAgendamento,
        proximaDataEspecifica: _proximaDataEspecifica,
      );
    }

    if (mounted) Navigator.pop(context);

  }
}