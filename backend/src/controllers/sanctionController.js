import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createSanctionSchema,
  updateSanctionSchema,
  paginationSchema,
} from '../utils/validation.js';

export const getSanctions = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, statut } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (statut) where.statut = statut;

    const [sanctions, total] = await Promise.all([
      prisma.sanction.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { date: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.sanction.count({ where }),
    ]);

    res.json({
      data: sanctions,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getSanctionById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const sanction = await prisma.sanction.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!sanction) {
      throw new NotFoundError('Sanction');
    }

    res.json({ sanction });
  } catch (error) {
    next(error);
  }
};

export const createSanction = async (req, res, next) => {
  try {
    const data = createSanctionSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const sanction = await prisma.sanction.create({
      data: {
        ...data,
        date: new Date(data.date),
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
        collection: 'sanctions',
        documentId: sanction.id,
        description: `Sanction pour ${employee.prenom} ${employee.nom} - ${data.type}`,
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
          titre: 'Nouvelle sanction',
          message: `Une sanction de type "${data.type}" vous a été attribuée`,
          type: 'warning',
          actionRoute: `/sanctions/${sanction.id}`,
        },
      });
    }

    res.status(201).json({ sanction });
  } catch (error) {
    next(error);
  }
};

export const updateSanction = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateSanctionSchema.parse(req.body);

    const existing = await prisma.sanction.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Sanction');
    }

    const updateData = { ...data };
    if (data.date) updateData.date = new Date(data.date);

    const sanction = await prisma.sanction.update({
      where: { id },
      data: updateData,
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
        collection: 'sanctions',
        documentId: sanction.id,
        description: `Mise à jour sanction pour ${sanction.employee.prenom} ${sanction.employee.nom}`,
      },
    });

    res.json({ sanction });
  } catch (error) {
    next(error);
  }
};

export const deleteSanction = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const sanction = await prisma.sanction.findUnique({ where: { id } });
    if (!sanction) {
      throw new NotFoundError('Sanction');
    }

    await prisma.sanction.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'sanctions',
        documentId: id,
        description: `Suppression sanction`,
      },
    });

    res.json({ message: 'Sanction supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};