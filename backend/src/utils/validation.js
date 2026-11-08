import { z } from 'zod';

// Auth schemas
export const loginSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
});

export const registerSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
  nom: z.string().min(1, 'Le nom est requis'),
  prenom: z.string().min(1, 'Le prénom est requis'),
  role: z.enum(['admin', 'manager', 'employee', 'hr']).default('employee'),
  employeeId: z.string().uuid().optional(),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token requis'),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Mot de passe actuel requis'),
  newPassword: z.string().min(6, 'Le nouveau mot de passe doit contenir au moins 6 caractères'),
});

export const resetPasswordSchema = z.object({
  email: z.string().email('Email invalide'),
});

export const updateProfileSchema = z.object({
  nom: z.string().min(1).optional(),
  prenom: z.string().min(1).optional(),
  photoUrl: z.string().url().optional().nullable(),
  darkMode: z.boolean().optional(),
  emailNotifications: z.boolean().optional(),
});

// User schemas
export const createUserSchema = z.object({
  email: z.string().email('Email invalide'),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
  nom: z.string().min(1, 'Le nom est requis'),
  prenom: z.string().min(1, 'Le prénom est requis'),
  role: z.enum(['admin', 'manager', 'employee', 'hr']).default('employee'),
  employeeId: z.string().uuid().optional().nullable(),
  permissions: z.array(z.string()).default([]),
});

export const updateUserSchema = z.object({
  nom: z.string().min(1).optional(),
  prenom: z.string().min(1).optional(),
  role: z.enum(['admin', 'manager', 'employee', 'hr']).optional(),
  employeeId: z.string().uuid().optional().nullable(),
  isActive: z.boolean().optional(),
  permissions: z.array(z.string()).optional(),
  darkMode: z.boolean().optional(),
  emailNotifications: z.boolean().optional(),
  mustChangePassword: z.boolean().optional(),
});

// Employee schemas
export const createEmployeeSchema = z.object({
  matricule: z.string().min(1, 'Le matricule est requis'),
  nom: z.string().min(1, 'Le nom est requis'),
  prenom: z.string().min(1, 'Le prénom est requis'),
  sexe: z.enum(['M', 'F']),
  dateNaissance: z.string().datetime(),
  photoUrl: z.string().url().optional().nullable(),
  adresse: z.string().min(1, 'L\'adresse est requise'),
  telephone: z.string().min(1, 'Le téléphone est requis'),
  email: z.string().email('Email invalide'),
  situationMatrimoniale: z.string().min(1, 'La situation matrimoniale est requise'),
  nationalite: z.string().optional(),
  contactUrgenceNom: z.string().optional(),
  contactUrgenceTel: z.string().optional(),
  contactUrgenceRelation: z.string().optional(),
  poste: z.string().min(1, 'Le poste est requis'),
  service: z.string().min(1, 'Le service est requis'),
  departementId: z.string().uuid('ID département invalide'),
  departementNom: z.string().min(1, 'Le nom du département est requis'),
  grade: z.string().min(1, 'Le grade est requis'),
  dateEmbauche: z.string().datetime(),
  typeContrat: z.enum(['CDI', 'CDD', 'stage', 'freelance']),
  salaire: z.number().positive('Le salaire doit être positif'),
  statut: z.enum(['actif', 'inactif', 'conge', 'suspendu']).default('actif'),
  soldeCongesAnnuels: z.number().int().min(0).default(30),
  soldeCongesMaladie: z.number().int().min(0).default(15),
});

export const updateEmployeeSchema = z.object({
  nom: z.string().min(1).optional(),
  prenom: z.string().min(1).optional(),
  photoUrl: z.string().url().optional().nullable(),
  adresse: z.string().optional(),
  telephone: z.string().optional(),
  email: z.string().email().optional(),
  situationMatrimoniale: z.string().optional(),
  nationalite: z.string().optional(),
  contactUrgenceNom: z.string().optional(),
  contactUrgenceTel: z.string().optional(),
  contactUrgenceRelation: z.string().optional(),
  poste: z.string().optional(),
  service: z.string().optional(),
  departementId: z.string().uuid().optional(),
  departementNom: z.string().optional(),
  grade: z.string().optional(),
  typeContrat: z.enum(['CDI', 'CDD', 'stage', 'freelance']).optional(),
  salaire: z.number().positive().optional(),
  statut: z.enum(['actif', 'inactif', 'conge', 'suspendu']).optional(),
  soldeCongesAnnuels: z.number().int().min(0).optional(),
  soldeCongesMaladie: z.number().int().min(0).optional(),
  contratSigneFileId: z.string().optional().nullable(),
  demandeFileId: z.string().optional().nullable(),
  cvFileId: z.string().optional().nullable(),
  diplomeFileId: z.string().optional().nullable(),
  autresFileId: z.string().optional().nullable(),
});

// Department schemas
export const createDepartmentSchema = z.object({
  nom: z.string().min(1, 'Le nom est requis'),
  description: z.string().optional(),
  responsableId: z.string().uuid().optional().nullable(),
});

export const updateDepartmentSchema = z.object({
  nom: z.string().min(1).optional(),
  description: z.string().optional().nullable(),
  responsableId: z.string().uuid().optional().nullable(),
});

// Position schemas
export const createPositionSchema = z.object({
  titre: z.string().min(1, 'Le titre est requis'),
  description: z.string().optional(),
  departementId: z.string().uuid().optional().nullable(),
  salaireMini: z.number().positive().optional(),
  salaireMaxi: z.number().positive().optional(),
});

export const updatePositionSchema = z.object({
  titre: z.string().min(1).optional(),
  description: z.string().optional().nullable(),
  departementId: z.string().uuid().optional().nullable(),
  salaireMini: z.number().positive().optional(),
  salaireMaxi: z.number().positive().optional(),
});

// Contract schemas
export const createContractSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  type: z.enum(['CDI', 'CDD', 'stage', 'freelance']),
  dateDebut: z.string().datetime(),
  dateFin: z.string().datetime().optional().nullable(),
  dureeEnMois: z.number().int().positive().optional(),
  renouvellement: z.boolean().default(false),
  notes: z.string().optional(),
  piecesJointes: z.array(z.string()).default([]),
  statut: z.enum(['actif', 'expire', 'resilie', 'en_attente']).default('actif'),
});

export const updateContractSchema = z.object({
  type: z.enum(['CDI', 'CDD', 'stage', 'freelance']).optional(),
  dateDebut: z.string().datetime().optional(),
  dateFin: z.string().datetime().optional().nullable(),
  dureeEnMois: z.number().int().positive().optional(),
  renouvellement: z.boolean().optional(),
  notes: z.string().optional(),
  piecesJointes: z.array(z.string()).optional(),
  statut: z.enum(['actif', 'expire', 'resilie', 'en_attente']).optional(),
});

// Attendance schemas
export const createAttendanceSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  employeePhoto: z.string().url().optional().nullable(),
  date: z.string().datetime(),
  heureArrivee: z.string().datetime().optional().nullable(),
  heureDepart: z.string().datetime().optional().nullable(),
  statut: z.enum(['present', 'absent', 'retard', 'conge', 'mission']).default('present'),
  retardMinutes: z.number().int().min(0).default(0),
  justification: z.string().optional(),
  methode: z.string().default('manuel'),
});

export const updateAttendanceSchema = z.object({
  heureArrivee: z.string().datetime().optional().nullable(),
  heureDepart: z.string().datetime().optional().nullable(),
  statut: z.enum(['present', 'absent', 'retard', 'conge', 'mission']).optional(),
  retardMinutes: z.number().int().min(0).optional(),
  justification: z.string().optional(),
  methode: z.string().optional(),
});

// Leave schemas
export const createLeaveSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  employeePhoto: z.string().url().optional().nullable(),
  type: z.enum(['annuel', 'maladie', 'maternite', 'paternite', 'exceptionnel', 'sans_solde']),
  dateDebut: z.string().datetime(),
  dateFin: z.string().datetime(),
  nombreJours: z.number().int().positive('Le nombre de jours doit être positif'),
  motif: z.string().min(1, 'Le motif est requis'),
  statut: z.enum(['en_attente', 'approuve', 'rejete', 'annule']).default('en_attente'),
});

export const updateLeaveSchema = z.object({
  type: z.enum(['annuel', 'maladie', 'maternite', 'paternite', 'exceptionnel', 'sans_solde']).optional(),
  dateDebut: z.string().datetime().optional(),
  dateFin: z.string().datetime().optional(),
  nombreJours: z.number().int().positive().optional(),
  motif: z.string().optional(),
  statut: z.enum(['en_attente', 'approuve', 'rejete', 'annule']).optional(),
  commentaireRH: z.string().optional(),
  validePar: z.string().uuid().optional().nullable(),
});

/// Schema for the dedicated leave-status endpoint used by the UI
/// (PATCH /leaves/:id/status). Accepts the flat payload sent by the app:
/// { status, validatedBy, comment }
export const updateLeaveStatusSchema = z.object({
  status: z.enum(['en_attente', 'approuve', 'rejete', 'annule']),
  validatedBy: z.string().min(1, 'ID validateur requis'),
  comment: z.string().optional().nullable(),
});

// Payroll schemas
export const createPayrollSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  mois: z.number().int().min(1).max(12),
  annee: z.number().int().min(2000).max(2100),
  salaireBase: z.number().min(0),
  primes: z.number().min(0).default(0),
  bonus: z.number().min(0).default(0),
  heuresSupp: z.number().min(0).default(0),
  tauxHeureSupp: z.number().min(0).default(0),
  retenues: z.number().min(0).default(0),
  cotisationsSociales: z.number().min(0).default(0),
  impots: z.number().min(0).default(0),
  netAPayer: z.number().min(0),
  statut: z.enum(['brouillon', 'valide', 'paye']).default('brouillon'),
  datePaiement: z.string().datetime().optional().nullable(),
});

export const updatePayrollSchema = z.object({
  salaireBase: z.number().min(0).optional(),
  primes: z.number().min(0).optional(),
  bonus: z.number().min(0).optional(),
  heuresSupp: z.number().min(0).optional(),
  tauxHeureSupp: z.number().min(0).optional(),
  retenues: z.number().min(0).optional(),
  cotisationsSociales: z.number().min(0).optional(),
  impots: z.number().min(0).optional(),
  netAPayer: z.number().min(0).optional(),
  statut: z.enum(['brouillon', 'valide', 'paye']).optional(),
  datePaiement: z.string().datetime().optional().nullable(),
});

// Bonus schemas
export const createBonusSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  type: z.string().min(1, 'Le type est requis'),
  montant: z.number().positive('Le montant doit être positif'),
  motif: z.string().min(1, 'Le motif est requis'),
  dateAttribution: z.string().datetime(),
  statut: z.enum(['active', 'paye', 'annule']).default('active'),
});

export const updateBonusSchema = z.object({
  type: z.string().optional(),
  montant: z.number().positive().optional(),
  motif: z.string().optional(),
  dateAttribution: z.string().datetime().optional(),
  statut: z.enum(['active', 'paye', 'annule']).optional(),
});

// Sanction schemas
export const createSanctionSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  type: z.string().min(1, 'Le type est requis'),
  motif: z.string().min(1, 'Le motif est requis'),
  date: z.string().datetime(),
  dureeSuspension: z.number().int().positive().optional(),
  decisionPar: z.string().optional(),
  statut: z.enum(['actif', 'leve', 'expire']).default('actif'),
});

export const updateSanctionSchema = z.object({
  type: z.string().optional(),
  motif: z.string().optional(),
  date: z.string().datetime().optional(),
  dureeSuspension: z.number().int().positive().optional(),
  decisionPar: z.string().optional(),
  statut: z.enum(['actif', 'leve', 'expire']).optional(),
});

// Training schemas
export const createTrainingSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  intitule: z.string().min(1, 'L\'intitulé est requis'),
  date: z.string().datetime(),
  organisme: z.string().min(1, 'L\'organisme est requis'),
  dureeJours: z.number().int().positive('La durée doit être positive'),
  attestationUrl: z.string().url().optional().nullable(),
  notes: z.string().optional(),
});

export const updateTrainingSchema = z.object({
  intitule: z.string().optional(),
  date: z.string().datetime().optional(),
  organisme: z.string().optional(),
  dureeJours: z.number().int().positive().optional(),
  attestationUrl: z.string().url().optional().nullable(),
  notes: z.string().optional(),
});

// Evaluation schemas
export const createEvaluationSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  annee: z.number().int().min(2000).max(2100),
  note: z.number().min(0).max(20),
  commentaire: z.string().min(1, 'Le commentaire est requis'),
  objectifs: z.array(z.object({
    titre: z.string(),
    description: z.string().optional(),
    atteint: z.boolean(),
  })).default([]),
  evaluateurId: z.string().uuid('ID évaluateur invalide'),
  evaluateurNom: z.string().min(1, 'Le nom de l\'évaluateur est requis'),
});

export const updateEvaluationSchema = z.object({
  note: z.number().min(0).max(20).optional(),
  commentaire: z.string().optional(),
  objectifs: z.array(z.object({
    titre: z.string(),
    description: z.string().optional(),
    atteint: z.boolean(),
  })).optional(),
});

// Document schemas
export const createDocumentSchema = z.object({
  employeeId: z.string().uuid('ID employé invalide'),
  employeeNom: z.string().min(1, 'Le nom de l\'employé est requis'),
  type: z.enum(['contrat', 'diplome', 'cv', 'cni', 'certificat_medical', 'autre']),
  nom: z.string().min(1, 'Le nom est requis'),
  url: z.string().url('URL invalide'),
  tailleFichier: z.number().int().positive('La taille doit être positive'),
});

export const updateDocumentSchema = z.object({
  type: z.enum(['contrat', 'diplome', 'cv', 'cni', 'certificat_medical', 'autre']).optional(),
  nom: z.string().optional(),
  url: z.string().url().optional(),
  tailleFichier: z.number().int().positive().optional(),
});

// Recruitment schemas
export const createRecruitmentSchema = z.object({
  poste: z.string().min(1, 'Le poste est requis'),
  departementId: z.string().uuid('ID département invalide'),
  departementNom: z.string().min(1, 'Le nom du département est requis'),
  description: z.string().min(1, 'La description est requise'),
  typeContrat: z.enum(['CDI', 'CDD', 'stage', 'freelance']),
  datePublication: z.string().datetime(),
  dateLimite: z.string().datetime().optional().nullable(),
  statut: z.enum(['ouvert', 'ferme', 'pourvu']).default('ouvert'),
});

export const updateRecruitmentSchema = z.object({
  poste: z.string().optional(),
  departementId: z.string().uuid().optional(),
  departementNom: z.string().optional(),
  description: z.string().optional(),
  typeContrat: z.enum(['CDI', 'CDD', 'stage', 'freelance']).optional(),
  datePublication: z.string().datetime().optional(),
  dateLimite: z.string().datetime().optional().nullable(),
  statut: z.enum(['ouvert', 'ferme', 'pourvu']).optional(),
  nombreCandidatures: z.number().int().min(0).optional(),
});

// Notification schemas
export const createNotificationSchema = z.object({
  userId: z.string().uuid('ID utilisateur invalide'),
  titre: z.string().min(1, 'Le titre est requis'),
  message: z.string().min(1, 'Le message est requis'),
  type: z.enum(['info', 'warning', 'success', 'error', 'contract_expiry', 'leave_request', 'payroll']).default('info'),
  actionRoute: z.string().optional(),
  contractId: z.string().uuid().optional().nullable(),
});

export const updateNotificationSchema = z.object({
  isRead: z.boolean().optional(),
});

// Conversation schemas
export const createConversationSchema = z.object({
  nom: z.string().min(1, 'Le nom est requis'),
  participantIds: z.array(z.string().uuid()).min(2, 'Au moins 2 participants requis'),
});

export const updateConversationSchema = z.object({
  nom: z.string().optional(),
});

// Message schemas
export const createMessageSchema = z.object({
  conversationId: z.string().uuid('ID conversation invalide'),
  contenu: z.string().min(1, 'Le contenu est requis'),
  piecesJointes: z.array(z.string()).default([]),
});

export const updateMessageSchema = z.object({
  isRead: z.boolean().optional(),
});

// Agenda schemas
export const createAgendaSchema = z.object({
  titre: z.string().min(1, 'Le titre est requis'),
  description: z.string().optional(),
  type: z.enum(['reunion', 'rdv', 'conge', 'evenement']),
  dateDebut: z.string().datetime(),
  dateFin: z.string().datetime(),
  participants: z.array(z.string()).default([]),
});

export const updateAgendaSchema = z.object({
  titre: z.string().optional(),
  description: z.string().optional().nullable(),
  type: z.enum(['reunion', 'rdv', 'conge', 'evenement']).optional(),
  dateDebut: z.string().datetime().optional(),
  dateFin: z.string().datetime().optional(),
  participants: z.array(z.string()).optional(),
});

// Schedule schemas
export const createScheduleSchema = z.object({
  nom: z.string().min(1, 'Le nom est requis'),
  debut: z.string().min(1, 'L\'heure de début est requise'),
  fin: z.string().min(1, 'L\'heure de fin est requise'),
  jours: z.string().min(1, 'Les jours sont requis'),
  type: z.enum(['normal', 'nuit', 'week_end', 'flexible']).default('normal'),
});

export const updateScheduleSchema = z.object({
  nom: z.string().optional(),
  debut: z.string().optional(),
  fin: z.string().optional(),
  jours: z.string().optional(),
  type: z.enum(['normal', 'nuit', 'week_end', 'flexible']).optional(),
});

// Query schemas
export const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export const dateRangeSchema = z.object({
  dateDebut: z.string().datetime().optional(),
  dateFin: z.string().datetime().optional(),
});

export const employeeQuerySchema = paginationSchema.extend({
  departementId: z.string().uuid().optional(),
  statut: z.enum(['actif', 'inactif', 'conge', 'suspendu']).optional(),
  search: z.string().optional(),
});

export const attendanceQuerySchema = paginationSchema.extend({
  employeeId: z.string().uuid().optional(),
  date: z.string().datetime().optional(),
  dateDebut: z.string().datetime().optional(),
  dateFin: z.string().datetime().optional(),
});

export const leaveQuerySchema = paginationSchema.extend({
  employeeId: z.string().uuid().optional(),
  statut: z.enum(['en_attente', 'approuve', 'rejete', 'annule']).optional(),
  type: z.enum(['annuel', 'maladie', 'maternite', 'paternite', 'exceptionnel', 'sans_solde']).optional(),
});

export const payrollQuerySchema = paginationSchema.extend({
  employeeId: z.string().uuid().optional(),
  mois: z.coerce.number().int().min(1).max(12).optional(),
  annee: z.coerce.number().int().min(2000).max(2100).optional(),
  statut: z.enum(['brouillon', 'valide', 'paye']).optional(),
});

export const bonusQuerySchema = paginationSchema.extend({
  employeeId: z.string().uuid().optional(),
  statut: z.enum(['active', 'paye', 'annule']).optional(),
});

export const contractQuerySchema = paginationSchema.extend({
  employeeId: z.string().uuid().optional(),
  statut: z.enum(['actif', 'expire', 'resilie', 'en_attente']).optional(),
  type: z.enum(['CDI', 'CDD', 'stage', 'freelance']).optional(),
});

export const auditQuerySchema = paginationSchema.extend({
  userId: z.string().uuid().optional(),
  action: z.string().optional(),
  collection: z.string().optional(),
  dateDebut: z.string().datetime().optional(),
  dateFin: z.string().datetime().optional(),
});

// Helper to validate request body
export const validate = (schema) => (req, res, next) => {
  try {
    req.body = schema.parse(req.body);
    next();
  } catch (error) {
    next(error);
  }
};

// Helper to validate query params
export const validateQuery = (schema) => (req, res, next) => {
  try {
    req.query = schema.parse(req.query);
    next();
  } catch (error) {
    next(error);
  }
};

// Helper to validate params
export const validateParams = (schema) => (req, res, next) => {
  try {
    req.params = schema.parse(req.params);
    next();
  } catch (error) {
    next(error);
  }
};

export const updateUserStatusSchema = z.object({
  isActive: z.boolean(),
});

export const idParamSchema = z.object({
  id: z.string().uuid('ID invalide'),
});