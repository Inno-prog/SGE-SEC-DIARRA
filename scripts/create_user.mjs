#!/usr/bin/env node

/**
 * Script de création d'utilisateur pour SGE Secdiarra (Prisma + PostgreSQL)
 * Utilisation :
 *   node scripts/create_user.mjs <email> <mot_de_passe> <nom> <prenom> [role]
 *
 * Exemple :
 *   node scripts/create_user.mjs admin@secdiarra.com MonMotDePasse123! Diarra Sekou admin
 */

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const args = process.argv.slice(2);
if (args.length < 4) {
  console.log('\n❌ Usage: node scripts/create_user.mjs <email> <mot_de_passe> <nom> <prenom> [role]');
  console.log('   Roles disponibles: admin, hr, manager, employee (défaut: admin)');
  console.log('   Exemple: node scripts/create_user.mjs admin@secdiarra.com AdminPass123! Sec Diarra admin\n');
  process.exit(1);
}

const [email, password, nom, prenom, roleArg] = args;
const role = roleArg || 'admin';

async function main() {
  console.log(`\n⏳ Création du compte pour "${email}" (Rôle: ${role})...`);

  // Vérifier si l'utilisateur existe déjà
  const existingUser = await prisma.user.findUnique({
    where: { email },
  });

  if (existingUser) {
    console.error(`\n⚠️ L'adresse "${email}" existe déjà.`);
    process.exit(1);
  }

  // Hasher le mot de passe
  const passwordHash = await bcrypt.hash(password, 12);

  // Créer l'utilisateur
  const user = await prisma.user.create({
    data: {
      email,
      passwordHash,
      nom,
      prenom,
      role,
      isActive: true,
      permissions: role === 'admin' ? ['*'] : [],
    },
  });

  console.log(`✅ Utilisateur créé avec succès !`);
  console.log(`   ID       : ${user.id}`);
  console.log(`   Email    : ${user.email}`);
  console.log(`   Rôle     : ${user.role}`);

  console.log('\n========================================');
  console.log('🎉 Utilisateur prêt ! Vous pouvez vous connecter :');
  console.log(`   Email    : ${email}`);
  console.log(`   Password : ${password}`);
  console.log(`   Rôle     : ${role}`);
  console.log('========================================\n');
}

main()
  .catch((err) => {
    console.error('\n❌ Erreur inattendue:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });