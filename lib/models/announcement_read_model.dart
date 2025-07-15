import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementReadModel {
  final String studentId;
  final List<String> readAnnouncementIds;
  final DateTime lastUpdated;

  AnnouncementReadModel({
    required this.studentId,
    required this.readAnnouncementIds,
    required this.lastUpdated,
  });

  // Converter do Firestore para o modelo
  factory AnnouncementReadModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AnnouncementReadModel(
      studentId: docId,
      readAnnouncementIds: List<String>.from(data['readAnnouncementIds'] ?? []),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Converter do modelo para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'readAnnouncementIds': readAnnouncementIds,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Verificar se um anúncio foi lido
  bool isAnnouncementRead(String announcementId) {
    return readAnnouncementIds.contains(announcementId);
  }

  // Criar uma cópia com novos anúncios lidos
  AnnouncementReadModel copyWithNewRead(String announcementId) {
    if (readAnnouncementIds.contains(announcementId)) {
      return this; // Já foi lido
    }

    return AnnouncementReadModel(
      studentId: studentId,
      readAnnouncementIds: [...readAnnouncementIds, announcementId],
      lastUpdated: DateTime.now(),
    );
  }

  // Criar uma instância vazia para um novo professor
  factory AnnouncementReadModel.empty(String studentId) {
    return AnnouncementReadModel(
      studentId: studentId,
      readAnnouncementIds: [],
      lastUpdated: DateTime.now(),
    );
  }
}
