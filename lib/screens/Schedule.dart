import 'package:flutter/material.dart';
import '../controllers/horario_controller.dart';
import '../models/horario_model.dart';
import '../session/session.dart';
import '../widgets/mobile_sidebar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final HorarioController _horarioController = HorarioController();
  Horario? _horario;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarHorario();
  }

  Future<void> _carregarHorario() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debug: verificar se há usuário na sessão
      if (Session.currentStudent == null) {
        print('❌ Session.currentStudent é null');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuário não está logado. Faça login novamente.';
        });
        return;
      } else {
        print('✅ Usuário na sessão: ${Session.currentStudent!.nome}');
        print('   📚 CourseId: ${Session.currentStudent!.courseId}');
        print('   📅 Year: ${Session.currentStudent!.year}');
      }

      Horario? horario = await _horarioController.buscarHorarioDoAlunoLogado();

      setState(() {
        _horario = horario;
        _isLoading = false;
        if (horario == null) {
          _errorMessage = 'Horário não encontrado para o seu curso';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar horário: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horário'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      ),
      body: _buildBody(),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando horário...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      bool isNotLoggedIn = _errorMessage!.contains('não está logado');

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isNotLoggedIn ? Icons.person_off : Icons.error,
                size: 64, color: isNotLoggedIn ? Colors.orange : Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNotLoggedIn) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text('Fazer Login'),
                  ),
                  SizedBox(width: 12),
                ],
                ElevatedButton(
                  onPressed: _carregarHorario,
                  child: Text('Tentar Novamente'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_horario == null || _horario!.aulas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma aula encontrada\npara o seu horário',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarHorario,
              child: Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildScheduleTable(),
    );
  }

  Widget _buildScheduleTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 80, child: Text('')),
              for (var day in ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'])
                SizedBox(
                  width: 120,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(width: 0.5),
                ),
                columnWidths: {
                  0: FixedColumnWidth(80),
                  for (var i = 1; i <= 5; i++) i: FixedColumnWidth(120),
                },
                children: _buildTableRows(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildTableRows() {
    List<String> timeSlots = [
      '10:00 - 11:30',
      '11:30 - 13:00',
      '13:30 - 15:00',
      '15:00 - 16:30',
      '16:30 - 18:00',
      '18:00 - 19:30',
    ];

    return timeSlots.map((timeSlot) {
      return TableRow(
        children: [
          _buildTimeCell(timeSlot),
          for (var day in ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta'])
            _buildDayCell(day, timeSlot),
        ],
      );
    }).toList();
  }

  Widget _buildTimeCell(String timeSlot) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        timeSlot,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDayCell(String day, String timeSlot) {
    if (_horario == null) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
        ),
        child: Text(''),
      );
    }

    // Converter dia da semana para o formato esperado no Firebase
    String diaFirebase = _converterDiaSemana(day);

    // Buscar aula para o dia e horário específicos
    Aula? aulaEncontrada = _horario!.aulas.firstWhere(
      (aula) =>
          aula.diaSemana == diaFirebase && _horarioCorresponde(aula, timeSlot),
      orElse: () =>
          Aula(disciplina: '', diaSemana: '', horaInicio: '', horaFim: ''),
    );

    bool temAula = aulaEncontrada.disciplina.isNotEmpty;

    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: temAula
            ? _getCorDisciplina(aulaEncontrada.disciplina)
            : Colors.transparent,
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          temAula ? aulaEncontrada.disciplina : '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: temAula ? Colors.white : Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ),
    );
  }

  // Converter nomes dos dias para o formato do Firebase
  String _converterDiaSemana(String dia) {
    switch (dia) {
      case 'Segunda':
        return 'Segunda';
      case 'Terça':
        return 'Terça';
      case 'Quarta':
        return 'Quarta';
      case 'Quinta':
        return 'Quinta';
      case 'Sexta':
        return 'Sexta';
      default:
        return dia;
    }
  }

  // Verificar se o horário da aula corresponde ao slot de tempo
  bool _horarioCorresponde(Aula aula, String timeSlot) {
    try {
      // Extrair horário de início e fim do timeSlot (ex: "10:00 - 11:30")
      List<String> parts = timeSlot.split(' - ');
      if (parts.length != 2) return false;

      String slotInicio = parts[0];
      String slotFim = parts[1];

      // Normalizar horários da aula (ex: "10:00" ou "10h00")
      String aulaInicio = _normalizarHorario(aula.horaInicio);
      String aulaFim = _normalizarHorario(aula.horaFim);

      print('🕐 Comparando horários:');
      print('   TimeSlot: $slotInicio - $slotFim');
      print(
          '   Aula: $aulaInicio - $aulaFim (original: ${aula.horaInicio} - ${aula.horaFim})');

      // Verificar se a aula se encaixa no time slot
      bool corresponde = (aulaInicio == slotInicio && aulaFim == slotFim) ||
          (aulaInicio == slotInicio) ||
          (_horarioEstaDentroDoSlot(aulaInicio, aulaFim, slotInicio, slotFim));

      if (corresponde) {
        print('   ✅ Horário corresponde!');
      }

      return corresponde;
    } catch (e) {
      print('❌ Erro ao comparar horários: $e');
      return false;
    }
  }

  // Normalizar formato de horário para "HH:MM"
  String _normalizarHorario(String horario) {
    if (horario.isEmpty) return '00:00';

    // Substituir possíveis formatos
    String normalizado =
        horario.replaceAll('h', ':').replaceAll('.', ':').replaceAll(' ', '');

    // Se não tem dois pontos, adicionar ":00"
    if (!normalizado.contains(':')) {
      normalizado = normalizado + ':00';
    }

    // Garantir formato HH:MM
    List<String> parts = normalizado.split(':');
    if (parts.length >= 2) {
      String horas = parts[0].padLeft(2, '0');
      String minutos = parts[1].padLeft(2, '0');
      return '$horas:$minutos';
    }

    return '00:00';
  }

  // Verificar se aula está dentro do slot de tempo
  bool _horarioEstaDentroDoSlot(
      String aulaInicio, String aulaFim, String slotInicio, String slotFim) {
    try {
      // Converter para minutos para comparação
      int aulaInicioMin = _horarioParaMinutos(aulaInicio);
      int aulaFimMin = _horarioParaMinutos(aulaFim);
      int slotInicioMin = _horarioParaMinutos(slotInicio);
      int slotFimMin = _horarioParaMinutos(slotFim);

      // Verificar se há sobreposição
      return (aulaInicioMin >= slotInicioMin && aulaInicioMin < slotFimMin) ||
          (aulaFimMin > slotInicioMin && aulaFimMin <= slotFimMin) ||
          (aulaInicioMin <= slotInicioMin && aulaFimMin >= slotFimMin);
    } catch (e) {
      return false;
    }
  }

  // Converter horário "HH:MM" para minutos
  int _horarioParaMinutos(String horario) {
    List<String> parts = horario.split(':');
    if (parts.length >= 2) {
      int horas = int.tryParse(parts[0]) ?? 0;
      int minutos = int.tryParse(parts[1]) ?? 0;
      return horas * 60 + minutos;
    }
    return 0;
  }

  // Gerar cores para diferentes disciplinas
  Color _getCorDisciplina(String disciplina) {
    List<Color> cores = [
      Colors.blue.withOpacity(0.7),
      Colors.green.withOpacity(0.7),
      Colors.orange.withOpacity(0.7),
      Colors.purple.withOpacity(0.7),
      Colors.red.withOpacity(0.7),
      Colors.teal.withOpacity(0.7),
      Colors.indigo.withOpacity(0.7),
      Colors.amber.withOpacity(0.7),
    ];

    // Usar hash da disciplina para gerar cor consistente
    int index = disciplina.hashCode % cores.length;
    return cores[index.abs()];
  }
}
