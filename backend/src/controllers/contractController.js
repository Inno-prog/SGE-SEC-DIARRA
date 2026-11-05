import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createContractSchema,
  updateContractSchema,
  contractQuerySchema,
} from '../utils/validation.js';

export const getContracts = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, statut, type } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (statut) where.statut = statut;
    if (type) where.type = type;

    const [contracts, total] = await Promise.all([
      prisma.contract.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { dateDebut: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.contract.count({ where }),
    ]);

    res.json({
      data: contracts,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getContractById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const contract = await prisma.contract.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!contract) {
      throw new NotFoundError('Contrat');
    }

    res.json({ contract });
  } catch (error) {
    next(error);
  }
};

export const createContract = async (req, res, next) => {
  try {
    const data = createContractSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const contract = await prisma.contract.create({
      data: {
        ...data,
        dateDebut: new Date(data.dateDebut),
        dateFin: data.dateFin ? new Date(data.dateFin) : null,
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
        collection: 'contracts',
        documentId: contract.id,
        description: `Création du contrat pour ${employee.prenom} ${employee.nom}`,
      },
    });

    res.status(201).json({ contract });
  } catch (error) {
    next(error);
  }
};

export const updateContract = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateContractSchema.parse(req.body);

    const existing = await prisma.contract.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Contrat');
    }

    const updateData = { ...data };
    if (data.dateDebut) updateData.dateDebut = new Date(data.dateDebut);
    if (data.dateFin) updateData.dateFin = new Date(data.dateFin);

    const contract = await prisma.contract.update({
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
        collection: 'contracts',
        documentId: contract.id,
        description: `Mise à jour du contrat pour ${contract.employee.prenom} ${contract.employee.nom}`,
      },
    });

    res.json({ contract });
  } catch (error) {
    next(error);
  }
};

export const deleteContract = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const contract = await prisma.contract.findUnique({ where: { id } });
    if (!contract) {
      throw new NotFoundError('Contrat');
    }

    await prisma.contract.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'contracts',
        documentId: id,
        description: `Suppression du contrat`,
      },
    });

    res.json({ message: 'Contrat supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const getExpiringContracts = async (req, res, next) => {
  try {
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    const contracts = await prisma.contract.findMany({
      where: {
        dateFin: { lte: thirtyDaysFromNow, gte: new Date() },
        statut: 'actif',
      },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
      },
      orderBy: { dateFin: 'asc' },
    });

    res.json({ contracts });
  } catch (error) {
    next(error);
  }
};