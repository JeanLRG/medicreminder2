import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'medicamento.dart';
import 'medicamento_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'core/app_theme.dart';

class AddMedicamentoScreen extends StatefulWidget {
  final Medicamento? medicamentoParaEditar;

  const AddMedicamentoScreen({super.key, this.medicamentoParaEditar});

  @override
  State<AddMedicamentoScreen> createState() => _AddMedicamentoScreenState();
}

class _AddMedicamentoScreenState extends State<AddMedicamentoScreen> {
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _doseController = TextEditingController(text: "1");
  final _intervaloDiasController = TextEditingController();

  bool controlarEstoque = false;
  TimeOfDay? _horarioSelecionado;
  List<int> diasSelecionados = [];
  final List<String> nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  File? _imagemSelecionada;
  final ImagePicker _picker = ImagePicker();

  int _intervaloHoras = 0;
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
      } else if (med.proximaDataEspecifica != null &&
          _tipoAgendamento == "horario") {
        _tipoAgendamento = "data_especifica";
      }

      _proximaDataEspecifica = med.proximaDataEspecifica;
      if (_intervaloDias > 0) {
        _intervaloDiasController.text = _intervaloDias.toString();
      }

      _dataInicio = med.dataInicio;
      _dataFim = med.dataFim;
      controlarEstoque = med.controlarEstoque;
      _quantidadeController.text = med.quantidadeInicial.toString();
      _doseController.text = med.comprimidosPorDose.toString();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _quantidadeController.dispose();
    _doseController.dispose();
    _intervaloDiasController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? novoHorario = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado ?? TimeOfDay.now(),
    );
    if (novoHorario != null) setState(() => _horarioSelecionado = novoHorario);
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
        final String nomeArquivo =
            '${DateTime.now().millisecondsSinceEpoch}_${imagem.name}';
        final String novoCaminho = '${directory.path}/$nomeArquivo';
        await imagem.saveTo(novoCaminho);
        setState(() => _imagemSelecionada = File(novoCaminho));
      }
    } catch (e) {
      debugPrint("Erro ao selecionar/salvar imagem: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erro ao carregar a imagem. Tente outra foto.")),
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

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Remédio' : 'Adicionar Remédio',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SEÇÃO 1: Sobre o remédio ===
            _buildSectionCard(
              icon: Icons.medication_outlined,
              title: 'Sobre o remédio',
              color: AppTheme.primaryBlue,
              children: [
                // Nome
                TextField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  style: AppTheme.titleMedium,
                  decoration: const InputDecoration(
                    labelText: 'Nome do remédio',
                    prefixIcon: Icon(Icons.local_pharmacy_outlined, size: 26),
                  ),
                ),
                const SizedBox(height: 14),

                // Dosagem
                TextField(
                  controller: _dosagemController,
                  style: AppTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade por dose (ex: 1 comprimido)',
                    prefixIcon: Icon(Icons.scale_outlined, size: 26),
                  ),
                ),
                const SizedBox(height: 16),

                // Foto do medicamento
                GestureDetector(
                  onTap: _selecionarImagem,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.4),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.primaryBlue.withOpacity(0.05),
                    ),
                    child: _imagemSelecionada != null &&
                            _imagemSelecionada!.existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imagemSelecionada!,
                                fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined,
                                  size: 48, color: AppTheme.primaryBlue),
                              const SizedBox(height: 8),
                              Text(
                                'Tocar para adicionar foto',
                                style: AppTheme.bodyMedium
                                    .copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // === SEÇÃO 2: Quando tomar ===
            _buildSectionCard(
              icon: Icons.calendar_month_outlined,
              title: 'Quando tomar',
              color: AppTheme.accentBlue,
              children: [
                // Uso contínuo ou com prazo
                Text('Esse remédio tem prazo para acabar?',
                    style: AppTheme.bodyLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        label: 'Uso contínuo',
                        icon: Icons.all_inclusive_rounded,
                        selected: _usoContinuo,
                        onTap: () => setState(() => _usoContinuo = true),
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildToggleButton(
                        label: 'Tem data de fim',
                        icon: Icons.event_busy_outlined,
                        selected: !_usoContinuo,
                        onTap: () => setState(() => _usoContinuo = false),
                        color: AppTheme.alertOrange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tipo de agendamento
                Text('Como vai tomar?', style: AppTheme.bodyLarge),
                const SizedBox(height: 10),
                _buildAgendamentoSelector(),

                const SizedBox(height: 14),

                // Opções específicas por tipo
                if (_tipoAgendamento == "data_especifica") ...[
                  _buildDatePickerButton(
                    label: _proximaDataEspecifica == null
                        ? 'Selecionar data específica'
                        : 'Data: ${_formatarData(_proximaDataEspecifica!)}',
                    icon: Icons.calendar_month,
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (data != null) {
                        setState(() => _proximaDataEspecifica = data);
                      }
                    },
                    selected: _proximaDataEspecifica != null,
                  ),
                ],

                if (_tipoAgendamento == "intervalo_horas") ...[
                  Text('De quantas em quantas horas?', style: AppTheme.bodyLarge),
                  const SizedBox(height: 10),
                  _buildIntervaloHorasSelector(),
                ],

                if (_tipoAgendamento == "intervalo_dias") ...[
                  TextField(
                    controller: _intervaloDiasController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'A cada quantos dias?',
                      prefixIcon: Icon(Icons.repeat_rounded, size: 26),
                      suffixText: 'dias',
                    ),
                    onChanged: (value) =>
                        setState(() => _intervaloDias = int.tryParse(value) ?? 0),
                  ),
                ],

                const SizedBox(height: 14),

                // Horário
                _buildDatePickerButton(
                  label: _horarioSelecionado == null
                      ? 'Escolher horário'
                      : 'Horário: ${_horarioSelecionado!.format(context)}',
                  icon: Icons.access_time_rounded,
                  onTap: _selecionarHora,
                  selected: _horarioSelecionado != null,
                  color: AppTheme.accentBlue,
                ),

                // Dias da semana (somente no modo horário fixo)
                if (_tipoAgendamento == "horario") ...[
                  const SizedBox(height: 14),
                  Text('Em quais dias da semana?', style: AppTheme.bodyLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final dia = index + 1;
                      final sel = diasSelecionados.contains(dia);
                      return GestureDetector(
                        onTap: () => _toggleDia(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primaryBlue
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              nomesDias[index],
                              style: TextStyle(
                                color: sel ? Colors.white : AppTheme.textMedium,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],

                // Datas início/fim
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerButton(
                        label: _dataInicio == null
                            ? 'Data de início'
                            : 'Início: ${_formatarData(_dataInicio!)}',
                        icon: Icons.calendar_today_outlined,
                        onTap: _selecionarDataInicio,
                        selected: _dataInicio != null,
                        color: AppTheme.successGreen,
                        fullWidth: false,
                      ),
                    ),
                    if (!_usoContinuo) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDatePickerButton(
                          label: _dataFim == null
                              ? 'Data de fim'
                              : 'Fim: ${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}',
                          icon: Icons.event_busy_outlined,
                          onTap: _selecionarDataFim,
                          selected: _dataFim != null,
                          color: AppTheme.alertOrange,
                          fullWidth: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // === SEÇÃO 3: Controle de estoque ===
            _buildSectionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Controle de estoque',
              color: AppTheme.warningAmber,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Avisar quando acabar?', style: AppTheme.bodyLarge),
                          Text(
                            'Receba um alerta quando os comprimidos estiverem acabando',
                            style: AppTheme.bodyMedium
                                .copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Transform.scale(
                      scale: 1.3,
                      child: Switch(
                        value: controlarEstoque,
                        onChanged: (v) => setState(() => controlarEstoque = v),
                      ),
                    ),
                  ],
                ),

                if (controlarEstoque) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _quantidadeController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Quantos comprimidos você tem agora?',
                      prefixIcon: Icon(Icons.medication_outlined, size: 26),
                      suffixText: 'comp.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _doseController,
                    keyboardType: TextInputType.number,
                    style: AppTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Comprimidos por vez?',
                      prefixIcon: Icon(Icons.colorize_outlined, size: 26),
                      suffixText: 'por dose',
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // === BOTÃO SALVAR ===
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton.icon(
                onPressed: _salvarMedicamento,
                icon: const Icon(Icons.save_rounded, size: 30),
                label: Text(
                  isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR REMÉDIO',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da seção
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 2.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentoSelector() {
    final opcoes = [
      {
        'value': 'horario',
        'label': 'Horário fixo',
        'sub': 'Ex: todos os dias às 08:00',
        'icon': Icons.access_time_rounded
      },
      {
        'value': 'intervalo_horas',
        'label': 'A cada X horas',
        'sub': 'Ex: de 8h em 8h',
        'icon': Icons.timer_outlined
      },
      {
        'value': 'intervalo_dias',
        'label': 'A cada X dias',
        'sub': 'Ex: a cada 2 dias',
        'icon': Icons.date_range_outlined
      },
      {
        'value': 'data_especifica',
        'label': 'Data específica',
        'sub': 'Uma única data',
        'icon': Icons.event_outlined
      },
    ];

    return Column(
      children: opcoes.map((op) {
        final sel = _tipoAgendamento == op['value'];
        return GestureDetector(
          onTap: () => setState(() => _tipoAgendamento = op['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? AppTheme.accentBlue.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? AppTheme.accentBlue : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(op['icon'] as IconData,
                    color: sel ? AppTheme.accentBlue : Colors.grey,
                    size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        op['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: sel ? AppTheme.accentBlue : AppTheme.textDark,
                        ),
                      ),
                      Text(
                        op['sub'] as String,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (sel)
                  const Icon(Icons.radio_button_checked,
                      color: AppTheme.accentBlue, size: 24)
                else
                  Icon(Icons.radio_button_off,
                      color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntervaloHorasSelector() {
    final opcoes = [4, 6, 8, 12];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: opcoes.map((h) {
        final sel = (_intervaloHoras == 0 ? 8 : _intervaloHoras) == h;
        return GestureDetector(
          onTap: () => setState(() => _intervaloHoras = h),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? AppTheme.primaryBlue
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? AppTheme.primaryBlue : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              'A cada ${h}h',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: sel ? Colors.white : AppTheme.textDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool selected,
    Color color = AppTheme.primaryBlue,
    bool fullWidth = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? color : Colors.grey.shade500, size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarMedicamento() async {
    if (_nomeController.text.trim().isEmpty) {
      _showError("Digite o nome do remédio");
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
      _showError("Selecione um horário");
      return;
    }

    if (_tipoAgendamento == "horario" && diasSelecionados.isEmpty) {
      _showError("Selecione pelo menos um dia da semana");
      return;
    }

    if (_tipoAgendamento == "data_especifica" &&
        _proximaDataEspecifica == null) {
      _showError("Selecione a data específica");
      return;
    }

    if (_tipoAgendamento == "intervalo_dias" && _intervaloDias <= 0) {
      _showError("Informe a cada quantos dias tomará o remédio");
      return;
    }

    if (!_usoContinuo && _dataFim == null) {
      _showError("Selecione a data de fim do tratamento");
      return;
    }

    final horaFormatada =
        "${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}";

    final provider = context.read<MedicamentoProvider>();

    if (isEditing) {
      final med = widget.medicamentoParaEditar!;
      med.nome = _nomeController.text.trim();
      med.dosagem = _dosagemController.text.trim();
      med.horario = horaFormatada;
      med.diasDaSemana = diasSelecionados;
      med.imagemPath = _imagemSelecionada?.path;
      med.intervaloHoras = _intervaloHoras;
      med.intervaloDias = _intervaloDias;
      med.usoContinuo = _usoContinuo;
      med.dataInicio = _dataInicio;
      med.dataFim = _dataFim;
      med.controlarEstoque = controlarEstoque;
      med.quantidadeInicial =
          int.tryParse(_quantidadeController.text) ?? 0;
      med.comprimidosPorDose = int.tryParse(_doseController.text) ?? 1;
      med.tipoAgendamento = _tipoAgendamento;
      med.proximaDataEspecifica = _proximaDataEspecifica;
      await provider.editarMedicamento(med);
    } else {
      await provider.adicionarNovo(
        _nomeController.text.trim(),
        horaFormatada,
        diasSelecionados,
        _dosagemController.text.trim(),
        imagemPath: _imagemSelecionada?.path,
        intervaloHoras: _intervaloHoras,
        intervaloDias: _intervaloDias,
        usoContinuo: _usoContinuo,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        controlarEstoque: controlarEstoque,
        comprimidosPorDose: int.tryParse(_doseController.text) ?? 1,
        quantidadeInicial: int.tryParse(_quantidadeController.text) ?? 0,
        tipoAgendamento: _tipoAgendamento,
        proximaDataEspecifica: _proximaDataEspecifica,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 17))),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }
}