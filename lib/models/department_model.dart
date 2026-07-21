import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String nom;
  final String? description;
  final String? responsableId;
  final String? responsableNom;
  final int nombreEmployes;
  final DateTime createdAt;

  DepartmentModel({
    required this.id,
    required this.nom,
    this.description,
    this.responsableId,
    this.responsableNom,
    this.nombreEmployes = 0,
    required this.createdAt,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      nom: d['nom'] ?? '',
      description: d['description'],
      responsableId: d['responsableId'],
      responsableNom: d['responsableNom'],
      nombreEmployes: d['nombreEmployes'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nom': nom,
        'description': description,
        'responsableId': responsableId,
        'responsableNom': responsableNom,
        'nombreEmployes': nombreEmployes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  DepartmentModel copyWith({
    String? nom,
    String? description,
    String? responsableId,
    String? responsableNom,
    int? nombreEmployes,
  }) =>
      DepartmentModel(
        id: id,
        nom: nom ?? this.nom,
        description: description ?? this.description,
        responsableId: responsableId ?? this.responsableId,
        responsableNom: responsableNom ?? this.responsableNom,
        nombreEmployes: nombreEmployes ?? this.nombreEmployes,
        createdAt: createdAt,
      );
}

class PositionModel {
  final String id;
  final String titre;
  final String? description;
  final String? departementId;
  final String? departementNom;
  final double? salaireMini;
  final double? salaireMaxi;
  final DateTime createdAt;

  PositionModel({
    required this.id,
    required this.titre,
    this.description,
    this.departementId,
    this.departementNom,
    this.salaireMini,
    this.salaireMaxi,
    required this.createdAt,
  });

  factory PositionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PositionModel(
      id: doc.id,
      titre: d['titre'] ?? '',
      description: d['description'],
      departementId: d['departementId'],
      departementNom: d['departementNom'],
      salaireMini: (d['salaireMini'] as num?)?.toDouble(),
      salaireMaxi: (d['salaireMaxi'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'titre': titre,
        'description': description,
        'departementId': departementId,
        'departementNom': departementNom,
        'salaireMini': salaireMini,
        'salaireMaxi': salaireMaxi,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
