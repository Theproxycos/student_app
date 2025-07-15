import 'package:campus_link/models/student_model.dart';

import '../widgets/mobile_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'assignment_detail_page.dart';
import '../models/assignment_data.dart';
import '../controllers/tarefas_controller.dart';
import '../session/session.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  _AssignmentsPageState createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  bool showCalendarView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Student student;
  List<AssignmentData> allAssignments = [];
  bool isLoadingAssignments = true;

  @override
  void initState() {
    super.initState();
    student = Session.currentStudent!;
    _selectedDay = DateTime.now();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final assignments = await buscarTrabalhosDoAluno(student);
      setState(() {
        allAssignments = assignments;
        isLoadingAssignments = false;
      });
    } catch (e) {
      setState(() {
        isLoadingAssignments = false;
      });
    }
  }

  // Função para verificar se uma data tem tarefas
  bool _hasAssignmentsOnDay(DateTime day) {
    return allAssignments.any((assignment) {
      final dueDate = _parseDate(assignment.dueDate);
      return dueDate != null && isSameDay(dueDate, day);
    });
  }

  // Função para obter tarefas de um dia específico
  List<AssignmentData> _getAssignmentsForDay(DateTime day) {
    return allAssignments.where((assignment) {
      final dueDate = _parseDate(assignment.dueDate);
      return dueDate != null && isSameDay(dueDate, day);
    }).toList();
  }

  // Função para converter string de data para DateTime
  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Erro ao converter data: $dateStr');
    }
    return null;
  }

  // Função para obter nomes curtos dos dias da semana
  String _getShortDayName(DateTime day) {
    switch (day.weekday) {
      case DateTime.monday:
        return 'Seg';
      case DateTime.tuesday:
        return 'Ter';
      case DateTime.wednesday:
        return 'Qua';
      case DateTime.thursday:
        return 'Qui';
      case DateTime.friday:
        return 'Sex';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }

  // Função para obter meses em português
  String _getPortugueseMonthYear(DateTime date) {
    List<String> months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Todos os Trabalhos"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                showCalendarView = true;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showCalendarView ? Colors.blue[300] : Colors.transparent,
              ),
              child: Icon(
                Icons.calendar_today,
                color: showCalendarView ? Colors.white : Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                showCalendarView = false;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    !showCalendarView ? Colors.blue[300] : Colors.transparent,
              ),
              child: Icon(
                Icons.view_list,
                color: !showCalendarView ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: showCalendarView ? buildCalendarView() : buildAssignmentsList(),
      ),
      floatingActionButton: MobileSidebar(),
    );
  }

  Widget buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextFormatter: (date, locale) {
              return _getPortugueseMonthYear(date);
            },
          ),
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            weekendStyle: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12),
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              String dayName = _getShortDayName(day);
              bool isWeekend = day.weekday == DateTime.saturday ||
                  day.weekday == DateTime.sunday;

              return Center(
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWeekend ? Colors.red : Colors.black,
                    fontSize: 12,
                  ),
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              bool hasAssignments = _hasAssignmentsOnDay(day);

              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: hasAssignments ? Colors.orange.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: hasAssignments ? Colors.orange[800] : null,
                      fontWeight: hasAssignments ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              bool hasAssignments = _hasAssignmentsOnDay(day);

              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasAssignments)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              bool hasAssignments = _hasAssignmentsOnDay(day);

              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasAssignments)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Divider(),
        // Título da seção
        if (_selectedDay != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Tarefas para ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
        Expanded(
          child: buildSelectedDayAssignments(),
        ),
      ],
    );
  }

  Widget buildAssignmentsList() {
    if (isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allAssignments.isEmpty) {
      return const Center(
        child: Text("Nenhum trabalho encontrado"),
      );
    }

    return ListView.builder(
      itemCount: allAssignments.length,
      itemBuilder: (context, index) {
        final assignment = allAssignments[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssignmentDetailPage(assignment: {
                  "subject": assignment.subject,
                  "type": assignment.type,
                  "dueDate": assignment.dueDate,
                  "daysRemaining": assignment.daysRemaining,
                  "completed": assignment.completed,
                  "createdDate": assignment.createdDate,
                  "assignmentType": assignment.assignmentType,
                  "descricao": assignment.descricao,
                  "id": assignment.id,
                  "ficheiros": assignment.ficheiros,
                }),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.book, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        assignment.subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignment.type,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(assignment.dueDate,
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            assignment.daysRemaining,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            assignment.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: assignment.completed
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSelectedDayAssignments() {
    if (isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedDay == null) {
      return const Center(
        child: Text(
          'Selecione um dia para ver as tarefas',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final assignmentsForDay = _getAssignmentsForDay(_selectedDay!);

    if (assignmentsForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Nenhuma tarefa para ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: assignmentsForDay.length,
      itemBuilder: (context, index) {
        final assignment = assignmentsForDay[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssignmentDetailPage(assignment: {
                  "subject": assignment.subject,
                  "type": assignment.type,
                  "dueDate": assignment.dueDate,
                  "daysRemaining": assignment.daysRemaining,
                  "completed": assignment.completed,
                  "createdDate": assignment.createdDate,
                  "assignmentType": assignment.assignmentType,
                  "descricao": assignment.descricao,
                  "id": assignment.id,
                  "ficheiros": assignment.ficheiros,
                }),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.book, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          assignment.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignment.type,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(assignment.dueDate,
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            assignment.daysRemaining,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            assignment.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: assignment.completed
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
