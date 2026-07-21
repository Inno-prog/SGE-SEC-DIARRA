import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ContractModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ContractModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      type: d['type'] ?? '',
      dateDebut: (d['dateDebut'] as Timestamp).toDate(),
      dateFin: (d['dateFin'] as Timestamp?)?.toDate(),
      dureeEnMois: d['dureeEnMois'],
      renouvellement: d['renouvellement'] ?? false,
      notes: d['notes'],
      piecesJointes: List<String>.from(d['piecesJointes'] ?? []),
      statut: d['statut'] ?? 'actif',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
        'dureeEnMois': dureeEnMois,
        'renouvellement': renouvellement,
        'notes': notes,
        'piecesJointes': piecesJointes,
        'statut': statut,
        'createdAt': Timestamp.fromDate(createdAt),
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
  final String statut; // present, absent, retard, conge
  final int retardMinutes;
  final String? justification;
  final String methode; // manuel, qr, badge
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

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      employeePhoto: d['employeePhoto'],
      date: (d['date'] as Timestamp).toDate(),
      heureArrivee: (d['heureArrivee'] as Timestamp?)?.toDate(),
      heureDepart: (d['heureDepart'] as Timestamp?)?.toDate(),
      statut: d['statut'] ?? 'absent',
      retardMinutes: d['retardMinutes'] ?? 0,
      justification: d['justification'],
      methode: d['methode'] ?? 'manuel',
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'employeePhoto': employeePhoto,
        'date': Timestamp.fromDate(date),
        'heureArrivee': heureArrivee != null ? Timestamp.fromDate(heureArrivee!) : null,
        'heureDepart': heureDepart != null ? Timestamp.fromDate(heureDepart!) : null,
        'statut': statut,
        'retardMinutes': retardMinutes,
        'justification': justification,
        'methode': methode,
        'createdBy': createdBy,
        'dateStr': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
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

  factory LeaveModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LeaveModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      employeePhoto: d['employeePhoto'],
      type: d['type'] ?? '',
      dateDebut: (d['dateDebut'] as Timestamp).toDate(),
      dateFin: (d['dateFin'] as Timestamp).toDate(),
      nombreJours: d['nombreJours'] ?? 0,
      motif: d['motif'] ?? '',
      statut: d['statut'] ?? 'en_attente',
      commentaireRH: d['commentaireRH'],
      validePar: d['validePar'],
      dateValidation: (d['dateValidation'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'employeePhoto': employeePhoto,
        'type': type,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'nombreJours': nombreJours,
        'motif': motif,
        'statut': statut,
        'commentaireRH': commentaireRH,
        'validePar': validePar,
        'dateValidation': dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
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
  final String statut; // brouillon, validé, payé
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

  factory PayrollModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PayrollModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      mois: d['mois'] ?? 1,
      annee: d['annee'] ?? DateTime.now().year,
      salaireBase: (d['salaireBase'] as num?)?.toDouble() ?? 0,
      primes: (d['primes'] as num?)?.toDouble() ?? 0,
      bonus: (d['bonus'] as num?)?.toDouble() ?? 0,
      heuresSupp: (d['heuresSupp'] as num?)?.toDouble() ?? 0,
      tauxHeureSupp: (d['tauxHeureSupp'] as num?)?.toDouble() ?? 0,
      retenues: (d['retenues'] as num?)?.toDouble() ?? 0,
      cotisationsSociales: (d['cotisationsSociales'] as num?)?.toDouble() ?? 0,
      impots: (d['impots'] as num?)?.toDouble() ?? 0,
      netAPayer: (d['netAPayer'] as num?)?.toDouble() ?? 0,
      statut: d['statut'] ?? 'brouillon',
      datePaiement: (d['datePaiement'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
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
        'datePaiement': datePaiement != null ? Timestamp.fromDate(datePaiement!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };
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

  factory SanctionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SanctionModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      type: d['type'] ?? '',
      motif: d['motif'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      dureeSuspension: d['dureeSuspension'],
      decisionPar: d['decisionPar'],
      statut: d['statut'] ?? 'actif',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'motif': motif,
        'date': Timestamp.fromDate(date),
        'dureeSuspension': dureeSuspension,
        'decisionPar': decisionPar,
        'statut': statut,
        'createdAt': Timestamp.fromDate(createdAt),
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

  factory TrainingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrainingModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      intitule: d['intitule'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      organisme: d['organisme'] ?? '',
      dureeJours: d['dureeJours'] ?? 1,
      attestationUrl: d['attestationUrl'],
      notes: d['notes'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'intitule': intitule,
        'date': Timestamp.fromDate(date),
        'organisme': organisme,
        'dureeJours': dureeJours,
        'attestationUrl': attestationUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
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

  factory EvaluationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EvaluationModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      annee: d['annee'] ?? DateTime.now().year,
      note: (d['note'] as num?)?.toDouble() ?? 0,
      commentaire: d['commentaire'] ?? '',
      objectifs: List<Map<String, dynamic>>.from(d['objectifs'] ?? []),
      evaluateurId: d['evaluateurId'] ?? '',
      evaluateurNom: d['evaluateurNom'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'annee': annee,
        'note': note,
        'commentaire': commentaire,
        'objectifs': objectifs,
        'evaluateurId': evaluateurId,
        'evaluateurNom': evaluateurNom,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class DocumentModel {
  final String id;
  final String employeeId;
  final String employeeNom;
  final String type; // contrat, diplome, cv, cni, certificat_medical
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

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      employeeId: d['employeeId'] ?? '',
      employeeNom: d['employeeNom'] ?? '',
      type: d['type'] ?? '',
      nom: d['nom'] ?? '',
      url: d['url'] ?? '',
      tailleFichier: d['tailleFichier'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'employeeId': employeeId,
        'employeeNom': employeeNom,
        'type': type,
        'nom': nom,
        'url': url,
        'tailleFichier': tailleFichier,
        'createdAt': Timestamp.fromDate(createdAt),
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
  final String statut; // ouvert, ferme, pourvu
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

  factory RecruitmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RecruitmentModel(
      id: doc.id,
      poste: d['poste'] ?? '',
      departementId: d['departementId'] ?? '',
      departementNom: d['departementNom'] ?? '',
      description: d['description'] ?? '',
      typeContrat: d['typeContrat'] ?? '',
      datePublication: (d['datePublication'] as Timestamp).toDate(),
      dateLimite: (d['dateLimite'] as Timestamp?)?.toDate(),
      statut: d['statut'] ?? 'ouvert',
      nombreCandidatures: d['nombreCandidatures'] ?? 0,
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'poste': poste,
        'departementId': departementId,
        'departementNom': departementNom,
        'description': description,
        'typeContrat': typeContrat,
        'datePublication': Timestamp.fromDate(datePublication),
        'dateLimite': dateLimite != null ? Timestamp.fromDate(dateLimite!) : null,
        'statut': statut,
        'nombreCandidatures': nombreCandidatures,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
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
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.message,
    required this.type,
    this.isRead = false,
    this.actionRoute,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      titre: d['titre'] ?? '',
      message: d['message'] ?? '',
      type: d['type'] ?? '',
      isRead: d['isRead'] ?? false,
      actionRoute: d['actionRoute'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'titre': titre,
        'message': message,
        'type': type,
        'isRead': isRead,
        'actionRoute': actionRoute,
        'createdAt': Timestamp.fromDate(createdAt),
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

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: d['conversationId'] ?? '',
      senderId: d['senderId'] ?? '',
      senderNom: d['senderNom'] ?? '',
      senderPhoto: d['senderPhoto'],
      contenu: d['contenu'] ?? '',
      piecesJointes: List<String>.from(d['piecesJointes'] ?? []),
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderNom': senderNom,
        'senderPhoto': senderPhoto,
        'contenu': contenu,
        'piecesJointes': piecesJointes,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AgendaModel {
  final String id;
  final String titre;
  final String? description;
  final String type; // reunion, rdv, conge, evenement
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

  factory AgendaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AgendaModel(
      id: doc.id,
      titre: d['titre'] ?? '',
      description: d['description'],
      type: d['type'] ?? '',
      dateDebut: (d['dateDebut'] as Timestamp).toDate(),
      dateFin: (d['dateFin'] as Timestamp).toDate(),
      participants: List<String>.from(d['participants'] ?? []),
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'titre': titre,
        'description': description,
        'type': type,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'participants': participants,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AuditLogModel {
  final String id;
  final String userId;
  final String userNom;
  final String action; // ajout, modification, suppression
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

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userNom: d['userNom'] ?? '',
      action: d['action'] ?? '',
      collection: d['collection'] ?? '',
      documentId: d['documentId'] ?? '',
      description: d['description'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userNom': userNom,
        'action': action,
        'collection': collection,
        'documentId': documentId,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
