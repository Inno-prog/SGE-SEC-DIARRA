import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createEvaluationSchema,
  updateEvaluationSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getEvaluations = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, annee } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (annee) where.annee = parseInt(annee);

    const [evaluations, total] = await Promise.all([
      prisma.evaluation.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { annee: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.evaluation.count({ where }),
    ]);

    res.json({
      data: evaluations,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getEvaluationById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const evaluation = await prisma.evaluation.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!evaluation) {
      throw new NotFoundError('Évaluation');
    }

    res.json({ evaluation });
  } catch (error) {
    next(error);
  }
};

export const createEvaluation = async (req, res, next) => {
  try {
    const data = createEvaluationSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const evaluator = await prisma.user.findUnique({ where: { id: data.evaluateurId } });
    if (!evaluator) {
      throw new NotFoundError('Évaluateur');
    }

    const evaluation = await prisma.evaluation.create({
      data: {
        ...data,
        createdBy: req.user.id,
      },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'evaluations',
        documentId: evaluation.id,
        description: `Évaluation pour ${employee.prenom} ${employee.nom} - ${data.annee}`,
      },
    });

    // Notify employee
    const employeeUser = await prisma.user.findFirst({
      where: { employeeId: employee.id },
      select: { id: true },
    });
    if (employeeUser) {
      await prisma.notification.create({
        data: {
          userId: employeeUser.id,
          titre: 'Nouvelle évaluation',
          message: `Une évaluation pour l'année ${data.annee} a été créée`,
          type: 'info',
          actionRoute: `/evaluations/${evaluation.id}`,
        },
      });
    }

    res.status(201).json({ evaluation });
  } catch (error) {
    next(error);
  }
};

export const updateEvaluation = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateEvaluationSchema.parse(req.body);

    const existing = await prisma.evaluation.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Évaluation');
    }

    const evaluation = await prisma.evaluation.update({
      where: { id },
      data,
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
        creator: { select: { id: true, nom: true, prenom: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'modification',
        collection: 'evaluations',
        documentId: evaluation.id,
        description: `Mise à jour évaluation pour ${evaluation.employee.prenom} ${evaluation.employee.nom}`,
      },
    });

    res.json({ evaluation });
  } catch (error) {
    next(error);
  }
};

export const deleteEvaluation = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const evaluation = await prisma.evaluation.findUnique({ where: { id } });
    if (!evaluation) {
      throw new NotFoundError('Évaluation');
    }

    await prisma.evaluation.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'evaluations',
        documentId: id,
        description: `Suppression évaluation`,
      },
    });

    res.json({ message: 'Évaluation supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};