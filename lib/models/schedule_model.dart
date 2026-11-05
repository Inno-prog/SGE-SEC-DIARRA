class ScheduleModel {
  final String id;
  final String nom;
  final String debut;
  final String fin;
  final String jours;
  final String type;
  final DateTime createdAt;
  final String? createdBy;

  ScheduleModel({
    required this.id,
    required this.nom,
    required this.debut,
    required this.fin,
    required this.jours,
    required this.type,
    required this.createdAt,
    this.createdBy,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      debut: json['debut'] ?? '',
      fin: json['fin'] ?? '',
      jours: json['jours'] ?? '',
      type: json['type'] ?? 'normal',
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
      createdBy: json['createdBy'] ?? json['created_by'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'debut': debut,
        'fin': fin,
        'jours': jours,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };
}