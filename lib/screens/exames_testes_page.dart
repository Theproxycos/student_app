import 'package:flutter/material.dart';
import '../controllers/exames_testes_controller.dart';
import '../models/exame_model.dart';
import '../models/teste_model.dart';
import '../session/session.dart';
import '../widgets/mobile_sidebar.dart';

class ExamesTestesPage extends StatefulWidget {
  const ExamesTestesPage({super.key});

  @override
  _ExamesTestesPageState createState() => _ExamesTestesPageState();
}

class _ExamesTestesPageState extends State<ExamesTestesPage>
    with SingleTickerProviderStateMixin {
  final ExamesTestesController _controller = ExamesTestesController();
  late TabController _tabController;

  Map<String, List<ExameModel>> _examesPorDisciplina = {};
  Map<String, List<TesteModel>> _testesPorDisciplina = {};
  Map<String, bool> _expandedStatusExames = {};
  Map<String, bool> _expandedStatusTestes = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
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

      // Carregar exames e testes em paralelo
      List<dynamic> results = await Future.wait([
        _controller.buscarExamesPorDisciplina(),
        _controller.buscarTestesPorDisciplina(),
      ]);

      Map<String, List<ExameModel>> exames = results[0];
      Map<String, List<TesteModel>> testes = results[1];

      // Debug: Verificar dados disponíveis
      await _controller.debugExamesDisponiveis();

      setState(() {
        _examesPorDisciplina = exames;
        _testesPorDisciplina = testes;

        // Inicializar estado expandido para cada disciplina
        _expandedStatusExames = {};
        _expandedStatusTestes = {};

        for (String disciplina in exames.keys) {
          _expandedStatusExames[disciplina] = false;
        }

        for (String disciplina in testes.keys) {
          _expandedStatusTestes[disciplina] = false;
        }

        _isLoading = false;

        if (exames.isEmpty && testes.isEmpty) {
          _errorMessage = 'Nenhum exame ou teste encontrado';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exames e Testes'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.assignment),
              text: 'Exames',
            ),
            Tab(
              icon: Icon(Icons.quiz),
              text: 'Testes',
            ),
          ],
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
            Text('Carregando dados...'),
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
                  onPressed: _carregarDados,
                  child: Text('Tentar Novamente'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildExamesTab(),
        _buildTestesTab(),
      ],
    );
  }

  Widget _buildExamesTab() {
    if (_examesPorDisciplina.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum exame agendado\nainda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDados,
              child: Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _examesPorDisciplina.length,
        itemBuilder: (context, index) {
          String disciplina = _examesPorDisciplina.keys.elementAt(index);
          List<ExameModel> exames = _examesPorDisciplina[disciplina]!;
          return _buildExameCard(disciplina, exames);
        },
      ),
    );
  }

  Widget _buildTestesTab() {
    if (_testesPorDisciplina.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum teste agendado\nainda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDados,
              child: Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _testesPorDisciplina.length,
        itemBuilder: (context, index) {
          String disciplina = _testesPorDisciplina.keys.elementAt(index);
          List<TesteModel> testes = _testesPorDisciplina[disciplina]!;
          return _buildTesteCard(disciplina, testes);
        },
      ),
    );
  }

  Widget _buildExameCard(String disciplina, List<ExameModel> exames) {
    Map<String, dynamic> estatisticas =
        _controller.calcularEstatisticasExamesDisciplina(exames);
    bool isExpanded = _expandedStatusExames[disciplina] ?? false;

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
                      Text("${estatisticas['totalExames']} exames agendados"),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${estatisticas['examesPendentes']} pendentes",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                          _expandedStatusExames[disciplina] = !isExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _buildExameStats(estatisticas),
              const SizedBox(height: 16),
              _buildExamesList(exames),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTesteCard(String disciplina, List<TesteModel> testes) {
    Map<String, dynamic> estatisticas =
        _controller.calcularEstatisticasTestesDisciplina(testes);
    bool isExpanded = _expandedStatusTestes[disciplina] ?? false;

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
                      Text("${estatisticas['totalTestes']} testes agendados"),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${estatisticas['testesPendentes']} pendentes",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                          _expandedStatusTestes[disciplina] = !isExpanded;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _buildTesteStats(estatisticas),
              const SizedBox(height: 16),
              _buildTestesList(testes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExameStats(Map<String, dynamic> estatisticas) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Total', estatisticas['totalExames'].toString(), Colors.blue),
              _buildStatItem('Realizados',
                  estatisticas['examesRealizados'].toString(), Colors.green),
              _buildStatItem('Pendentes',
                  estatisticas['examesPendentes'].toString(), Colors.orange),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Normal', estatisticas['epocaNormal'].toString(),
                  Colors.blue),
              _buildStatItem('Especial',
                  estatisticas['epocaEspecial'].toString(), Colors.orange),
              _buildStatItem(
                  'Recurso', estatisticas['recurso'].toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTesteStats(Map<String, dynamic> estatisticas) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Total', estatisticas['totalTestes'].toString(), Colors.blue),
          _buildStatItem('Realizados',
              estatisticas['testesRealizados'].toString(), Colors.green),
          _buildStatItem('Pendentes',
              estatisticas['testesPendentes'].toString(), Colors.orange),
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
            fontSize: 18,
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

  Widget _buildExamesList(List<ExameModel> exames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos Exames',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...exames
            .map((exame) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exame.tipo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: getStatusColor(exame.corTipo),
                                ),
                              ),
                              Text(
                                '${exame.dataFormatada} às ${exame.horarioFormatado}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: exame.jaPasso
                                ? Colors.grey
                                : getStatusColor(exame.corTipo),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exame.status,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildTestesList(List<TesteModel> testes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos Testes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...testes
            .map((teste) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teste.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${teste.dataHora.day.toString().padLeft(2, '0')}/${teste.dataHora.month.toString().padLeft(2, '0')}/${teste.dataHora.year} às ${teste.dataHora.hour.toString().padLeft(2, '0')}:${teste.dataHora.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: teste.dataHora.isBefore(DateTime.now())
                                ? Colors.grey
                                : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            teste.dataHora.isBefore(DateTime.now())
                                ? 'Concluído'
                                : 'Agendado',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
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
