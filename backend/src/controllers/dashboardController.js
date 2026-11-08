import prisma from '../config/prisma.js';
import { authMiddleware, requireRole } from '../middleware/auth.js';

export const getDashboardStats = async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const [
      totalEmployes,
      employesActifs,
      presentsAujourdhui,
      enConge,
      contratsActifs,
      congesEnAttente,
      totalDepartments,
      totalPositions,
      recentEmployees,
      recentContracts,
      recentLeaves,
      payrollThisMonth,
    ] = await Promise.all([
      prisma.employee.count(),
      prisma.employee.count({ where: { statut: 'actif' } }),
      prisma.attendance.count({
        where: {
          date: { gte: today, lt: tomorrow },
          statut: 'present',
        },
      }),
      prisma.employee.count({ where: { statut: 'conge' } }),
      prisma.contract.count({ where: { statut: 'actif' } }),
      prisma.leave.count({ where: { statut: 'en_attente' } }),
      prisma.department.count(),
      prisma.position.count(),
      prisma.employee.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        select: { id: true, matricule: true, nom: true, prenom: true, poste: true, createdAt: true },
      }),
      prisma.contract.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: { employee: { select: { nom: true, prenom: true } } },
      }),
      prisma.leave.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: { employee: { select: { nom: true, prenom: true } } },
      }),
      prisma.payroll.aggregate({
        where: {
          mois: today.getMonth() + 1,
          annee: today.getFullYear(),
        },
        _sum: { netAPayer: true },
        _count: true,
      }),
    ]);

    // Contracts expiring soon
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    const contratsExpirantBientot = await prisma.contract.count({
      where: {
        dateFin: { lte: thirtyDaysFromNow, gte: today },
        statut: 'actif',
      },
    });

    // Birthdays this month
    const currentMonth = today.getMonth() + 1;
    const allEmployees = await prisma.employee.findMany({
      select: { id: true, matricule: true, nom: true, prenom: true, dateNaissance: true, poste: true, departementNom: true },
    });
    const birthdaysThisMonth = allEmployees.filter(e => e.dateNaissance.getMonth() + 1 === currentMonth);

    // Attendance stats for last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const attendanceStats = await prisma.attendance.groupBy({
      by: ['date', 'statut'],
      where: { date: { gte: sevenDaysAgo } },
      _count: true,
    });

    res.json({
      stats: {
        totalEmployes,
        employesActifs,
        presentsAujourdhui,
        enConge,
        contratsActifs,
        congesEnAttente,
        contratsExpirantBientot,
        totalDepartments,
        totalPositions,
        payrollThisMonth: payrollThisMonth._sum.netAPayer || 0,
        payrollCount: payrollThisMonth._count || 0,
      },
      recentEmployees,
      recentContracts,
      recentLeaves,
      birthdaysThisMonth,
      attendanceStats,
    });
  } catch (error) {
    next(error);
  }
};

export const getDashboardCharts = async (req, res, next) => {
  try {
    // Employees by department
    const employeesByDept = await prisma.employee.groupBy({
      by: ['departementId'],
      _count: true,
    });

    const deptIds = employeesByDept.map(d => d.departementId);
    const departments = await prisma.department.findMany({
      where: { id: { in: deptIds } },
      select: { id: true, nom: true },
    });
    const deptMap = Object.fromEntries(departments.map(d => [d.id, d.nom]));

    const employeesByDepartment = employeesByDept.map(d => ({
      departement: deptMap[d.departementId] || 'Inconnu',
      count: d._count,
    }));

    // Employees by status
    const employeesByStatus = await prisma.employee.groupBy({
      by: ['statut'],
      _count: true,
    });

    // Contracts by type
    const contractsByType = await prisma.contract.groupBy({
      by: ['type'],
      _count: true,
    });

    // Leaves by type
    const leavesByType = await prisma.leave.groupBy({
      by: ['type'],
      _count: true,
    });

    // Payroll evolution (last 12 months)
    const payrollEvolution = await prisma.payroll.groupBy({
      by: ['mois', 'annee'],
      _sum: { netAPayer: true },
      _count: true,
      orderBy: [{ annee: 'asc' }, { mois: 'asc' }],
      take: 12,
    });

    res.json({
      employeesByDepartment,
      employeesByStatus,
      contractsByType,
      leavesByType,
      payrollEvolution,
    });
  } catch (error) {
    next(error);
  }
};