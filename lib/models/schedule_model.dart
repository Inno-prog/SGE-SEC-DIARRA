import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String nom;
  final String debut;
  final String fin;
  final String jours;
  final String type;
  final DateTime createdAt;

  ScheduleModel({
    required this.id,
    required this.nom,
    required this.debut,
    required this.fin,
    required this.jours,
    required this.type,
    required this.createdAt,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      nom: d['nom'] ?? '',
      debut: d['debut'] ?? '',
      fin: d['fin'] ?? '',
      jours: d['jours'] ?? '',
      type: d['type'] ?? 'normal',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nom': nom,
        'debut': debut,
        'fin': fin,
        'jours': jours,
        'type': type,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
