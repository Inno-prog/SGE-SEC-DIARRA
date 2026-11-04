// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed - using REST API instead

class ContractModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String type;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final int? dureeEnMois;
  final bool renouvellement;
  final String? notes;
  final List<String> piecesJointes;
  final String statut;
  final DateTime createdAt;
  final String createdBy;

  ContractModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.type,
    required this.dateDebut,
    this.dateFin,
    this.dureeEnMois,
    this.renouvellement = false,
    this.notes,
    this.piecesJointes = const [],
    this.statut = 'actif',
    required this.createdAt,
    required this.createdBy,
  });

  bool get isExpiringSoon {
    if (dateFin == null) return false;
    return dateFin!.difference(DateTime.now()).inDays <= 30;
  }

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      type: json['type'] ?? '',
      dateDebut: DateTime.parse(json['dateDebut'] ?? json['date_debut'] ?? DateTime.now().toIso8601String()),
      dateFin: json['dateFin'] != null || json['date_fin'] != null
          ? DateTime.parse(json['dateFin'] ?? json['date_fin'] ?? DateTime.now().toIso8601String())
          : null,
      dureeEnMois: json['dureeEnMois'] ?? json['duree_en_mois'],
      renouvellement: json['renouvellement'] ?? false,
      notes: json['notes'],
      piecesJointes: List<String>.from(json['piecesJointes'] ?? json['pieces_jointes'] ?? []),
      statut: json['statut'] ?? 'actif',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'dateDebut': dateDebut.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'dateFin': dateFin?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'dureeEnMois': dureeEnMois,
        'renouvellement': renouvellement,
        'notes': notes,
        'piecesJointes': piecesJointes,
        'statut': statut,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
      };
}

class AttendanceModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String? employeePhoto;
  final DateTime date;
  final DateTime? heureArrivee;
  final DateTime? heureDepart;
  final String statut;
  final int retardMinutes;
  final String? justification;
  final String methode;
  final String createdBy;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    this.employeePhoto,
    required this.date,
    this.heureArrivee,
    this.heureDepart,
    required this.statut,
    this.retardMinutes = 0,
    this.justification,
    this.methode = 'manuel',
    required this.createdBy,
  });

  Duration? get dureePresence {
    if (heureArrivee == null || heureDepart == null) return null;
    return heureDepart!.difference(heureArrivee!);
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      employeePhoto: json['employeePhoto'] ?? json['employee_photo'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      heureArrivee: json['heureArrivee'] != null || json['heure_arrivee'] != null
          ? DateTime.parse(json['heureArrivee'] ?? json['heure_arrivee'] ?? DateTime.now().toIso8601String())
          : null,
      heureDepart: json['heureDepart'] != null || json['heure_depart'] != null
          ? DateTime.parse(json['heureDepart'] ?? json['heure_depart'] ?? DateTime.now().toIso8601String())
          : null,
      statut: json['statut'] ?? 'absent',
      retardMinutes: json['retardMinutes'] ?? json['retard_minutes'] ?? 0,
      justification: json['justification'],
      methode: json['methode'] ?? 'manuel',
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'employeePhoto': employeePhoto,
        'date': date.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'heureArrivee': heureArrivee?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'heureDepart': heureDepart?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'statut': statut,
        'retardMinutes': retardMinutes,
        if (justification != null && justification!.isNotEmpty) 'justification': justification,
        'methode': methode,
        'createdBy': createdBy,
      };
}

class LeaveModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String? employeePhoto;
  final String type;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nombreJours;
  final String motif;
  final String statut;
  final String? commentaireRH;
  final String? validePar;
  final DateTime? dateValidation;
  final DateTime createdAt;

  LeaveModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    this.employeePhoto,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    required this.nombreJours,
    required this.motif,
    this.statut = 'en_attente',
    this.commentaireRH,
    this.validePar,
    this.dateValidation,
    required this.createdAt,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      employeePhoto: json['employeePhoto'] ?? json['employee_photo'],
      type: json['type'] ?? '',
      dateDebut: DateTime.parse(json['dateDebut'] ?? json['date_debut'] ?? DateTime.now().toIso8601String()),
      dateFin: DateTime.parse(json['dateFin'] ?? json['date_fin'] ?? DateTime.now().toIso8601String()),
      nombreJours: json['nombreJours'] ?? json['nombre_jours'] ?? 0,
      motif: json['motif'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      commentaireRH: json['commentaireRH'] ?? json['commentaire_rh'],
      validePar: json['validePar'] ?? json['valide_par'],
      dateValidation: json['dateValidation'] != null || json['date_validation'] != null
          ? DateTime.parse(json['dateValidation'] ?? json['date_validation'] ?? DateTime.now().toIso8601String())
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'employeePhoto': employeePhoto,
        'type': type,
        'dateDebut': dateDebut.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'dateFin': dateFin.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'nombreJours': nombreJours,
        'motif': motif,
        'statut': statut,
        'commentaireRH': commentaireRH,
        'validePar': validePar,
        'dateValidation': dateValidation?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class PayrollModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final int mois;
  final int annee;
  final double salaireBase;
  final double primes;
  final double bonus;
  final double heuresSupp;
  final double tauxHeureSupp;
  final double retenues;
  final double cotisationsSociales;
  final double impots;
  final double netAPayer;
  final String statut;
  final DateTime? datePaiement;
  final DateTime createdAt;
  final String createdBy;

  PayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.mois,
    required this.annee,
    required this.salaireBase,
    this.primes = 0,
    this.bonus = 0,
    this.heuresSupp = 0,
    this.tauxHeureSupp = 0,
    this.retenues = 0,
    this.cotisationsSociales = 0,
    this.impots = 0,
    required this.netAPayer,
    this.statut = 'brouillon',
    this.datePaiement,
    required this.createdAt,
    required this.createdBy,
  });

  double get brutTotal => salaireBase + primes + bonus + (heuresSupp * tauxHeureSupp);
  double get totalDeductions => retenues + cotisationsSociales + impots;

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      mois: json['mois'] ?? 1,
      annee: json['annee'] ?? DateTime.now().year,
      salaireBase: (json['salaireBase'] ?? json['salaire_base'] ?? 0).toDouble(),
      primes: (json['primes'] ?? 0).toDouble(),
      bonus: (json['bonus'] ?? 0).toDouble(),
      heuresSupp: (json['heuresSupp'] ?? json['heures_supp'] ?? 0).toDouble(),
      tauxHeureSupp: (json['tauxHeureSupp'] ?? json['taux_heure_supp'] ?? 0).toDouble(),
      retenues: (json['retenues'] ?? 0).toDouble(),
      cotisationsSociales: (json['cotisationsSociales'] ?? json['cotisations_sociales'] ?? 0).toDouble(),
      impots: (json['impots'] ?? 0).toDouble(),
      netAPayer: (json['netAPayer'] ?? json['net_a_payer'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'brouillon',
      datePaiement: json['datePaiement'] != null || json['date_paiement'] != null
          ? DateTime.parse(json['datePaiement'] ?? json['date_paiement'] ?? DateTime.now().toIso8601String())
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'mois': mois,
        'annee': annee,
        'salaireBase': salaireBase,
        'primes': primes,
        'bonus': bonus,
        'heuresSupp': heuresSupp,
        'tauxHeureSupp': tauxHeureSupp,
        'retenues': retenues,
        'cotisationsSociales': cotisationsSociales,
        'impots': impots,
        'netAPayer': netAPayer,
        'statut': statut,
        'datePaiement': datePaiement?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
      };

  PayrollModel copyWith({
    String? id,
    String? employeeId,
    String? employeeNom,
    int? mois,
    int? annee,
    double? salaireBase,
    double? primes,
    double? bonus,
    double? heuresSupp,
    double? tauxHeureSupp,
    double? retenues,
    double? cotisationsSociales,
    double? impots,
    double? netAPayer,
    String? statut,
    DateTime? datePaiement,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return PayrollModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeNom: employeeNom ?? this.employeeNom,
      mois: mois ?? this.mois,
      annee: annee ?? this.annee,
      salaireBase: salaireBase ?? this.salaireBase,
      primes: primes ?? this.primes,
      bonus: bonus ?? this.bonus,
      heuresSupp: heuresSupp ?? this.heuresSupp,
      tauxHeureSupp: tauxHeureSupp ?? this.tauxHeureSupp,
      retenues: retenues ?? this.retenues,
      cotisationsSociales: cotisationsSociales ?? this.cotisationsSociales,
      impots: impots ?? this.impots,
      netAPayer: netAPayer ?? this.netAPayer,
      statut: statut ?? this.statut,
      datePaiement: datePaiement ?? this.datePaiement,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class SanctionModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String type;
  final String motif;
  final DateTime date;
  final int? dureeSuspension;
  final String? decisionPar;
  final String statut;
  final DateTime createdAt;
  final String createdBy;

  SanctionModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.type,
    required this.motif,
    required this.date,
    this.dureeSuspension,
    this.decisionPar,
    this.statut = 'actif',
    required this.createdAt,
    required this.createdBy,
  });

  factory SanctionModel.fromJson(Map<String, dynamic> json) {
    return SanctionModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      type: json['type'] ?? '',
      motif: json['motif'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      dureeSuspension: json['dureeSuspension'] ?? json['duree_suspension'],
      decisionPar: json['decisionPar'] ?? json['decision_par'],
      statut: json['statut'] ?? 'actif',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'motif': motif,
        'date': date.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'dureeSuspension': dureeSuspension,
        'decisionPar': decisionPar,
        'statut': statut,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
      };
}

class TrainingModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String intitule;
  final DateTime date;
  final String organisme;
  final int dureeJours;
  final String? attestationUrl;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  TrainingModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.intitule,
    required this.date,
    required this.organisme,
    required this.dureeJours,
    this.attestationUrl,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      intitule: json['intitule'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      organisme: json['organisme'] ?? '',
      dureeJours: json['dureeJours'] ?? json['duree_jours'] ?? 1,
      attestationUrl: json['attestationUrl'] ?? json['attestation_url'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'intitule': intitule,
        'date': date.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'organisme': organisme,
        'dureeJours': dureeJours,
        'attestationUrl': attestationUrl,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
      };
}

class EvaluationModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final int annee;
  final double note;
  final String commentaire;
  final List<Map<String, dynamic>> objectifs;
  final String evaluateurId;
  final String evaluateurNom;
  final DateTime createdAt;

  EvaluationModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.annee,
    required this.note,
    required this.commentaire,
    this.objectifs = const [],
    required this.evaluateurId,
    required this.evaluateurNom,
    required this.createdAt,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      annee: json['annee'] ?? DateTime.now().year,
      note: (json['note'] ?? 0).toDouble(),
      commentaire: json['commentaire'] ?? '',
      objectifs: List<Map<String, dynamic>>.from(json['objectifs'] ?? []),
      evaluateurId: json['evaluateurId'] ?? json['evaluateur_id'] ?? '',
      evaluateurNom: json['evaluateurNom'] ?? json['evaluateur_nom'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'annee': annee,
        'note': note,
        'commentaire': commentaire,
        'objectifs': objectifs,
        'evaluateurId': evaluateurId,
        'evaluateurNom': evaluateurNom,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class DocumentModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String type;
  final String nom;
  final String url;
  final int tailleFichier;
  final DateTime createdAt;
  final String createdBy;

  DocumentModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.type,
    required this.nom,
    required this.url,
    required this.tailleFichier,
    required this.createdAt,
    required this.createdBy,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      type: json['type'] ?? '',
      nom: json['nom'] ?? '',
      url: json['url'] ?? '',
      tailleFichier: json['tailleFichier'] ?? json['taille_fichier'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'nom': nom,
        'url': url,
        'tailleFichier': tailleFichier,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
      };
}

class RecruitmentModel {
  final String id;
  final String poste;
  final String departementId;
  final String departementNom;
  final String description;
  final String typeContrat;
  final DateTime datePublication;
  final DateTime? dateLimite;
  final String statut;
  final int nombreCandidatures;
  final String createdBy;
  final DateTime createdAt;

  RecruitmentModel({
    required this.id,
    required this.poste,
    required this.departementId,
    required this.departementNom,
    required this.description,
    required this.typeContrat,
    required this.datePublication,
    this.dateLimite,
    this.statut = 'ouvert',
    this.nombreCandidatures = 0,
    required this.createdBy,
    required this.createdAt,
  });

  factory RecruitmentModel.fromJson(Map<String, dynamic> json) {
    return RecruitmentModel(
      id: json['id'] ?? '',
      poste: json['poste'] ?? '',
      departementId: json['departementId'] ?? json['departement_id'] ?? '',
      departementNom: json['departementNom'] ?? json['departement_nom'] ?? '',
      description: json['description'] ?? '',
      typeContrat: json['typeContrat'] ?? json['type_contrat'] ?? '',
      datePublication: DateTime.parse(json['datePublication'] ?? json['date_publication'] ?? DateTime.now().toIso8601String()),
      dateLimite: json['dateLimite'] != null || json['date_limite'] != null
          ? DateTime.parse(json['dateLimite'] ?? json['date_limite'] ?? DateTime.now().toIso8601String())
          : null,
      statut: json['statut'] ?? 'ouvert',
      nombreCandidatures: json['nombreCandidatures'] ?? json['nombre_candidatures'] ?? 0,
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'poste': poste,
        'departementId': departementId,
        'departementNom': departementNom,
        'description': description,
        'typeContrat': typeContrat,
        'datePublication': datePublication.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'dateLimite': dateLimite?.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'statut': statut,
        'nombreCandidatures': nombreCandidatures,
        'createdBy': createdBy,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class NotificationModel {
  final String id;
  final String userId;
  final String titre;
  final String message;
  final String type;
  final bool isRead;
  final String? actionRoute;
  final String? contractId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.message,
    required this.type,
    this.isRead = false,
    this.actionRoute,
    this.contractId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      actionRoute: json['actionRoute'] ?? json['action_route'],
      contractId: json['contractId'] ?? json['contract_id'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'titre': titre,
        'message': message,
        'type': type,
        'isRead': isRead,
        'actionRoute': actionRoute,
        'contractId': contractId,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderNom;
  final String? senderPhoto;
  final String contenu;
  final List<String> piecesJointes;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderNom,
    this.senderPhoto,
    required this.contenu,
    this.piecesJointes = const [],
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderNom: json['senderNom'] ?? json['sender_nom'] ?? '',
      senderPhoto: json['senderPhoto'] ?? json['sender_photo'],
      contenu: json['contenu'] ?? '',
      piecesJointes: List<String>.from(json['piecesJointes'] ?? json['pieces_jointes'] ?? []),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderNom': senderNom,
        'senderPhoto': senderPhoto,
        'contenu': contenu,
        'piecesJointes': piecesJointes,
        'isRead': isRead,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class AgendaModel {
  final String id;
  final String titre;
  final String? description;
  final String type;
  final DateTime dateDebut;
  final DateTime dateFin;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;

  AgendaModel({
    required this.id,
    required this.titre,
    this.description,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    this.participants = const [],
    required this.createdBy,
    required this.createdAt,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) {
    return AgendaModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'],
      type: json['type'] ?? '',
      dateDebut: DateTime.parse(json['dateDebut'] ?? json['date_debut'] ?? DateTime.now().toIso8601String()),
      dateFin: DateTime.parse(json['dateFin'] ?? json['date_fin'] ?? DateTime.now().toIso8601String()),
      participants: List<String>.from(json['participants'] ?? []),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'type': type,
        'dateDebut': dateDebut.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'dateFin': dateFin.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'participants': participants,
        'createdBy': createdBy,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class AuditLogModel {
  final String id;
  final String userId;
  final String userNom;
  final String action;
  final String collection;
  final String documentId;
  final String description;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userNom,
    required this.action,
    required this.collection,
    required this.documentId,
    required this.description,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userNom: json['userNom'] ?? json['user_nom'] ?? '',
      action: json['action'] ?? '',
      collection: json['collection'] ?? '',
      documentId: json['documentId'] ?? json['document_id'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userNom': userNom,
        'action': action,
        'collection': collection,
        'documentId': documentId,
        'description': description,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
      };
}

class BonusModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String type;
  final double montant;
  final String motif;
  final DateTime dateAttribution;
  final String statut;
  final DateTime createdAt;
  final String createdBy;

  BonusModel({
    required this.id,
    required this.employeeId,
    required this.employeeNom,
    required this.type,
    required this.montant,
    required this.motif,
    required this.dateAttribution,
    this.statut = 'active',
    required this.createdAt,
    required this.createdBy,
  });

  factory BonusModel.fromJson(Map<String, dynamic> json) {
    return BonusModel(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      employeeNom: json['employeeNom'] ?? json['employee_nom'] ?? '',
      type: json['type'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      motif: json['motif'] ?? '',
      dateAttribution: DateTime.parse(json['dateAttribution'] ?? json['date_attribution'] ?? DateTime.now().toIso8601String()),
      statut: json['statut'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'montant': montant,
        'motif': motif,
        'dateAttribution': dateAttribution.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'statut': statut,
        'createdAt': createdAt.toUtc().toIso8601String().replaceAll('+00:00', 'Z'),
        'createdBy': createdBy,
      };
}