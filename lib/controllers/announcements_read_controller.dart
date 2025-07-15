import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_read_model.dart';

class AnnouncementReadController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'anuncios_student_read';

  /// Carrega os anúncios lidos para um professor
  Future<AnnouncementReadModel> loadReadAnnouncements(
    String studentId,
  ) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(studentId).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return AnnouncementReadModel.fromFirestore(
          docSnapshot.data()!,
          studentId,
        );
      } else {
        // Se não existe, retorna um modelo vazio
        return AnnouncementReadModel.empty(studentId);
      }
    } catch (e) {
      print('Erro ao carregar anúncios lidos: $e');
      // Em caso de erro, retorna um modelo vazio
      return AnnouncementReadModel.empty(studentId);
    }
  }

  /// Marca um anúncio como lido
  Future<bool> markAnnouncementAsRead(
    String studentId,
    String announcementId,
  ) async {
    try {
      // Primeiro carrega os dados atuais
      final currentData = await loadReadAnnouncements(studentId);

      // Cria uma nova versão com o anúncio marcado como lido
      final updatedData = currentData.copyWithNewRead(announcementId);

      // Salva no Firestore
      await _firestore
          .collection(_collection)
          .doc(studentId)
          .set(updatedData.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao marcar anúncio como lido: $e');
      return false;
    }
  }

  /// Verifica se um anúncio específico foi lido
  Future<bool> isAnnouncementRead(
    String studentId,
    String announcementId,
  ) async {
    try {
      final data = await loadReadAnnouncements(studentId);
      return data.isAnnouncementRead(announcementId);
    } catch (e) {
      print('Erro ao verificar se anúncio foi lido: $e');
      return false;
    }
  }

  /// Obtém a lista de IDs dos anúncios lidos
  Future<Set<String>> getReadAnnouncementIds(String studentId) async {
    try {
      final data = await loadReadAnnouncements(studentId);
      return data.readAnnouncementIds.toSet();
    } catch (e) {
      print('Erro ao obter IDs dos anúncios lidos: $e');
      return <String>{};
    }
  }

  /// Marca múltiplos anúncios como lidos de uma vez
  Future<bool> markMultipleAnnouncementsAsRead(
    String studentId,
    List<String> announcementIds,
  ) async {
    try {
      // Carrega os dados atuais
      final currentData = await loadReadAnnouncements(studentId);

      // Adiciona todos os novos IDs (evitando duplicatas)
      final allReadIds = {
        ...currentData.readAnnouncementIds,
        ...announcementIds,
      };

      // Cria o modelo atualizado
      final updatedData = AnnouncementReadModel(
        studentId: studentId,
        readAnnouncementIds: allReadIds.toList(),
        lastUpdated: DateTime.now(),
      );

      // Salva no Firestore
      await _firestore
          .collection(_collection)
          .doc(studentId)
          .set(updatedData.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao marcar múltiplos anúncios como lidos: $e');
      return false;
    }
  }

  /// Remove um anúncio da lista de lidos (marcar como não lido)
  Future<bool> markAnnouncementAsUnread(
    String studentId,
    String announcementId,
  ) async {
    try {
      final currentData = await loadReadAnnouncements(studentId);

      // Remove o ID da lista
      final updatedIds =
          currentData.readAnnouncementIds
              .where((id) => id != announcementId)
              .toList();

      final updatedData = AnnouncementReadModel(
        studentId: studentId,
        readAnnouncementIds: updatedIds,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(studentId)
          .set(updatedData.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao marcar anúncio como não lido: $e');
      return false;
    }
  }
}
