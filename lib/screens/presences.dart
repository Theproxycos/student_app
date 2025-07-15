import 'package:flutter/material.dart';
import '../controllers/presenca_controller.dart';
import '../models/presenca_model.dart';
import '../session/session.dart';
import '../widgets/mobile_sidebar.dart';

class PresencesPage extends StatefulWidget {
  const PresencesPage({super.key});

  @override
  _PresencesPageState createState() => _PresencesPageState();
}

class _PresencesPageState extends State<PresencesPage> {
  final PresencaController _presencaController = PresencaController();
  Map<String, List<PresencaModel>> _presencasPorDisciplina = {};
  Map<String, bool> _expandedStatus = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarPresencas();
  }

  Future<void> _carregarPresencas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar se há usuário na sessão
      if (Session.currentStudent == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuário não está logado. Faça login novamente.';
        });
        return;
      }

      Map<String, List<PresencaModel>> presencas =
          await _presencaController.buscarPresencasPorDisciplina();

      // Debug: Verificar presenças disponíveis
      await _presencaController.debugPresencasDisponiveis();

      setState(() {
        _presencasPorDisciplina = presencas;
        _expandedStatus = {};
        // Inicializar estado expandido para cada disciplina
        for (String disciplina in presencas.keys) {
          _expandedStatus[disciplina] = false;
        }
        _isLoading = false;
        if (presencas.isEmpty) {
          _errorMessage = 'Nenhuma presença encontrada';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar presenças: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presenças'),
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
            Text('Carregando presenças...'),
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
                  onPressed: _carregarPresencas,
                  child: Text('Tentar Novamente'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_presencasPorDisciplina.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma presença registrada\nainda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarPresencas,
              child: Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _presencasPorDisciplina.length,
        itemBuilder: (context, index) {
          String disciplina = _presencasPorDisciplina.keys.elementAt(index);
          List<PresencaModel> presencas = _presencasPorDisciplina[disciplina]!;
          return _buildPresenceCard(disciplina, presencas);
        },
      ),
    );
  }

  Widget _buildPresenceCard(String disciplina, List<PresencaModel> presencas) {
    Map<String, dynamic> estatisticas =
        _presencaController.calcularEstatisticasDisciplina(presencas);
    bool isExpanded = _expandedStatus[disciplina] ?? false;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disciplina,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text("${estatisticas['totalAulas']} aulas registradas"),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: getStatusColor(estatisticas['corStatus'])
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${estatisticas['percentualPresenca']}%",
                        style: TextStyle(
                          color: getStatusColor(estatisticas['corStatus']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedStatus[disciplina] = !isExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _buildPresenceStats(estatisticas),
              const SizedBox(height: 16),
              _buildPresenceHistory(presencas),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceStats(Map<String, dynamic> estatisticas) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Presenças', estatisticas['aulasPresentes'].toString(),
              Colors.green),
          _buildStatItem(
              'Faltas', estatisticas['aulasFaltou'].toString(), Colors.red),
          _buildStatItem(
              'Total', estatisticas['totalAulas'].toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPresenceHistory(List<PresencaModel> presencas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico Recente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...presencas
            .take(5)
            .map((presenca) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        presenca.dataFormatada,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Row(
                        children: [
                          Text(
                            presenca.horarioFormatado,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  presenca.presente ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              presenca.statusPresenca,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
        if (presencas.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+ ${presencas.length - 5} mais registros',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Color getStatusColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
