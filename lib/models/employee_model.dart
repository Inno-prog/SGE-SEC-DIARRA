class EmergencyContact {
  final String nom;
  final String telephone;
  final String relation;

  EmergencyContact({required this.nom, required this.telephone, required this.relation});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(nom: json['nom'] ?? '', telephone: json['telephone'] ?? '', relation: json['relation'] ?? '');

  Map<String, dynamic> toJson() => {'nom': nom, 'telephone': telephone, 'relation': relation};
}

class EmployeeModel {
  final String id;
  final String matricule;
  final String nom;
  final String prenom;
  final String sexe;
  final DateTime dateNaissance;
  final String? photoUrl;
  final String adresse;
  final String telephone;
  final String email;
  final String situationMatrimoniale;
  final String nationalite;
  final EmergencyContact? contactUrgence;

  // Infos professionnelles
  final String poste;
  final String service;
  final String departementId;
  final String departementNom;
  final String grade;
  final DateTime dateEmbauche;
  final String typeContrat;
  final double salaire;
  final String statut;

  // Congés
  final int soldeCongesAnnuels;
  final int soldeCongesMaladie;

  // Documents
  final String? contratSigneFileId;
  final String? demandeFileId;
  final String? cvFileId;
  final String? diplomeFileId;
  final String? autresFileId;

  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  EmployeeModel({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.sexe,
    required this.dateNaissance,
    this.photoUrl,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.situationMatrimoniale,
    this.nationalite = '',
    this.contactUrgence,
    required this.poste,
    required this.service,
    required this.departementId,
    required this.departementNom,
    required this.grade,
    required this.dateEmbauche,
    required this.typeContrat,
    required this.salaire,
    required this.statut,
    this.soldeCongesAnnuels = 30,
    this.soldeCongesMaladie = 15,
    this.contratSigneFileId,
    this.demandeFileId,
    this.cvFileId,
    this.diplomeFileId,
    this.autresFileId,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  String get fullName => '$prenom $nom';

  int get anciennete {
    final now = DateTime.now();
    return now.year - dateEmbauche.year;
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? '',
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      sexe: json['sexe'] ?? '',
      dateNaissance: json['dateNaissance'] != null || json['date_naissance'] != null
          ? DateTime.parse(json['dateNaissance'] ?? json['date_naissance'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      situationMatrimoniale: json['situationMatrimoniale'] ?? json['situation_matrimoniale'] ?? '',
      nationalite: json['nationalite'] ?? '',
      contactUrgence: (json['contactUrgence'] != null || json['contact_urgence'] != null)
          ? EmergencyContact.fromJson(json['contactUrgence'] ?? json['contact_urgence'] ?? {})
          : null,
      poste: json['poste'] ?? '',
      service: json['service'] ?? '',
      departementId: json['departementId'] ?? json['departement_id'] ?? '',
      departementNom: json['departementNom'] ?? json['departement_nom'] ?? '',
      grade: json['grade'] ?? '',
      dateEmbauche: json['dateEmbauche'] != null || json['date_embauche'] != null
          ? DateTime.parse(json['dateEmbauche'] ?? json['date_embauche'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
      typeContrat: json['typeContrat'] ?? json['type_contrat'] ?? '',
      salaire: (json['salaire'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'actif',
      soldeCongesAnnuels: json['soldeCongesAnnuels'] ?? json['solde_conges_annuels'] ?? 30,
      soldeCongesMaladie: json['soldeCongesMaladie'] ?? json['solde_conges_maladie'] ?? 15,
      contratSigneFileId: json['contratSigneFileId'] ?? json['contrat_signe_file_id'],
      demandeFileId: json['demandeFileId'] ?? json['demande_file_id'],
      cvFileId: json['cvFileId'] ?? json['cv_file_id'],
      diplomeFileId: json['diplomeFileId'] ?? json['diplome_file_id'],
      autresFileId: json['autresFileId'] ?? json['autres_file_id'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String())
          : DateTime.now(),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String())
          : null,
      updatedBy: json['updatedBy'] ?? json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'sexe': sexe,
        'dateNaissance': dateNaissance.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'photoUrl': photoUrl,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'situationMatrimoniale': situationMatrimoniale,
        'nationalite': nationalite,
        'contactUrgence': contactUrgence?.toJson(),
        'poste': poste,
        'service': service,
        'departementId': departementId,
        'departementNom': departementNom,
        'grade': grade,
        'dateEmbauche': dateEmbauche.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'typeContrat': typeContrat,
        'salaire': salaire,
        'statut': statut,
        'soldeCongesAnnuels': soldeCongesAnnuels,
        'soldeCongesMaladie': soldeCongesMaladie,
        'contratSigneFileId': contratSigneFileId,
        'demandeFileId': demandeFileId,
        'cvFileId': cvFileId,
        'diplomeFileId': diplomeFileId,
        'autresFileId': autresFileId,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
        'updatedAt': updatedAt?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'updatedBy': updatedBy,
      };

  EmployeeModel copyWith({
    String? nom,
    String? prenom,
    String? photoUrl,
    String? adresse,
    String? telephone,
    String? email,
    String? poste,
    String? service,
    String? departementId,
    String? departementNom,
    String? grade,
    double? salaire,
    String? statut,
    String? typeContrat,
    int? soldeCongesAnnuels,
    int? soldeCongesMaladie,
    String? nationalite,
    String? contratSigneFileId,
    String? demandeFileId,
    String? cvFileId,
    String? diplomeFileId,
    String? autresFileId,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      EmployeeModel(
        id: id,
        matricule: matricule,
        nom: nom ?? this.nom,
        prenom: prenom ?? this.prenom,
        sexe: sexe,
        dateNaissance: dateNaissance,
        photoUrl: photoUrl ?? this.photoUrl,
        adresse: adresse ?? this.adresse,
        telephone: telephone ?? this.telephone,
        email: email ?? this.email,
        situationMatrimoniale: situationMatrimoniale,
        nationalite: nationalite ?? this.nationalite,
        contactUrgence: contactUrgence,
        poste: poste ?? this.poste,
        service: service ?? this.service,
        departementId: departementId ?? this.departementId,
        departementNom: departementNom ?? this.departementNom,
        grade: grade ?? this.grade,
        dateEmbauche: dateEmbauche,
        typeContrat: typeContrat ?? this.typeContrat,
        salaire: salaire ?? this.salaire,
        statut: statut ?? this.statut,
        soldeCongesAnnuels: soldeCongesAnnuels ?? this.soldeCongesAnnuels,
        soldeCongesMaladie: soldeCongesMaladie ?? this.soldeCongesMaladie,
        contratSigneFileId: contratSigneFileId ?? this.contratSigneFileId,
        demandeFileId: demandeFileId ?? this.demandeFileId,
        cvFileId: cvFileId ?? this.cvFileId,
        diplomeFileId: diplomeFileId ?? this.diplomeFileId,
        autresFileId: autresFileId ?? this.autresFileId,
        createdAt: createdAt,
        createdBy: createdBy,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );
}