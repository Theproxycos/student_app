import 'package:campus_link/models/notification_model.dart';
import 'package:campus_link/session/session.dart';
import 'package:campus_link/controllers/exames_testes_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController {
  final ExamesTestesController _examesController = ExamesTestesController();

  // Função principal para buscar todas as notificações
  Future<List<NotificationModel>> getAllNotifications() async {
    print('🔔 Iniciando busca de notificações REAIS');

    List<NotificationModel> allNotifications = [];

    try {
      // Buscar notificações de trabalhos próximos do prazo
      final assignmentNotifications = await _getAssignmentNotifications();
      allNotifications.addAll(assignmentNotifications);

      // Buscar notificações de exames/testes próximos
      final examNotifications = await _getExamTestNotifications();
      allNotifications.addAll(examNotifications);

      // Verificar quais notificações foram lidas pelo usuário atual
      allNotifications = allNotifications.map((notification) {
        final isRead = Session.isNotificationRead(notification.id);
        return notification.copyWith(isRead: isRead);
      }).toList();

      print('✅ Total de notificações encontradas: ${allNotifications.length}');
    } catch (e) {
      print('❌ Erro ao buscar notificações: $e');
    }

    // Ordenar por data (mais recentes primeiro)
    allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allNotifications;
  }

  // Notificações de tarefas (3 dias antes do prazo)
  Future<List<NotificationModel>> _getAssignmentNotifications() async {
    List<NotificationModel> notifications = [];

    try {
      final student = Session.currentStudent!;
      print('📚 Buscando trabalhos para o aluno: ${student.nome}');

      // Buscar as disciplinas do aluno
      final firestore = FirebaseFirestore.instance;
      final coursesSnap = await firestore.collection('courses').get();
      final courseDoc = coursesSnap.docs.firstWhere(
        (doc) =>
            (doc.data()['name'] as String).toLowerCase() ==
            student.courseId.toLowerCase(),
        orElse: () => throw Exception('Curso não encontrado'),
      );

      final subjectsSnap = await firestore
          .collection('courses')
          .doc(courseDoc.id)
          .collection('subjects')
          .where('courseYear', isEqualTo: student.year)
          .get();

      final subjectIds = subjectsSnap.docs.map((doc) => doc.id).toList();
      final Map<String, String> subjectNames = {
        for (var doc in subjectsSnap.docs)
          doc.id: doc.data()['name'] ?? 'Disciplina'
      };

      if (subjectIds.isEmpty) return notifications;

      // Buscar tarefas diretamente do Firebase
      final tarefasSnap = await firestore.collection('tarefas').get();
      final now = DateTime.now();
      print(
          '📅 Data atual: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}');

      for (final doc in tarefasSnap.docs) {
        final data = doc.data();
        final disciplinaId = data['disciplinaId'];

        // Verificar se a tarefa é de uma disciplina do aluno
        if (!subjectIds.contains(disciplinaId)) continue;

        print('🔍 Analisando trabalho: ${data['titulo']} - ID: ${doc.id}');
        print('   - DisciplinaId: $disciplinaId');
        print('   - DataLimite: ${data['dataLimite']}');
        print('   - HoraLimite: ${data['horaLimite']}');

        // Verificar se o aluno já entregou
        final entregasRaw = data['entregas'];
        bool entregue = false;
        if (entregasRaw is List) {
          entregue =
              entregasRaw.any((e) => e is Map && e['alunoId'] == student.id);
        }

        print('   - Completed: $entregue');

        if (!entregue) {
          // Parse da data e hora limite
          DateTime? dataLimite = DateTime.tryParse(data['dataLimite'] ?? '');
          final horaLimiteStr = data['horaLimite'] ?? '';

          if (dataLimite != null) {
            // Trabalhar com uma cópia local para evitar problemas de null safety
            DateTime finalDueDate = dataLimite;

            // Todas as tarefas devem ter horaLimite obrigatoriamente
            if (horaLimiteStr.isNotEmpty) {
              try {
                final horaPartes = horaLimiteStr.split(':');
                if (horaPartes.length >= 2) {
                  final hora = int.parse(horaPartes[0]);
                  final minuto = int.parse(horaPartes[1]);
                  final segundo =
                      horaPartes.length > 2 ? int.parse(horaPartes[2]) : 0;

                  finalDueDate = DateTime(
                    finalDueDate.year,
                    finalDueDate.month,
                    finalDueDate.day,
                    hora,
                    minuto,
                    segundo,
                  );
                  print(
                      '   - Data limite com hora: ${finalDueDate.day}/${finalDueDate.month}/${finalDueDate.year} ${finalDueDate.hour}:${finalDueDate.minute}');
                } else {
                  print(
                      '   - ❌ HoraLimite em formato inválido: $horaLimiteStr');
                  continue; // Pular esta tarefa se não tem hora válida
                }
              } catch (e) {
                print('   - ❌ Erro ao parsear horaLimite: $horaLimiteStr - $e');
                continue; // Pular esta tarefa se não conseguir parsear a hora
              }
            } else {
              print('   - ❌ Tarefa sem horaLimite - ID: ${doc.id}');
              continue; // Pular tarefas sem horaLimite
            }

            final timeUntilDue = finalDueDate.difference(now);
            final daysUntilDue = timeUntilDue.inDays;
            final hoursUntilDue = timeUntilDue.inHours;

            print(
                '   - Tempo restante: ${daysUntilDue} dias, ${hoursUntilDue} horas');

            String title = '';
            String description = '';
            final nomeDisciplina = subjectNames[disciplinaId] ?? disciplinaId;

            // Não mostrar notificações para tarefas em atraso
            if (timeUntilDue.isNegative) {
              print('   - ❌ Trabalho em atraso, não gerando notificação');
              continue;
            }

            // Determinar o tipo de notificação baseado no tempo restante
            if (daysUntilDue == 0) {
              // Mesmo dia
              if (hoursUntilDue <= 2) {
                title = 'Trabalho vence em ${hoursUntilDue}h!';
                description = '$nomeDisciplina - ${data['titulo']} vence hoje';
              } else {
                title = 'Trabalho vence hoje!';
                description =
                    '$nomeDisciplina - ${data['titulo']} vence às ${finalDueDate.hour}:${finalDueDate.minute.toString().padLeft(2, '0')}';
              }
            } else if (daysUntilDue == 1) {
              title = 'Trabalho vence amanhã!';
              description =
                  '$nomeDisciplina - ${data['titulo']} vence amanhã às ${finalDueDate.hour}:${finalDueDate.minute.toString().padLeft(2, '0')}';
            } else if (daysUntilDue <= 3) {
              title = 'Trabalho próximo do prazo';
              description =
                  '$nomeDisciplina - ${data['titulo']} vence em $daysUntilDue dias';
            }

            if (title.isNotEmpty) {
              print('✅ Adicionando notificação de trabalho: $title');
              notifications.add(NotificationModel(
                id: 'assignment_${doc.id}',
                title: title,
                description: description,
                type: 'tarefa',
                timestamp: now
                    .subtract(Duration(hours: (3 - daysUntilDue).abs() * 24)),
                data: {
                  'assignmentId': doc.id,
                  'subject': nomeDisciplina,
                  'type': data['titulo'].toString(),
                  'dueDate':
                      '${finalDueDate.day.toString().padLeft(2, '0')}/${finalDueDate.month.toString().padLeft(2, '0')}/${finalDueDate.year}',
                  'horaLimite': horaLimiteStr,
                },
              ));
            } else {
              print(
                  '   - Não gera notificação (${daysUntilDue > 3 ? 'muito longe' : 'critério não atendido'})');
            }
          } else {
            print('   - ❌ Erro ao parsear dataLimite: ${data['dataLimite']}');
          }
        } else {
          print('   - ✅ Trabalho já concluído');
        }
      }
    } catch (e) {
      print('❌ Erro ao buscar notificações de tarefas: $e');
    }

    print('📊 Total de notificações de tarefas: ${notifications.length}');
    return notifications;
  }

  // Notificações de testes e exames (3 dias antes)
  Future<List<NotificationModel>> _getExamTestNotifications() async {
    List<NotificationModel> notifications = [];

    try {
      final student = Session.currentStudent!;
      print('🎓 Buscando exames/testes para o aluno: ${student.nome}');

      final exames = await _examesController.buscarExamesDoAlunoLogado();
      final testes = await _examesController.buscarTestesDoAlunoLogado();
      print('📋 Encontrados ${exames.length} exames e ${testes.length} testes');

      // Buscar nomes das disciplinas para os testes
      Map<String, String> disciplinaNomes = {};
      try {
        final firestore = FirebaseFirestore.instance;
        final currentUser = Session.currentStudent!;

        // Buscar curso do aluno
        final coursesSnap = await firestore.collection('courses').get();
        final courseDoc = coursesSnap.docs.firstWhere(
          (doc) =>
              (doc.data()['name'] as String).toLowerCase() ==
              currentUser.courseId.toLowerCase(),
          orElse: () => throw Exception('Curso não encontrado'),
        );

        // Buscar disciplinas do ano do aluno
        final subjectsSnap = await firestore
            .collection('courses')
            .doc(courseDoc.id)
            .collection('subjects')
            .where('courseYear', isEqualTo: currentUser.year)
            .get();

        for (var doc in subjectsSnap.docs) {
          final data = doc.data();
          disciplinaNomes[doc.id] = data['name'] ?? doc.id;
        }
        print('📚 Disciplinas encontradas: $disciplinaNomes');
      } catch (e) {
        print('❌ Erro ao buscar nomes das disciplinas: $e');
      }

      final now = DateTime.now();

      // Processar exames
      for (final exame in exames) {
        final daysUntilExam = exame.dataHora.difference(now).inDays;
        print(
            '📅 Exame: ${exame.disciplinaNome} - ${exame.tipo}, Dias restantes: $daysUntilExam');

        // Não mostrar notificações para exames em atraso
        if (daysUntilExam < 0) {
          print('   - ❌ Exame em atraso, não gerando notificação');
          continue;
        }

        String title = '';
        String description = '';

        // Notificar apenas quando faltam 3 dias ou menos
        if (daysUntilExam == 0) {
          title = 'Exame hoje!';
          description = '${exame.disciplinaNome} - ${exame.tipo} é hoje!';
        } else if (daysUntilExam <= 3) {
          title = daysUntilExam == 1 ? 'Exame amanhã!' : 'Exame próximo';
          description =
              '${exame.disciplinaNome} - ${exame.tipo} em $daysUntilExam dias';
        }

        if (title.isNotEmpty) {
          print('✅ Adicionando notificação de exame: $title');
          notifications.add(NotificationModel(
            id: 'exam_${exame.id}',
            title: title,
            description: description,
            type: 'exame',
            timestamp:
                now.subtract(Duration(hours: (3 - daysUntilExam).abs() * 24)),
            data: {
              'examId': exame.id,
              'disciplina': exame.disciplinaNome,
              'tipo': exame.tipo,
              'data': exame.dataFormatada,
            },
          ));
        }
      }

      // Processar testes
      for (final teste in testes) {
        final daysUntilTest = teste.dataHora.difference(now).inDays;
        final disciplinaNome =
            disciplinaNomes[teste.disciplinaId] ?? teste.disciplinaId;
        print(
            '📝 Teste: ${teste.nome} - $disciplinaNome, Dias restantes: $daysUntilTest');

        // Não mostrar notificações para testes em atraso
        if (daysUntilTest < 0) {
          print('   - ❌ Teste em atraso, não gerando notificação');
          continue;
        }

        String title = '';
        String description = '';

        // Notificar apenas quando faltam 3 dias ou menos
        if (daysUntilTest == 0) {
          title = 'Teste hoje!';
          description = '$disciplinaNome - ${teste.nome} é hoje!';
        } else if (daysUntilTest <= 3) {
          title = daysUntilTest == 1 ? 'Teste amanhã!' : 'Teste próximo';
          description =
              '$disciplinaNome - ${teste.nome} em $daysUntilTest dias';
        }

        if (title.isNotEmpty) {
          print('✅ Adicionando notificação de teste: $title');
          notifications.add(NotificationModel(
            id: 'test_${teste.id}',
            title: title,
            description: description,
            type: 'teste',
            timestamp:
                now.subtract(Duration(hours: (3 - daysUntilTest).abs() * 24)),
            data: {
              'testId': teste.id,
              'nome': teste.nome,
              'disciplina': disciplinaNome,
              'data': teste.dataFormatada,
            },
          ));
        }
      }
    } catch (e) {
      print('❌ Erro ao buscar notificações de exames/testes: $e');
    }

    print('📊 Total de notificações de exames/testes: ${notifications.length}');
    return notifications;
  }

  // Marcar uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      print('🔵 markAsRead chamado no Controller: $notificationId');

      // Usar o sistema de sessão para marcar como lida
      await Session.markNotificationAsRead(notificationId);

      print(
          '✅ NotificationController: Notificação marcada como lida com sucesso');
    } catch (e) {
      print(
          '❌ NotificationController: Erro ao marcar notificação como lida: $e');
    }
  }

  // Marcar todas as notificações como lidas
  Future<void> markAllAsRead() async {
    try {
      print('🔵 Marcando todas as notificações como lidas');

      // Buscar todas as notificações atuais
      final notifications = await getAllNotifications();

      // Coletar IDs das notificações não lidas
      final unreadIds = notifications
          .where((notification) => !notification.isRead)
          .map((notification) => notification.id)
          .toList();

      // Marcar todas como lidas de uma vez
      if (unreadIds.isNotEmpty) {
        await Session.markAllNotificationsAsRead(unreadIds);
      }

      print('✅ Todas as notificações marcadas como lidas com sucesso');
    } catch (e) {
      print('❌ Erro ao marcar todas as notificações como lidas: $e');
    }
  }
}
