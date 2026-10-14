'use strict';
// Fictitious accounts exclusively in the local demo emulators. No ADC used.
if (process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') {
  throw new Error('La preparación de QA exige los dos emuladores locales.');
}
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const app = initializeApp({ projectId: 'demo-futschool-admin' });

async function seed() {
  const auth = getAuth(app);
  for (const [uid, email, displayName, admin] of [
    ['qa-admin', 'admin.demo@example.test', 'Admin de prueba', true],
    ['qa-captain', 'captain.demo@example.test', 'Capitán de prueba', false],
    ['qa-other', 'other.demo@example.test', 'Otro capitán', false],
  ]) {
    const properties = { email, displayName, emailVerified: true, password: 'Demo-only-local-2026!' };
    try { await auth.createUser({uid, ...properties}); }
    catch (error) {
      if (error.code !== 'auth/uid-already-exists') throw error;
      await auth.updateUser(uid, properties);
    }
    await auth.setCustomUserClaims(uid, admin ? {admin: true} : {});
  }
  const db = getFirestore(app);
  const start = new Date(); start.setUTCHours(0,0,0,0);
  const end = new Date(start); end.setUTCDate(end.getUTCDate()+30);
  await db.doc('adminTournaments/qa-cup').set({
    name: 'Copa de prueba local', description: 'Datos ficticios del emulador.',
    startDate: Timestamp.fromDate(start), endDate: Timestamp.fromDate(end),
    maxTeams: 16, teamCount: 0, lastTeamId: null,
    createdBy: 'qa-admin', createdAt: Timestamp.now(),
  });
  console.log('Emuladores preparados con tres cuentas ficticias y un torneo.');
}
seed().finally(() => deleteApp(app)).catch(() => { console.error('No se pudo preparar QA local.'); process.exitCode=1; });
