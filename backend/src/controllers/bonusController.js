import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createBonusSchema,
  updateBonusSchema,
  bonusQuerySchema,
} from '../utils/validation.js';

function getMonthRange(mois, annee) {
  const start = new Date(Date.UTC(annee, mois - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(annee, mois, 0, 23, 59, 59, 999));
  return { start, end };
}

async function syncPayrollPrimes(employeeId, dateAttribution) {
  const date = dateAttribution instanceof Date ? dateAttribution : new Date(dateAttribution);
  if (Number.isNaN(date.getTime())) return;
  const mois = date.getUTCMonth() + 1;
  const annee = date.getUTCFullYear();
  const payroll = await prisma.payroll.findUnique({
    where: { employeeId_mois_annee: { employeeId, mois, annee } },
  });
  if (!payroll) return;
  const { start, end } = getMonthRange(mois, annee);
  const result = await prisma.bonus.aggregate({
    where: {
      employeeId,
      statut: 'active',
      dateAttribution: { gte: start, lte: end },
    },
    _sum: { montant: true },
  });
  const primes = result._sum.montant ?? 0;
  const salaireBase = Number(payroll.salaireBase ?? 0);
  const bonus = Number(payroll.bonus ?? 0);
  const heuresSupp = Number(payroll.heuresSupp ?? 0);
  const tauxHeureSupp = Number(payroll.tauxHeureSupp ?? 0);
  const retenues = Number(payroll.retenues ?? 0);
  const cotisationsSociales = Number(payroll.cotisationsSociales ?? 0);
  const impots = Number(payroll.impots ?? 0);
  const brut = salaireBase + primes + bonus + (heuresSupp * tauxHeureSupp);
  const netAPayer = brut - retenues - cotisationsSociales - impots;
  await prisma.payroll.update({
    where: { id: payroll.id },
    data: { primes, netAPayer },
  });
}

export const getBonuses = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, statut } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (statut) where.statut = statut;

    const [bonuses, total] = await Promise.all([
      prisma.bonus.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : { dateAttribution: 'desc' },
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.bonus.count({ where }),
    ]);

    res.json({
      data: bonuses,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getBonusById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const bonus = await prisma.bonus.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!bonus) {
      throw new NotFoundError('Prime');
    }

    res.json({ bonus });
  } catch (error) {
    next(error);
  }
};

export const createBonus = async (req, res, next) => {
  try {
    const data = createBonusSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    const bonus = await prisma.bonus.create({
      data: {
        ...data,
        dateAttribution: new Date(data.dateAttribution),
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
        collection: 'bonuses',
        documentId: bonus.id,
        description: `Attribution de prime à ${employee.prenom} ${employee.nom} - ${data.montant}`,
      },
    });

    await syncPayrollPrimes(bonus.employeeId, bonus.dateAttribution);

    res.status(201).json({ bonus });
  } catch (error) {
    next(error);
  }
};

export const updateBonus = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updateBonusSchema.parse(req.body);

    const existing = await prisma.bonus.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Prime');
    }

    const updateData = { ...data };
    if (data.dateAttribution) updateData.dateAttribution = new Date(data.dateAttribution);

    const bonus = await prisma.bonus.update({
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
        collection: 'bonuses',
        documentId: bonus.id,
        description: `Mise à jour prime pour ${bonus.employee.prenom} ${bonus.employee.nom}`,
      },
    });

    await syncPayrollPrimes(bonus.employeeId, bonus.dateAttribution);
    if (existing.employeeId !== bonus.employeeId || existing.dateAttribution?.getTime?.() !== bonus.dateAttribution?.getTime?.()) {
      await syncPayrollPrimes(existing.employeeId, existing.dateAttribution);
    }

    res.json({ bonus });
  } catch (error) {
    next(error);
  }
};

export const deleteBonus = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const bonus = await prisma.bonus.findUnique({ where: { id } });
    if (!bonus) {
      throw new NotFoundError('Prime');
    }

    await prisma.bonus.delete({ where: { id } });
    await syncPayrollPrimes(bonus.employeeId, bonus.dateAttribution);

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'bonuses',
        documentId: id,
        description: `Suppression prime`,
      },
    });

    res.json({ message: 'Prime supprimée avec succès' });
  } catch (error) {
    next(error);
  }
};