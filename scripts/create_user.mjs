#!/usr/bin/env node

/**
 * Script de création d'utilisateur pour SGE Secdiarra (Firebase Auth + Firestore)
 * Utilisation :
 *   node scripts/create_user.mjs <email> <mot_de_passe> <nom> <prenom> [role]
 *
 * Exemple :
 *   node scripts/create_user.mjs admin@secdiarra.com MonMotDePasse123! Diarra Sekou admin
 */

const API_KEY = 'AIzaSyAdup-JatLVH_kcpNLrk5OhnpriV6Svc40';
const PROJECT_ID = 'sge-sec-diarra';

const args = process.argv.slice(2);
if (args.length < 4) {
  console.log('\n❌ Usage: node scripts/create_user.mjs <email> <mot_de_passe> <nom> <prenom> [role]');
  console.log('   Roles disponibles: admin, rh, director, chef_service, employee (défaut: admin)');
  console.log('   Exemple: node scripts/create_user.mjs admin@secdiarra.com AdminPass123! Sec Diarra admin\n');
  process.exit(1);
}

const [email, password, nom, prenom, roleArg] = args;
const role = roleArg || 'admin';

async function main() {
  console.log(`\n⏳ Création du compte pour "${email}" (Rôle: ${role})...`);

  // 1. Création dans Firebase Authentication
  const signUpUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
  const authRes = await fetch(signUpUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });

  const authData = await authRes.json();
  if (!authRes.ok) {
    if (authData.error?.message === 'EMAIL_EXISTS') {
      console.error(`\n⚠️ L'adresse "${email}" existe déjà dans Firebase Authentication.`);
      console.log('Pour changer son mot de passe, allez dans la Console Firebase > Authentication > Users > Réinitialiser le mot de passe.\n');
    } else {
      console.error('\n❌ Erreur Firebase Auth:', authData.error?.message || authData);
    }
    process.exit(1);
  }

  const { idToken, localId: uid } = authData;
  console.log(`✅ Compte Auth créé ! UID: ${uid}`);

  // 2. Création du profil utilisateur dans Firestore
  console.log('⏳ Création du document utilisateur dans Firestore...');
  const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
  
  const firestoreDoc = {
    fields: {
      email: { stringValue: email },
      nom: { stringValue: nom },
      prenom: { stringValue: prenom },
      role: { stringValue: role },
      employeeId: { stringValue: uid },
      photoUrl: { nullValue: null },
      isActive: { booleanValue: true },
      twoFactorEnabled: { booleanValue: false },
      darkMode: { booleanValue: false },
      emailNotifications: { booleanValue: true },
      mustChangePassword: { booleanValue: false },
      createdAt: { timestampValue: new Date().toISOString() },
      permissions: { arrayValue: { values: [] } },
    },
  };

  const fsRes = await fetch(firestoreUrl, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify(firestoreDoc),
  });

  const fsData = await fsRes.json();
  if (!fsRes.ok) {
    console.error('\n⚠️ Compte Auth créé, mais erreur écriture Firestore:', fsData.error?.message || fsData);
  } else {
    console.log(`✅ Profil Firestore créé avec succès !`);
  }

  console.log('\n========================================');
  console.log('🎉 Utilisateur prêt ! Vous pouvez vous connecter :');
  console.log(`   Email    : ${email}`);
  console.log(`   Password : ${password}`);
  console.log(`   Rôle     : ${role}`);
  console.log('========================================\n');
}

main().catch((err) => {
  console.error('\n❌ Erreur inattendue:', err);
  process.exit(1);
});

