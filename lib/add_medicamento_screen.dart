import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'medicamento.dart';
import 'medicamento_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _usoContinuo = true;
  DateTime? _dataInicio;
  DateTime? _dataFim;

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
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() => _imagemSelecionada = File(imagem.path));
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
      appBar: AppBar(title: Text(isEditing ? 'Editar Remédio' : 'Novo Remédio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nomeController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Nome do remédio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _dosagemController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Dosagem (ex: 1 comprimido)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),
            const Text("Tipo de tratamento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Contínuo"),
                    value: true,
                    groupValue: _usoContinuo,
                    onChanged: (val) => setState(() => _usoContinuo = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Temporário"),
                    value: false,
                    groupValue: _usoContinuo,
                    onChanged: (val) => setState(() => _usoContinuo = val!),
                  ),
                ),
              ],
            ),

            DropdownButtonFormField<String>(
              value: _tipoAgendamento,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: "horario", child: Text("Horário específico")),
                DropdownMenuItem(value: "intervalo_horas", child: Text("Intervalo em horas")),
                DropdownMenuItem(value: "intervalo_dias", child: Text("Intervalo em dias")),
                DropdownMenuItem(value: "data_especifica", child: Text("Data específica")),
              ],
              onChanged: (value) => setState(() => _tipoAgendamento = value!),
            ),

            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDedcoratio(labelText: "Intervalo em dias"),
              inChanged: (v) {
                _intervaloDias = int.tryParse(v) ?? 0;
              },
            ),

            OutlineButton(
              onPressed: () async {
                final data = await showDatePicker(
                  context: xontext,
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
              child: Text(
                _proximaDataEspecifica == null
                ? "Selecionar data"
                : "${_proximaDataEspecifica!.day}/${_proximaDataEspecifica!.month}/${_proximaDataEspecifica!.year}",
              )
            ),

            const SizedBox(height: 15),
            const Text("Frequência", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _intervaloHoras,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text("Horário específico")),
                DropdownMenuItem(value: 4, child: Text("A cada 4 horas")),
                DropdownMenuItem(value: 6, child: Text("A cada 6 horas")),
                DropdownMenuItem(value: 8, child: Text("A cada 8 horas")),
                DropdownMenuItem(value: 12, child: Text("A cada 12 horas")),
              ],
              onChanged: (value) => setState(() => _intervaloHoras = value!),
            ),

            const SizedBox(height: 15),
            TextField(
              controller: _intervaloDiasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Intervalo em dias (opcional)",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _intervaloDias = int.tryParse(value) ?? 0);
              },
            ),

            const SizedBox(height: 20),
            // Horário e Dias só aparecem se for "Horário Específico"
            if (_intervaloHoras == 0) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selecionarHora,
                  icon: const Icon(Icons.access_time),
                  label: Text(_horarioSelecionado == null
                      ? 'Escolher horário'
                      : 'Horário: ${_horarioSelecionado!.format(context)}'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
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
            // Seletor de Datas
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selecionarDataInicio,
                    child: Text(_dataInicio == null
                        ? "Data Início"
                        : "${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}"),
                  ),
                ),
                if (!_usoContinuo) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selecionarDataFim,
                      child: Text(_dataFim == null
                          ? "Data Fim"
                          : "${_dataFim!.day}/${_dataFim!.month}"),
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
                child: _imagemSelecionada != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                    Text("Adicionar foto do remédio"),
                  ],
                ),
              ),
            ),

            SwitchListTile(
              title: Text("Controlar estoque"),
              value: controlarEstoque,
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
                decoration: InputDecoration(labelText: 'Quantidade inicial'),
              ),
              TextField(
                controller: doseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Comprimidos por dose'),
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _salvarMedicamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SALVAR REMÉDIO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    if (_horarioSelecionado == null && _intervaloHoras == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um horário")));
      return;
    }
    if (_intervaloHoras == 0 && diasSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione pelo menos um dia da semana")),
      );
      return;
    }

    final horaFormatada = _horarioSelecionado != null
        ? "${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}"
        : "${TimeOfDay.now().hour}:${TimeOfDay.now().minute}";

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
      );
    }

    if (mounted) Navigator.pop(context);

  }
}