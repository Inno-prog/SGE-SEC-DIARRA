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

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      responsableId: json['responsableId'] ?? json['responsable_id'],
      responsableNom: json['responsableNom'] ?? json['responsable_nom'],
      nombreEmployes: json['nombreEmployes'] ?? json['nombre_employes'] ?? 0,
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'description': description,
        'responsableId': responsableId,
        'responsableNom': responsableNom,
        'nombreEmployes': nombreEmployes,
        'createdAt': createdAt.toIso8601String(),
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

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'],
      departementId: json['departementId'] ?? json['departement_id'],
      departementNom: json['departementNom'] ?? json['departement_nom'],
      salaireMini: (json['salaireMini'] ?? json['salaire_mini'] as num?)?.toDouble(),
      salaireMaxi: (json['salaireMaxi'] ?? json['salaire_maxi'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'departementId': departementId,
        'departementNom': departementNom,
        'salaireMini': salaireMini,
        'salaireMaxi': salaireMaxi,
        'createdAt': createdAt.toIso8601String(),
      };
}