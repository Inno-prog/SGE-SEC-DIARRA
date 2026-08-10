import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String nom;
  final String telephone;
  final String relation;

  EmergencyContact({required this.nom, required this.telephone, required this.relation});

  factory EmergencyContact.fromMap(Map<String, dynamic> m) =>
      EmergencyContact(nom: m['nom'] ?? '', telephone: m['telephone'] ?? '', relation: m['relation'] ?? '');

  Map<String, dynamic> toMap() => {'nom': nom, 'telephone': telephone, 'relation': relation};
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
  });

  String get fullName => '$prenom $nom';

  int get anciennete {
    final now = DateTime.now();
    return now.year - dateEmbauche.year;
  }

  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EmployeeModel(
      id: doc.id,
      matricule: d['matricule'] ?? '',
      nom: d['nom'] ?? '',
      prenom: d['prenom'] ?? '',
      sexe: d['sexe'] ?? '',
      dateNaissance: (d['dateNaissance'] as Timestamp).toDate(),
      photoUrl: d['photoUrl'],
      adresse: d['adresse'] ?? '',
      telephone: d['telephone'] ?? '',
      email: d['email'] ?? '',
      situationMatrimoniale: d['situationMatrimoniale'] ?? '',
      nationalite: d['nationalite'] ?? '',
      contactUrgence: d['contactUrgence'] != null
          ? EmergencyContact.fromMap(d['contactUrgence'])
          : null,
      poste: d['poste'] ?? '',
      service: d['service'] ?? '',
      departementId: d['departementId'] ?? '',
      departementNom: d['departementNom'] ?? '',
      grade: d['grade'] ?? '',
      dateEmbauche: (d['dateEmbauche'] as Timestamp).toDate(),
      typeContrat: d['typeContrat'] ?? '',
      salaire: (d['salaire'] ?? 0).toDouble(),
      statut: d['statut'] ?? 'actif',
      soldeCongesAnnuels: d['soldeCongesAnnuels'] ?? 30,
      soldeCongesMaladie: d['soldeCongesMaladie'] ?? 15,
      contratSigneFileId: d['contratSigneFileId'],
      demandeFileId: d['demandeFileId'],
      cvFileId: d['cvFileId'],
      diplomeFileId: d['diplomeFileId'],
      autresFileId: d['autresFileId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'sexe': sexe,
        'dateNaissance': Timestamp.fromDate(dateNaissance),
        'photoUrl': photoUrl,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'situationMatrimoniale': situationMatrimoniale,
        'nationalite': nationalite,
        'contactUrgence': contactUrgence?.toMap(),
        'poste': poste,
        'service': service,
        'departementId': departementId,
        'departementNom': departementNom,
        'grade': grade,
        'dateEmbauche': Timestamp.fromDate(dateEmbauche),
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
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'searchIndex': [
          nom.toLowerCase(),
          prenom.toLowerCase(),
          matricule.toLowerCase(),
          email.toLowerCase(),
          departementNom.toLowerCase(),
          poste.toLowerCase(),
        ],
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
      );
}
