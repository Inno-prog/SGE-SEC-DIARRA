import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const adminPassword = await bcrypt.hash('admin123', 12);
  
  const admin = await prisma.user.upsert({
    where: { email: 'admin@secdiarra.com' },
    update: {
      passwordHash: adminPassword,
      nom: 'Admin',
      prenom: 'SGE',
      role: 'admin',
      isActive: true,
      permissions: ['*'],
      mustChangePassword: false,
    },
    create: {
      email: 'admin@secdiarra.com',
      passwordHash: adminPassword,
      nom: 'Admin',
      prenom: 'SGE',
      role: 'admin',
      isActive: true,
      permissions: ['*'],
      mustChangePassword: false,
    },
  });
  
  console.log('✅ Admin user created/updated:', admin.email);
  console.log('   Role:', admin.role);
  console.log('   Active:', admin.isActive);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
