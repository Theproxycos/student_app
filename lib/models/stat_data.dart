import 'package:campus_link/controllers/chat_controller.dart';
import 'package:flutter/material.dart';

import '../widgets/stat_card.dart';

import '../models/student_model.dart';
import '../session/session.dart';
import '../controllers/tarefas_controller.dart';
import '../controllers/disciplinas_controller.dart';
import '../controllers/presenca_controller.dart';

class StatData {
  // static int getTotalAssignments() {
  //   return AssignmentData.getAssignments().length;
  // }

  static Future<int> getTotalChats() async {
    final chatCount = await contarConversasDoUsuario();
    return chatCount;
  }

  static Future<int> getTotalAssignments(Student student) async {
    final trabalhosCount =
        await contarTrabalhosDoAluno(student.courseId, student.year);
    return trabalhosCount;
  }

  static Future<int> getTotalCourses(Student student) async {
    final disciplinasCount =
        await contarDisciplinasDoAluno(student.courseId, student.year);
    return disciplinasCount;
  }

  static Future<double> getAverageAttendancePercentage(Student student) async {
    final presenca = await calcularPercentagemPresencasPorEmail(student.userId);
    return presenca;
  }



  static List<Widget> generateStatCards() {
    return [
      FutureBuilder<int>(
        future: getTotalAssignments(Session.currentStudent!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return StatCard(
              title: 'Trabalhos',
              value: '...',
              color: Colors.green,
              student: Session.currentStudent!,
            );
          } else if (snapshot.hasError) {
            return StatCard(
              title: 'Trabalhos',
              value: 'Erro',
              color: Colors.red,
              student: Session.currentStudent!,
            );
          } else {
            return StatCard(
              title: 'Trabalhos',
              value: snapshot.data.toString(),
              color: Colors.green,
              student: Session.currentStudent!,
            );
          }
        },
      ),
      FutureBuilder<int>(
        future: getTotalCourses(Session.currentStudent!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return StatCard(
              title: 'Disciplinas',
              value: '...',
              color: Colors.blue,
              student: Session.currentStudent!,
            );
          } else if (snapshot.hasError) {
            return StatCard(
              title: 'Disciplinas',
              value: 'Erro',
              color: Colors.red,
              student: Session.currentStudent!,
            );
          } else {
            return StatCard(
              title: 'Disciplinas',
              value: snapshot.data.toString(),
              color: Colors.blue,
              student: Session.currentStudent!,
            );
          }
        },
      ),
      FutureBuilder<double>(
        future: getAverageAttendancePercentage(Session.currentStudent!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return StatCard(
              title: 'Assiduidade %',
              value: '...',
              color: Colors.orange,
              student: Session.currentStudent!,
            );
          } else if (snapshot.hasError) {
            return StatCard(
              title: 'Assiduidade %',
              value: 'Erro',
              color: Colors.red,
              student: Session.currentStudent!,
            );
          } else {
            return StatCard(
              title: 'Assiduidade %',
              value: '${snapshot.data!.toStringAsFixed(1)}%',
              color: Colors.orange,
              student: Session.currentStudent!,
            );
          }
        },
      ),
      FutureBuilder<int>(
        future: contarConversasDoUsuario(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return StatCard(
              title: 'Conversas',
              value: '...',
              color: Colors.red,
              student: Session.currentStudent!,
            );
          } else if (snapshot.hasError) {
            return StatCard(
              title: 'Conversas',
              value: 'Erro',
              color: Colors.red,
              student: Session.currentStudent!,
            );
          } else {
            return StatCard(
              title: 'Conversas',
              value: snapshot.data.toString(),
              color: Colors.red,
              student: Session.currentStudent!,
            );
          }
        },
      ),
    ];
  }
}
