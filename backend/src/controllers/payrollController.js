import prisma from '../config/prisma.js';
import { AppError, NotFoundError } from '../middleware/errorHandler.js';
import { validate, validateQuery, validateParams, idParamSchema } from '../utils/validation.js';
import {
  createPayrollSchema,
  updatePayrollSchema,
  payrollQuerySchema,
} from '../utils/validation.js';

export const getPayrolls = async (req, res, next) => {
  try {
    const { page, limit, sortBy, sortOrder, employeeId, mois, annee, statut } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (employeeId) where.employeeId = employeeId;
    if (mois) where.mois = parseInt(mois);
    if (annee) where.annee = parseInt(annee);
    if (statut) where.statut = statut;

    const [payrolls, total] = await Promise.all([
      prisma.payroll.findMany({
        where,
        skip,
        take: limit,
        orderBy: sortBy ? { [sortBy]: sortOrder } : [{ annee: 'desc' }, { mois: 'desc' }],
        include: {
          employee: { select: { id: true, matricule: true, nom: true, prenom: true } },
          creator: { select: { id: true, nom: true, prenom: true } },
        },
      }),
      prisma.payroll.count({ where }),
    ]);

    res.json({
      data: payrolls,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    next(error);
  }
};

export const getPayrollById = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const payroll = await prisma.payroll.findUnique({
      where: { id },
      include: {
        employee: { select: { id: true, matricule: true, nom: true, prenom: true, email: true, salaire: true } },
        creator: { select: { id: true, nom: true, prenom: true, email: true } },
      },
    });

    if (!payroll) {
      throw new NotFoundError('Bulletin de paie');
    }

    res.json({ payroll });
  } catch (error) {
    next(error);
  }
};

export const createPayroll = async (req, res, next) => {
  try {
    const data = createPayrollSchema.parse(req.body);

    const employee = await prisma.employee.findUnique({ where: { id: data.employeeId } });
    if (!employee) {
      throw new NotFoundError('Employé');
    }

    // Check if payroll already exists for this employee/month/year
    const existing = await prisma.payroll.findUnique({
      where: {
        employeeId_mois_annee: {
          employeeId: data.employeeId,
          mois: data.mois,
          annee: data.annee,
        },
      },
    });
    if (existing) {
      throw new AppError('Un bulletin existe déjà pour cet employé ce mois-ci', 409, 'DUPLICATE_PAYROLL');
    }

    const payroll = await prisma.payroll.create({
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
        collection: 'payrolls',
        documentId: payroll.id,
        description: `Création bulletin de paie pour ${employee.prenom} ${employee.nom} - ${data.mois}/${data.annee}`,
      },
    });

    res.status(201).json({ payroll });
  } catch (error) {
    next(error);
  }
};

export const updatePayroll = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);
    const data = updatePayrollSchema.parse(req.body);

    const existing = await prisma.payroll.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Bulletin de paie');
    }

    const updateData = { ...data };
    if (data.datePaiement) updateData.datePaiement = new Date(data.datePaiement);

    const payroll = await prisma.payroll.update({
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
        collection: 'payrolls',
        documentId: payroll.id,
        description: `Mise à jour bulletin de paie pour ${payroll.employee.prenom} ${payroll.employee.nom}`,
      },
    });

    res.json({ payroll });
  } catch (error) {
    next(error);
  }
};

export const deletePayroll = async (req, res, next) => {
  try {
    const { id } = idParamSchema.parse(req.params);

    const payroll = await prisma.payroll.findUnique({ where: { id } });
    if (!payroll) {
      throw new NotFoundError('Bulletin de paie');
    }

    await prisma.payroll.delete({ where: { id } });

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'suppression',
        collection: 'payrolls',
        documentId: id,
        description: `Suppression bulletin de paie`,
      },
    });

    res.json({ message: 'Bulletin de paie supprimé avec succès' });
  } catch (error) {
    next(error);
  }
};

export const generatePayroll = async (req, res, next) => {
  try {
    const { mois, annee, employeeIds } = req.body;

    if (!mois || !annee) {
      throw new AppError('Mois et année requis', 400, 'VALIDATION_ERROR');
    }

    const where = { statut: 'actif' };
    if (employeeIds && employeeIds.length > 0) {
      where.id = { in: employeeIds };
    }

    const employees = await prisma.employee.findMany({ where });

    const results = [];
    for (const emp of employees) {
      const existing = await prisma.payroll.findUnique({
        where: {
          employeeId_mois_annee: {
            employeeId: emp.id,
            mois,
            annee,
          },
        },
      });

      if (existing) {
        results.push({ employeeId: emp.id, status: 'exists', payrollId: existing.id });
        continue;
      }

      // Calculate payroll based on employee data
      const salaireBase = emp.salaire;
      const primes = 0;
      const bonus = 0;
      const heuresSupp = 0;
      const tauxHeureSupp = 0;
      const retenues = 0;
      const cotisationsSociales = salaireBase * 0.22; // 22% social contributions
      const impots = 0; // Les employés ne paient pas d'impôts
      const netAPayer = salaireBase + primes + bonus - retenues - cotisationsSociales - impots;

      const payroll = await prisma.payroll.create({
        data: {
          employeeId: emp.id,
          employeeNom: `${emp.prenom} ${emp.nom}`,
          mois,
          annee,
          salaireBase,
          primes,
          bonus,
          heuresSupp,
          tauxHeureSupp,
          retenues,
          cotisationsSociales,
          impots,
          netAPayer,
          statut: 'brouillon',
          createdBy: req.user.id,
        },
      });

      results.push({ employeeId: emp.id, status: 'created', payrollId: payroll.id });
    }

    await prisma.auditLog.create({
      data: {
        userId: req.user.id,
        userNom: `${req.user.prenom} ${req.user.nom}`,
        action: 'ajout',
        collection: 'payrolls',
        documentId: 'batch',
        description: `Génération groupée des bulletins de paie - ${mois}/${annee}`,
      },
    });

    res.json({ results });
  } catch (error) {
    next(error);
  }
};