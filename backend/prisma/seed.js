import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Create admin user
  const adminPassword = await bcrypt.hash('admin123', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@secdiarra.com' },
    update: {},
    create: {
      email: 'admin@secdiarra.com',
      passwordHash: adminPassword,
      nom: 'Admin',
      prenom: 'SGE',
      role: 'admin',
      isActive: true,
      permissions: ['*'],
    },
  });
  console.log('✅ Admin user created:', admin.email);

  // Create HR user
  const hrPassword = await bcrypt.hash('hr123', 12);
  const hr = await prisma.user.upsert({
    where: { email: 'hr@secdiarra.com' },
    update: {},
    create: {
      email: 'hr@secdiarra.com',
      passwordHash: hrPassword,
      nom: 'Ressources',
      prenom: 'Humaines',
      role: 'hr',
      isActive: true,
      permissions: ['employees:read', 'employees:write', 'leaves:read', 'leaves:write', 'contracts:read', 'payroll:read'],
    },
  });
  console.log('✅ HR user created:', hr.email);

  // Create manager user
  const managerPassword = await bcrypt.hash('manager123', 12);
  const manager = await prisma.user.upsert({
    where: { email: 'manager@secdiarra.com' },
    update: {},
    create: {
      email: 'manager@secdiarra.com',
      passwordHash: managerPassword,
      nom: 'Manager',
      prenom: 'General',
      role: 'manager',
      isActive: true,
      permissions: ['employees:read', 'employees:write', 'attendances:read', 'attendances:write', 'leaves:read', 'leaves:write'],
    },
  });
  console.log('✅ Manager user created:', manager.email);

  // Create employee user
  const employeePassword = await bcrypt.hash('employee123', 12);
  const employeeUser = await prisma.user.upsert({
    where: { email: 'employee@secdiarra.com' },
    update: {},
    create: {
      email: 'employee@secdiarra.com',
      passwordHash: employeePassword,
      nom: 'Employe',
      prenom: 'Test',
      role: 'employee',
      isActive: true,
    },
  });
  console.log('✅ Employee user created:', employeeUser.email);

  // Create departments
  const deptData = [
    { nom: 'Direction Générale', description: 'Direction générale de l\'entreprise' },
    { nom: 'Ressources Humaines', description: 'Gestion des ressources humaines' },
    { nom: 'Comptabilité', description: 'Service comptabilité et finance' },
    { nom: 'Informatique', description: 'Service informatique et systèmes' },
    { nom: 'Commercial', description: 'Service commercial et ventes' },
  ];

  const departments = [];
  for (const d of deptData) {
    let dept = await prisma.department.findFirst({ where: { nom: d.nom } });
    if (!dept) {
      dept = await prisma.department.create({ data: d });
    }
    departments.push(dept);
  }

  const [dept1, dept2, dept3, dept4, dept5] = departments;
  console.log('✅ Departments created');

  // Assign a responsable (User) to each department so the "Responsable" column
  // is populated in the department list.
  const responsableByDept = {
    [dept1.id]: admin.id,    // Direction Générale → Admin
    [dept2.id]: hr.id,       // Ressources Humaines → HR
    [dept3.id]: hr.id,       // Comptabilité → HR
    [dept4.id]: manager.id,  // Informatique → Manager
    [dept5.id]: manager.id,  // Commercial → Manager
  };
  for (const dept of departments) {
    const responsableId = responsableByDept[dept.id];
    if (responsableId) {
      await prisma.department.update({
        where: { id: dept.id },
        data: { responsableId },
      });
    }
  }
  console.log('✅ Department responsables assigned');

  // Create positions
  const positions = [
    { titre: 'Directeur Général', departementId: dept1.id, salaireMini: 500000, salaireMaxi: 1000000 },
    { titre: 'Directeur RH', departementId: dept2.id, salaireMini: 300000, salaireMaxi: 600000 },
    { titre: 'Gestionnaire Paie', departementId: dept2.id, salaireMini: 200000, salaireMaxi: 400000 },
    { titre: 'Comptable', departementId: dept3.id, salaireMini: 180000, salaireMaxi: 350000 },
    { titre: 'Développeur', departementId: dept4.id, salaireMini: 250000, salaireMaxi: 500000 },
    { titre: 'Administrateur Système', departementId: dept4.id, salaireMini: 200000, salaireMaxi: 400000 },
    { titre: 'Commercial', departementId: dept5.id, salaireMini: 150000, salaireMaxi: 300000 },
  ];

  for (const pos of positions) {
    await prisma.position.upsert({
      where: { titre: pos.titre },
      update: {},
      create: pos,
    });
  }
  console.log('✅ Positions created');

  // Create employees
  const employees = [
    {
      matricule: 'EMP0001',
      nom: 'Diop',
      prenom: 'Mamadou',
      sexe: 'M',
      dateNaissance: new Date('1985-03-15'),
      adresse: 'Dakar, Plateau',
      telephone: '+221 77 123 45 67',
      email: 'mamadou.diop@secdiarra.com',
      situationMatrimoniale: 'Marié',
      nationalite: 'Sénégalaise',
      contactUrgenceNom: 'Fatou Diop',
      contactUrgenceTel: '+221 77 987 65 43',
      contactUrgenceRelation: 'Épouse',
      poste: 'Directeur Général',
      service: 'Direction',
      departementId: dept1.id,
      departementNom: dept1.nom,
      grade: 'Cadre Supérieur',
      dateEmbauche: new Date('2010-01-15'),
      typeContrat: 'CDI',
      salaire: 800000,
      statut: 'actif',
      soldeCongesAnnuels: 30,
      soldeCongesMaladie: 15,
      createdBy: admin.id,
    },
    {
      matricule: 'EMP0002',
      nom: 'Sow',
      prenom: 'Aminata',
      sexe: 'F',
      dateNaissance: new Date('1990-07-22'),
      adresse: 'Dakar, Almadies',
      telephone: '+221 77 234 56 78',
      email: 'aminata.sow@secdiarra.com',
      situationMatrimoniale: 'Célibataire',
      nationalite: 'Sénégalaise',
      contactUrgenceNom: 'Ousmane Sow',
      contactUrgenceTel: '+221 77 345 67 89',
      contactUrgenceRelation: 'Frère',
      poste: 'Directeur RH',
      service: 'RH',
      departementId: dept2.id,
      departementNom: dept2.nom,
      grade: 'Cadre',
      dateEmbauche: new Date('2015-03-01'),
      typeContrat: 'CDI',
      salaire: 450000,
      statut: 'actif',
      soldeCongesAnnuels: 28,
      soldeCongesMaladie: 12,
      createdBy: admin.id,
    },
    {
      matricule: 'EMP0003',
      nom: 'Ba',
      prenom: 'Ibrahima',
      sexe: 'M',
      dateNaissance: new Date('1992-11-05'),
      adresse: 'Dakar, Grand Yoff',
      telephone: '+221 77 345 67 89',
      email: 'ibrahima.ba@secdiarra.com',
      situationMatrimoniale: 'Célibataire',
      nationalite: 'Sénégalaise',
      contactUrgenceNom: 'Awa Ba',
      contactUrgenceTel: '+221 77 456 78 90',
      contactUrgenceRelation: 'Sœur',
      poste: 'Gestionnaire Paie',
      service: 'RH',
      departementId: dept2.id,
      departementNom: dept2.nom,
      grade: 'Technicien',
      dateEmbauche: new Date('2018-06-15'),
      typeContrat: 'CDI',
      salaire: 280000,
      statut: 'actif',
      soldeCongesAnnuels: 25,
      soldeCongesMaladie: 10,
      createdBy: admin.id,
    },
    {
      matricule: 'EMP0004',
      nom: 'Ndiaye',
      prenom: 'Fatou',
      sexe: 'F',
      dateNaissance: new Date('1988-02-28'),
      adresse: 'Dakar, Parcelles Assainies',
      telephone: '+221 77 456 78 90',
      email: 'fatou.ndiaye@secdiarra.com',
      situationMatrimoniale: 'Mariée',
      nationalite: 'Sénégalaise',
      contactUrgenceNom: 'Mamadou Ndiaye',
      contactUrgenceTel: '+221 77 567 89 01',
      contactUrgenceRelation: 'Époux',
      poste: 'Comptable',
      service: 'Comptabilité',
      departementId: dept3.id,
      departementNom: dept3.nom,
      grade: 'Technicien',
      dateEmbauche: new Date('2016-09-01'),
      typeContrat: 'CDI',
      salaire: 300000,
      statut: 'actif',
      soldeCongesAnnuels: 27,
      soldeCongesMaladie: 13,
      createdBy: admin.id,
    },
    {
      matricule: 'EMP0005',
      nom: 'Fall',
      prenom: 'Cheikh',
      sexe: 'M',
      dateNaissance: new Date('1995-04-12'),
      adresse: 'Dakar, HLM',
      telephone: '+221 77 567 89 01',
      email: 'cheikh.fall@secdiarra.com',
      situationMatrimoniale: 'Célibataire',
      nationalite: 'Sénégalaise',
      contactUrgenceNom: 'Khady Fall',
      contactUrgenceTel: '+221 77 678 90 12',
      contactUrgenceRelation: 'Mère',
      poste: 'Développeur',
      service: 'IT',
      departementId: dept4.id,
      departementNom: dept4.nom,
      grade: 'Technicien',
      dateEmbauche: new Date('2020-01-10'),
      typeContrat: 'CDI',
      salaire: 350000,
      statut: 'actif',
      soldeCongesAnnuels: 22,
      soldeCongesMaladie: 8,
      createdBy: admin.id,
    },
  ];

  for (const emp of employees) {
    await prisma.employee.upsert({
      where: { matricule: emp.matricule },
      update: {},
      create: emp,
    });
  }
  console.log('✅ Employees created');

  // Update department employee counts
  for (const dept of [dept1, dept2, dept3, dept4, dept5]) {
    const count = await prisma.employee.count({ where: { departementId: dept.id } });
    await prisma.department.update({
      where: { id: dept.id },
      data: { nombreEmployes: count },
    });
  }

  // Link users to employees
  await prisma.user.update({
    where: { id: employeeUser.id },
    data: { employeeId: (await prisma.employee.findUnique({ where: { matricule: 'EMP0005' } })).id },
  });

  // Create sample contracts
  const emp1 = await prisma.employee.findUnique({ where: { matricule: 'EMP0001' } });
  const emp2 = await prisma.employee.findUnique({ where: { matricule: 'EMP0002' } });
  const emp3 = await prisma.employee.findUnique({ where: { matricule: 'EMP0003' } });
  const emp4 = await prisma.employee.findUnique({ where: { matricule: 'EMP0004' } });
  const emp5 = await prisma.employee.findUnique({ where: { matricule: 'EMP0005' } });

  const contracts = [
    { employeeId: emp1.id, employeeNom: `${emp1.prenom} ${emp1.nom}`, type: 'CDI', dateDebut: new Date('2010-01-15'), statut: 'actif', createdBy: admin.id },
    { employeeId: emp2.id, employeeNom: `${emp2.prenom} ${emp2.nom}`, type: 'CDI', dateDebut: new Date('2015-03-01'), statut: 'actif', createdBy: admin.id },
    { employeeId: emp3.id, employeeNom: `${emp3.prenom} ${emp3.nom}`, type: 'CDI', dateDebut: new Date('2018-06-15'), statut: 'actif', createdBy: admin.id },
    { employeeId: emp4.id, employeeNom: `${emp4.prenom} ${emp4.nom}`, type: 'CDI', dateDebut: new Date('2016-09-01'), statut: 'actif', createdBy: admin.id },
    { employeeId: emp5.id, employeeNom: `${emp5.prenom} ${emp5.nom}`, type: 'CDI', dateDebut: new Date('2020-01-10'), statut: 'actif', createdBy: admin.id },
  ];

  for (const contract of contracts) {
    await prisma.contract.upsert({
      where: { id: 'seed-' + contract.employeeId },
      update: {},
      create: { ...contract, id: 'seed-' + contract.employeeId },
    });
  }
  console.log('✅ Contracts created');

  // Create sample attendances for today
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (const emp of [emp1, emp2, emp3, emp4, emp5]) {
    await prisma.attendance.upsert({
      where: { id: `seed-att-${emp.id}` },
      update: {},
      create: {
        id: `seed-att-${emp.id}`,
        employeeId: emp.id,
        employeeNom: `${emp.prenom} ${emp.nom}`,
        date: today,
        heureArrivee: new Date(today.getTime() + 8 * 60 * 60 * 1000), // 8:00
        statut: 'present',
        createdBy: admin.id,
      },
    });
  }
  console.log('✅ Sample attendances created');

  // Create sample leave
  const leave = await prisma.leave.upsert({
    where: { id: 'seed-leave-1' },
    update: {},
    create: {
      id: 'seed-leave-1',
      employee: { connect: { id: emp3.id } },
      creator: { connect: { id: admin.id } },
      employeeNom: `${emp3.prenom} ${emp3.nom}`,
      type: 'annuel',
      dateDebut: new Date('2024-02-01'),
      dateFin: new Date('2024-02-05'),
      nombreJours: 5,
      motif: 'Congés annuels',
      statut: 'en_attente',
    },
  });
  console.log('✅ Sample leave created');

  // Create sample payroll
  const currentMonth = today.getMonth() + 1;
  const currentYear = today.getFullYear();

  for (const emp of [emp1, emp2, emp3, emp4, emp5]) {
    const salaireBase = emp.salaire;
    const cotisationsSociales = salaireBase * 0.22;
    const impots = (salaireBase - cotisationsSociales) * 0.15;
    const netAPayer = salaireBase - cotisationsSociales - impots;

    await prisma.payroll.upsert({
      where: { employeeId_mois_annee: { employeeId: emp.id, mois: currentMonth, annee: currentYear } },
      update: {},
      create: {
        employeeId: emp.id,
        employeeNom: `${emp.prenom} ${emp.nom}`,
        mois: currentMonth,
        annee: currentYear,
        salaireBase,
        primes: 0,
        bonus: 0,
        heuresSupp: 0,
        tauxHeureSupp: 0,
        retenues: 0,
        cotisationsSociales,
        impots,
        netAPayer,
        statut: 'brouillon',
        createdBy: admin.id,
      },
    });
  }
  console.log('✅ Sample payrolls created');

  // Create sample agenda events
  const agendaEvents = [
    {
      titre: 'Réunion direction',
      description: 'Réunion hebdomadaire de la direction',
      type: 'reunion',
      dateDebut: new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000),
      dateFin: new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000),
      participants: [emp1.id, emp2.id],
      createdBy: admin.id,
    },
    {
      titre: 'Formation sécurité',
      description: 'Formation sécurité incendie',
      type: 'evenement',
      dateDebut: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000),
      dateFin: new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000 + 4 * 60 * 60 * 1000),
      participants: [emp1.id, emp2.id, emp3.id, emp4.id, emp5.id],
      createdBy: admin.id,
    },
  ];

  for (const event of agendaEvents) {
    await prisma.agenda.create({ data: event });
  }
  console.log('✅ Sample agenda events created');

  // Create sample schedules
  const schedules = [
    { nom: 'Planning standard', debut: '08:00', fin: '17:00', jours: 'Lundi-Vendredi', type: 'normal', createdBy: admin.id },
    { nom: 'Planning nuit', debut: '22:00', fin: '06:00', jours: 'Lundi-Vendredi', type: 'nuit', createdBy: admin.id },
    { nom: 'Planning week-end', debut: '09:00', fin: '13:00', jours: 'Samedi-Dimanche', type: 'week_end', createdBy: admin.id },
  ];

  for (const sched of schedules) {
    await prisma.schedule.create({ data: sched });
  }
  console.log('✅ Sample schedules created');

  console.log('🎉 Database seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });