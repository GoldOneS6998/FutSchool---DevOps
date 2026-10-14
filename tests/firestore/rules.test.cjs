'use strict';

const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, collection, query, where, limit, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp, setLogLevel } = require('firebase/firestore');
// Expected permission denials are asserted below; retain the test runner's failure details.
setLogLevel('silent');

// A demo project and an explicit loopback endpoint prevent a production run.
const emulatorEndpoint = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulatorEndpoint || !/^(127\.0\.0\.1|localhost):\d+$/.test(emulatorEndpoint)) {
  throw new Error('Estas pruebas requieren FIRESTORE_EMULATOR_HOST en loopback; usa npm test.');
}
const [host, portText] = emulatorEndpoint.split(':');
let env;
const adminUid = 'administrator';
const start = Timestamp.fromDate(new Date('2026-10-15T06:00:00Z'));
const end = Timestamp.fromDate(new Date('2026-10-20T06:00:00Z'));
const kickOff = Timestamp.fromDate(new Date('2026-10-16T14:00:00Z'));
const ref = (db, name, id) => doc(db, name, id);
const adminDb = () => env.authenticatedContext(adminUid, { admin: true, email_verified: true }).firestore();

function tournament(overrides = {}) {
  return { name: 'Copa Universidad', description: '', startDate: start, endDate: end,
    maxTeams: 16, teamCount: 0, lastTeamId: null, createdBy: adminUid,
    createdAt: serverTimestamp(), ...overrides };
}
function match(overrides = {}) {
  return { tournamentId: 'cup', homeTeamId: 'teamA', awayTeamId: 'teamB', courtId: 'cancha-1',
    startsAt: kickOff, status: 'scheduled', homeScore: null, awayScore: null,
    createdBy: adminUid, createdAt: serverTimestamp(), ...overrides };
}
function teamBatch(db, id, count, overrides = {}) {
  const batch = writeBatch(db);
  batch.set(ref(db, 'adminTeams', id), { name: `Equipo ${id}`, tournamentId: 'cup',
    createdBy: adminUid, createdAt: serverTimestamp(), ...overrides });
  batch.update(ref(db, 'adminTournaments', 'cup'), { teamCount: count, lastTeamId: id });
  return batch;
}
function matchBatch(db, id, overrides = {}, slots = 3) {
  const data = match(overrides);
  const batch = writeBatch(db);
  batch.set(ref(db, 'adminMatches', id), data);
  const epoch = data.startsAt.toMillis();
  const ids = [`court_${data.courtId}_${epoch}`, `team_${data.homeTeamId}_${epoch}`, `team_${data.awayTeamId}_${epoch}`];
  ids.slice(0, slots).forEach(slot => batch.set(ref(db, 'adminReservations', slot), {
    matchId: id, createdBy: adminUid, createdAt: serverTimestamp(),
  }));
  return batch;
}
async function seed() {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(ref(db, 'adminTournaments', 'cup'), tournament({ teamCount: 2, lastTeamId: 'teamB' }));
    await setDoc(ref(db, 'adminTournaments', 'otherCup'), tournament());
    for (const id of ['teamA', 'teamB', 'teamC', 'teamD']) {
      await setDoc(ref(db, 'adminTeams', id), {
        name: `Equipo ${id}`, tournamentId: 'cup', createdBy: adminUid, createdAt: serverTimestamp(),
      });
    }
    await setDoc(ref(db, 'adminTeams', 'teamOther'), {
      name: 'Otro torneo', tournamentId: 'otherCup', createdBy: adminUid, createdAt: serverTimestamp(),
    });
    await setDoc(ref(db, 'adminTournaments', 'registrationCup'), tournament({
      startDate: Timestamp.fromMillis(Date.now() + 86400000), endDate: Timestamp.fromMillis(Date.now() + 86400000 * 30),
    }));
    for (const uid of ['captainA', 'captainB']) {
      await setDoc(ref(db, 'captainProfiles', uid), profile(uid));
      await setDoc(ref(db, 'captainTeams', uid), captainTeam(uid));
      await setDoc(doc(db, 'captainTeams', uid, 'players', '7'), player(uid));
    }
  });
}
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-futschool-admin',
    firestore: { host, port: Number(portText), rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8') } });
});
beforeEach(async () => { await env.clearFirestore(); await seed(); });
after(async () => { if (env) await env.cleanup(); });

test('admin verificado puede leer documentos y listar con límite de 200', async () => {
  const db = adminDb();
  await assertSucceeds(getDoc(ref(db, 'adminTournaments', 'cup')));
  await assertSucceeds(getDocs(query(collection(db, 'adminTeams'), limit(200))));
});
test('sin autenticación no puede leer ni escribir', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(ref(db, 'adminTournaments', 'cup')));
  await assertFails(setDoc(ref(db, 'adminTournaments', 'unauthorized'), tournament()));
});
test('usuario regular no puede acceder a ningún recurso administrativo de otros usuarios', async () => {
  const db = env.authenticatedContext('student', { email_verified: true }).firestore();
  for (const [name, id] of [['adminTournaments', 'cup'], ['adminTeams', 'teamA'], ['adminMatches', 'any'], ['adminReservations', 'any']]) {
    await assertFails(getDoc(ref(db, name, id)));
  }
  await assertFails(setDoc(ref(db, 'adminTournaments', 'studentCup'), tournament({ createdBy: 'student' })));
});
test('claim admin sin correo verificado no concede acceso', async () => {
  const db = env.authenticatedContext('unverified', { admin: true, email_verified: false }).firestore();
  await assertFails(getDoc(ref(db, 'adminTournaments', 'cup')));
});
test('rol enviado como dato por usuario regular no concede autoridad', async () => {
  const db = env.authenticatedContext('student', { email_verified: true }).firestore();
  await assertFails(setDoc(ref(db, 'adminTournaments', 'forged'), tournament({ createdBy: 'student', admin: true })));
  await assertFails(setDoc(ref(db, 'users', 'student'), { admin: true }));
});
test('listas sin límite o con más de 200 documentos son rechazadas', async () => {
  const db = adminDb();
  await assertFails(getDocs(collection(db, 'adminTeams')));
  await assertFails(getDocs(query(collection(db, 'adminTeams'), limit(201))));
});
test('admin puede crear torneo válido sin datos personales adicionales', async () => {
  await assertSucceeds(setDoc(ref(adminDb(), 'adminTournaments', 'newCup'), tournament()));
});
test('campos desconocidos, nombres vacíos y límites extremos de torneo se rechazan', async () => {
  const db = adminDb();
  for (const [i, data] of [{ name: '' }, { name: '   ' }, { name: 'Copa\nUniversidad' }, { name: 'x'.repeat(101) }, { description: 'x'.repeat(2001) }, { maxTeams: 1 }, { maxTeams: 65 }, { maxTeams: 2.5 }, { admin: true }].entries()) {
    await assertFails(setDoc(ref(db, 'adminTournaments', `invalid${i}`), tournament(data)));
  }
});
test('fechas invertidas y autor falsificado se rechazan', async () => {
  const db = adminDb();
  await assertFails(setDoc(ref(db, 'adminTournaments', 'badDates'), tournament({ endDate: Timestamp.fromMillis(start.toMillis() - 1) })));
  await assertFails(setDoc(ref(db, 'adminTournaments', 'badAuthor'), tournament({ createdBy: 'other' })));
});
test('crear equipo y aumentar cupo exige operación atómica enlazada', async () => {
  await assertSucceeds(teamBatch(adminDb(), 'newTeam', 3).commit());
});
test('equipo sin actualización del torneo se rechaza', async () => {
  const db = adminDb();
  await assertFails(setDoc(ref(db, 'adminTeams', 'standalone'), { name: 'Equipo nuevo', tournamentId: 'cup', createdBy: adminUid, createdAt: serverTimestamp() }));
});
test('incremento de contador sin equipo nuevo y reutilizar equipo anterior se rechazan', async () => {
  const db = adminDb();
  await assertFails(updateDoc(ref(db, 'adminTournaments', 'cup'), { teamCount: 3, lastTeamId: 'absent' }));
  await assertFails(updateDoc(ref(db, 'adminTournaments', 'cup'), { teamCount: 3, lastTeamId: 'teamA' }));
});
test('equipo adicional cuando se agotó el cupo se rechaza', async () => {
  await env.withSecurityRulesDisabled(context => updateDoc(ref(context.firestore(), 'adminTournaments', 'cup'), { maxTeams: 2 }));
  await assertFails(teamBatch(adminDb(), 'overflow', 3).commit());
});
test('nombre de equipo inválido, campo inesperado o torneo distinto se rechazan', async () => {
  const db = adminDb();
  await assertFails(teamBatch(db, 'empty', 3, { name: '' }).commit());
  await assertFails(teamBatch(db, 'blank', 3, { name: '   ' }).commit());
  await assertFails(teamBatch(db, 'privileged', 3, { role: 'admin' }).commit());
  await assertFails(teamBatch(db, 'wrongCup', 3, { tournamentId: 'otherCup' }).commit());
});
test('crear partido con las tres reservas atómicas es válido', async () => {
  await assertSucceeds(matchBatch(adminDb(), 'match1').commit());
});
test('partido sin reservas completas se rechaza', async () => {
  const db = adminDb();
  await assertFails(matchBatch(db, 'missingAll', {}, 0).commit());
  await assertFails(matchBatch(db, 'missingOne', {}, 2).commit());
});
test('equipos repetidos, de otro torneo o inexistentes se rechazan', async () => {
  const db = adminDb();
  await assertFails(matchBatch(db, 'sameTeam', { awayTeamId: 'teamA' }).commit());
  await assertFails(matchBatch(db, 'otherTournament', { awayTeamId: 'teamOther' }).commit());
  await assertFails(matchBatch(db, 'missingTeam', { awayTeamId: 'absent' }).commit());
});
test('colisión de cancha se rechaza aunque cambien ambos equipos', async () => {
  const db = adminDb();
  await assertSucceeds(matchBatch(db, 'first').commit());
  await assertFails(matchBatch(db, 'collision', { homeTeamId: 'teamC', awayTeamId: 'teamD' }).commit());
});
test('colisión de equipo se rechaza aunque cambie la cancha', async () => {
  const db = adminDb();
  await assertSucceeds(matchBatch(db, 'first').commit());
  await assertFails(matchBatch(db, 'collision', { courtId: 'cancha-2', awayTeamId: 'teamC' }).commit());
});
test('fecha fuera del torneo, hora parcial y cancha no normalizada se rechazan', async () => {
  const db = adminDb();
  await assertFails(matchBatch(db, 'early', { startsAt: Timestamp.fromMillis(start.toMillis() - 3600000) }).commit());
  await assertFails(matchBatch(db, 'late', { startsAt: Timestamp.fromMillis(end.toMillis() + 86400000) }).commit());
  await assertFails(matchBatch(db, 'partialHour', { startsAt: Timestamp.fromMillis(kickOff.toMillis() + 60000) }).commit());
  await assertFails(matchBatch(db, 'unsafeCourt', { courtId: 'Cancha_1' }).commit());
});
test('estados, marcadores y campos inesperados se validan en servidor', async () => {
  const db = adminDb();
  await assertFails(matchBatch(db, 'badStatus', { status: 'admin' }).commit());
  await assertFails(matchBatch(db, 'badScore', { homeScore: 0 }).commit());
  await assertFails(matchBatch(db, 'unknownField', { privilege: true }).commit());
});
test('actualizar resultado y finalizar funciona; regresar de finalizado se rechaza', async () => {
  const db = adminDb();
  await assertSucceeds(matchBatch(db, 'match1').commit());
  const data = { updatedBy: adminUid, updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(ref(db, 'adminMatches', 'match1'), { ...data, status: 'live', homeScore: 0, awayScore: 0 }));
  await assertSucceeds(updateDoc(ref(db, 'adminMatches', 'match1'), { ...data, status: 'finished', homeScore: 2, awayScore: 1 }));
  await assertFails(updateDoc(ref(db, 'adminMatches', 'match1'), { ...data, status: 'live' }));
});
test('cambiar equipos, alterar autor o marcador fuera de rango se rechaza', async () => {
  const db = adminDb();
  await assertSucceeds(matchBatch(db, 'match1').commit());
  const meta = { updatedBy: adminUid, updatedAt: serverTimestamp() };
  await assertFails(updateDoc(ref(db, 'adminMatches', 'match1'), { ...meta, homeTeamId: 'teamC' }));
  await assertFails(updateDoc(ref(db, 'adminMatches', 'match1'), { ...meta, updatedBy: 'other' }));
  await assertFails(updateDoc(ref(db, 'adminMatches', 'match1'), { ...meta, status: 'finished', homeScore: 100, awayScore: 1 }));
  await assertFails(updateDoc(ref(db, 'adminMatches', 'match1'), { ...meta, status: 'finished', homeScore: -1, awayScore: 1 }));
});
test('reservas no pueden crearse huérfanas ni reescribirse o borrarse', async () => {
  const db = adminDb();
  await assertFails(setDoc(ref(db, 'adminReservations', 'orphan'), { matchId: 'absent', createdBy: adminUid, createdAt: serverTimestamp() }));
  await assertSucceeds(matchBatch(db, 'match1').commit());
  const reservation = ref(db, 'adminReservations', `court_cancha-1_${kickOff.toMillis()}`);
  await assertFails(updateDoc(reservation, { matchId: 'other' }));
  await assertFails(deleteDoc(reservation));
});
test('cancelación conserva reserva e impide reabrir partido', async () => {
  const db = adminDb();
  await assertSucceeds(matchBatch(db, 'match1').commit());
  const meta = { updatedBy: adminUid, updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(ref(db, 'adminMatches', 'match1'), { ...meta, status: 'cancelled' }));
  await assertFails(updateDoc(ref(db, 'adminMatches', 'match1'), { ...meta, status: 'scheduled' }));
  await assertFails(matchBatch(db, 'replacement').commit());
});
test('colecciones no declaradas y borrado de recursos se deniegan por defecto', async () => {
  const db = adminDb();
  await assertFails(getDoc(ref(db, 'privateProfiles', 'other')));
  await assertFails(setDoc(ref(db, 'privateProfiles', 'other'), { name: 'privado' }));
  await assertFails(deleteDoc(ref(db, 'adminTournaments', 'cup')));
  await assertFails(deleteDoc(ref(db, 'adminTeams', 'teamA')));
});

// Captains own their private roster; shared competition data remains admin writable.
const captainDb = (uid = 'captainA', verified = true) => env.authenticatedContext(uid,
  { email_verified: verified, email: `${uid}@example.test` }).firestore();
function audit(uid) { return { createdBy: uid, createdAt: serverTimestamp(), updatedBy: uid, updatedAt: serverTimestamp() }; }
function profile(uid, extra = {}) { return { displayName: `Capitán ${uid}`, email: `${uid}@example.test`, disabled: false, ...audit(uid), ...extra }; }
function captainTeam(uid, extra = {}) { return { name: `Equipo ${uid}`, description: '', logoBase64: null, ...audit(uid), ...extra }; }
function player(uid, extra = {}) { return { name: 'Jugador universitario', position: 'forward', jerseyNumber: 7, ...audit(uid), ...extra }; }
function registration(uid = 'captainA', extra = {}) {
  return { tournamentId: 'registrationCup', captainUid: uid, teamName: `Equipo ${uid}`, status: 'pending',
    entrantId: null, reviewNote: '', createdBy: uid, createdAt: serverTimestamp(), ...extra };
}
const registrationId = (uid = 'captainA') => `registrationCup__${uid}`;
function approveBatch(db, uid = 'captainA', count = 1, extra = {}) {
  const id = registrationId(uid);
  const batch = writeBatch(db);
  batch.set(ref(db, 'adminTeams', id), { name: `Equipo ${uid}`, tournamentId: 'registrationCup', captainUid: uid,
    registrationId: id, createdBy: adminUid, createdAt: serverTimestamp(), ...extra });
  batch.update(ref(db, 'adminTournaments', 'registrationCup'), { teamCount: count, lastTeamId: id });
  batch.update(ref(db, 'tournamentRegistrations', id), { status: 'approved', entrantId: id, reviewNote: '', reviewedBy: adminUid, reviewedAt: serverTimestamp() });
  return batch;
}
function privacy(extra = {}) { return { privacyResponsible: '', privacyContact: '', privacyNotice: '', privacyVersion: '', ...extra }; }
function settingsBatch(db, extra = {}, privacyExtra = {}) {
  const batch = writeBatch(db);
  const p = privacy(privacyExtra);
  batch.set(ref(db, 'publicPrivacy', 'notice'), p);
  batch.set(ref(db, 'appSettings', 'general'), { registrationEnabled: true, announcement: '', ...p, updatedBy: adminUid, updatedAt: serverTimestamp(), ...extra });
  return batch;
}

test('capitán crea su perfil con correo del token y sin privilegios', async () => {
  const db = captainDb('newCaptain');
  await assertSucceeds(setDoc(ref(db, 'captainProfiles', 'newCaptain'), profile('newCaptain')));
  await assertFails(setDoc(ref(db, 'captainProfiles', 'other'), profile('newCaptain')));
  await assertFails(setDoc(ref(captainDb('forged'), 'captainProfiles', 'forged'), profile('forged', { admin: true })));
  await assertFails(setDoc(ref(captainDb('wrongEmail'), 'captainProfiles', 'wrongEmail'), profile('wrongEmail', { email: 'another@example.test' })));
});
test('correo sin verificar y sesión ausente no crean perfil ni consultan datos compartidos', async () => {
  for (const db of [captainDb('newCaptain', false), env.unauthenticatedContext().firestore()]) {
    await assertFails(setDoc(ref(db, 'captainProfiles', 'newCaptain'), profile('newCaptain')));
    await assertFails(getDoc(ref(db, 'adminTournaments', 'registrationCup')));
  }
});
test('perfil activo permite consultar torneos, equipos y partidos compartidos con límite', async () => {
  const db = captainDb();
  for (const name of ['adminTournaments', 'adminTeams', 'adminMatches']) {
    await assertSucceeds(getDocs(query(collection(db, name), limit(200))));
    await assertFails(getDocs(collection(db, name)));
  }
  await assertFails(getDoc(ref(db, 'adminReservations', 'any')));
});
test('un capitán no puede leer perfiles, equipos privados ni jugadores de otro', async () => {
  const db = captainDb();
  await assertSucceeds(getDoc(ref(db, 'captainProfiles', 'captainA')));
  await assertSucceeds(getDoc(ref(db, 'captainTeams', 'captainA')));
  await assertSucceeds(getDoc(doc(db, 'captainTeams', 'captainA', 'players', '7')));
  await assertFails(getDoc(ref(db, 'captainProfiles', 'captainB')));
  await assertFails(getDoc(ref(db, 'captainTeams', 'captainB')));
  await assertFails(getDoc(doc(db, 'captainTeams', 'captainB', 'players', '7')));
  await assertFails(getDocs(query(collection(db, 'captainProfiles'), limit(200))));
  await assertFails(getDocs(query(collection(db, 'captainTeams'), limit(200))));
});
test('capitán edita su perfil pero no se concede privilegios ni altera suspensión', async () => {
  const db = captainDb();
  const refA = ref(db, 'captainProfiles', 'captainA');
  const meta = { updatedBy: 'captainA', updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(refA, { displayName: 'Nombre actualizado', ...meta }));
  await assertFails(updateDoc(refA, { disabled: true, ...meta }));
  await assertFails(updateDoc(refA, { email: 'other@example.test', ...meta }));
  await assertFails(updateDoc(refA, { role: 'admin', ...meta }));
  await assertFails(updateDoc(ref(db, 'captainProfiles', 'captainB'), { displayName: 'Intruso', ...meta }));
});
test('administrador suspende y reactiva; suspendido no lee ni escribe equipo ni datos compartidos', async () => {
  const admin = adminDb();
  const db = captainDb();
  const meta = { updatedBy: adminUid, updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(ref(admin, 'captainProfiles', 'captainA'), { disabled: true, ...meta }));
  await assertSucceeds(getDoc(ref(db, 'captainProfiles', 'captainA')));
  await assertFails(getDoc(ref(db, 'captainTeams', 'captainA')));
  await assertFails(getDoc(ref(db, 'adminTournaments', 'cup')));
  await assertFails(updateDoc(ref(db, 'captainProfiles', 'captainA'), { disabled: false, updatedBy: 'captainA', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref(db, 'captainTeams', 'captainA'), { name: 'Suspendido', updatedBy: 'captainA', updatedAt: serverTimestamp() }));
  await assertFails(getDocs(query(collection(db, 'captainTeams', 'captainA', 'players'), limit(200))));
  await assertFails(setDoc(ref(db, 'tournamentRegistrations', registrationId()), registration()));
  await assertSucceeds(updateDoc(ref(admin, 'captainProfiles', 'captainA'), { disabled: false, ...meta }));
  await assertSucceeds(getDoc(ref(db, 'captainTeams', 'captainA')));
});
test('equipo privado exige propietario y logo PNG/JPEG con tamaño acotado', async () => {
  const db = captainDb();
  const meta = { updatedBy: 'captainA', updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(ref(db, 'captainTeams', 'captainA'), { name: 'Lobos', logoBase64: 'iVBORw0KGgoAAA==', ...meta }));
  await assertFails(updateDoc(ref(db, 'captainTeams', 'captainB'), { name: 'Intruso', ...meta }));
  for (const logoBase64 of ['<script>alert(1)</script>', 'data:image/svg+xml;base64,AAA', 'iVBORw0KGgo' + 'A'.repeat(68269)]) {
    await assertFails(updateDoc(ref(db, 'captainTeams', 'captainA'), { logoBase64, ...meta }));
  }
  await assertFails(updateDoc(ref(db, 'captainTeams', 'captainA'), { name: '', ...meta }));
  await assertFails(updateDoc(ref(db, 'captainTeams', 'captainA'), { description: 'x'.repeat(1001), ...meta }));
  await assertFails(updateDoc(ref(db, 'captainTeams', 'captainA'), { createdBy: 'captainB', ...meta }));
});
test('jugadores usan número único, campos mínimos y no permiten IDOR ni cambiar autor', async () => {
  const db = captainDb();
  const playerRef = doc(db, 'captainTeams', 'captainA', 'players', '8');
  await assertSucceeds(setDoc(playerRef, player('captainA', { jerseyNumber: 8 })));
  await assertFails(setDoc(playerRef, player('captainA', { jerseyNumber: 8 })));
  await assertFails(setDoc(doc(db, 'captainTeams', 'captainA', 'players', 'wrongId'), player('captainA', { jerseyNumber: 9 })));
  await assertFails(setDoc(doc(db, 'captainTeams', 'captainA', 'players', '100'), player('captainA', { jerseyNumber: 100 })));
  await assertFails(setDoc(doc(db, 'captainTeams', 'captainA', 'players', '9'), player('captainA', { jerseyNumber: 9, birthDate: '2000-01-01' })));
  await assertFails(setDoc(doc(db, 'captainTeams', 'captainA', 'players', '9'), player('captainA', { jerseyNumber: 9, position: 'admin' })));
  await assertFails(deleteDoc(doc(db, 'captainTeams', 'captainB', 'players', '7')));
  await assertSucceeds(deleteDoc(playerRef));
});
test('cambiar camiseta mueve jugador atómicamente sin duplicar números', async () => {
  const db = captainDb();
  const batch = writeBatch(db);
  batch.set(doc(db, 'captainTeams', 'captainA', 'players', '12'), player('captainA', { jerseyNumber: 12 }));
  batch.delete(doc(db, 'captainTeams', 'captainA', 'players', '7'));
  await assertSucceeds(batch.commit());
  await assertSucceeds(updateDoc(doc(db, 'captainTeams', 'captainA', 'players', '12'), { name: 'Nombre nuevo', updatedBy: 'captainA', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, 'captainTeams', 'captainA', 'players', '12'), { jerseyNumber: 13, updatedBy: 'captainA', updatedAt: serverTimestamp() }));
});
test('administrador consulta perfiles y jugadores sin cambiar identidad ni otorgar roles', async () => {
  const db = adminDb();
  await assertSucceeds(getDocs(query(collection(db, 'captainProfiles'), limit(200))));
  await assertSucceeds(getDocs(query(collection(db, 'captainTeams'), limit(200))));
  await assertSucceeds(getDocs(query(collection(db, 'captainTeams', 'captainA', 'players'), limit(200))));
  await assertFails(updateDoc(ref(db, 'captainProfiles', 'captainA'), { email: 'different@example.test', updatedBy: adminUid, updatedAt: serverTimestamp() }));
});
test('inscripción pendiente enlaza equipo propio y torneo; duplicado y manipulación se rechazan', async () => {
  const db = captainDb();
  await assertSucceeds(getDoc(ref(db, 'tournamentRegistrations', registrationId())));
  await assertSucceeds(setDoc(ref(db, 'tournamentRegistrations', registrationId()), registration()));
  await assertFails(setDoc(ref(db, 'tournamentRegistrations', registrationId()), registration()));
  await assertFails(setDoc(ref(db, 'tournamentRegistrations', 'other'), registration()));
  await assertFails(setDoc(ref(db, 'tournamentRegistrations', registrationId('captainB')), registration('captainB')));
  await assertFails(setDoc(ref(captainDb('captainB'), 'tournamentRegistrations', registrationId('captainB')), registration('captainB', { status: 'approved', entrantId: 'any' })));
});
test('capitán consulta sólo sus solicitudes y nunca autoaprueba ni modifica resultados', async () => {
  const db = captainDb();
  await assertSucceeds(setDoc(ref(db, 'tournamentRegistrations', registrationId()), registration()));
  const other = captainDb('captainB');
  await assertSucceeds(setDoc(ref(other, 'tournamentRegistrations', registrationId('captainB')), registration('captainB')));
  await assertSucceeds(getDocs(query(collection(db, 'tournamentRegistrations'), where('captainUid', '==', 'captainA'), limit(200))));
  await assertFails(getDocs(query(collection(db, 'tournamentRegistrations'), limit(200))));
  await assertFails(getDoc(ref(db, 'tournamentRegistrations', registrationId('captainB'))));
  await assertFails(updateDoc(ref(db, 'tournamentRegistrations', registrationId()), { status: 'approved', entrantId: registrationId(), reviewedBy: 'captainA', reviewedAt: serverTimestamp() }));
  await assertFails(teamBatch(db, 'forgedEntrant', 3).commit());
  await assertFails(matchBatch(db, 'forgedMatch').commit());
});
test('aprobar exige crear participante y aumentar contador en la misma operación', async () => {
  await assertSucceeds(setDoc(ref(captainDb(), 'tournamentRegistrations', registrationId()), registration()));
  const db = adminDb();
  await assertFails(updateDoc(ref(db, 'tournamentRegistrations', registrationId()), { status: 'approved', entrantId: registrationId(), reviewedBy: adminUid, reviewedAt: serverTimestamp() }));
  await assertSucceeds(approveBatch(db).commit());
  const entrant = await getDoc(ref(db, 'adminTeams', registrationId()));
  if (entrant.data().captainUid !== 'captainA') throw new Error('La aprobación perdió la propiedad del equipo.');
  await assertFails(approveBatch(db, 'captainA', 2).commit());
});
test('aprobación rechaza cuenta suspendida, equipo falsificado y cupo agotado', async () => {
  await assertSucceeds(setDoc(ref(captainDb(), 'tournamentRegistrations', registrationId()), registration()));
  const db = adminDb();
  await assertFails(approveBatch(db, 'captainA', 1, { name: 'Equipo falsificado' }).commit());
  await assertSucceeds(updateDoc(ref(db, 'captainProfiles', 'captainA'), { disabled: true, updatedBy: adminUid, updatedAt: serverTimestamp() }));
  await assertFails(approveBatch(db).commit());
  await assertSucceeds(updateDoc(ref(db, 'captainProfiles', 'captainA'), { disabled: false, updatedBy: adminUid, updatedAt: serverTimestamp() }));
  await env.withSecurityRulesDisabled(context => updateDoc(ref(context.firestore(), 'adminTournaments', 'registrationCup'), { maxTeams: 2, teamCount: 2 }));
  await assertFails(approveBatch(db, 'captainA', 3).commit());
});
test('rechazar preserva contador y equipo; revisión terminal y nota acotada', async () => {
  await assertSucceeds(setDoc(ref(captainDb(), 'tournamentRegistrations', registrationId()), registration()));
  const db = adminDb();
  const review = { status: 'rejected', entrantId: null, reviewNote: 'Revisa tu inscripción', reviewedBy: adminUid, reviewedAt: serverTimestamp() };
  await assertFails(updateDoc(ref(db, 'tournamentRegistrations', registrationId()), { ...review, reviewNote: 'x'.repeat(501) }));
  await assertSucceeds(updateDoc(ref(db, 'tournamentRegistrations', registrationId()), review));
  await assertFails(approveBatch(db).commit());
  const cup = await getDoc(ref(db, 'adminTournaments', 'registrationCup'));
  if (cup.data().teamCount !== 0) throw new Error('Rechazar alteró el contador.');
});
test('configuración y aviso público se guardan juntos; aviso sólo expone texto institucional', async () => {
  const db = adminDb();
  await assertSucceeds(settingsBatch(db, {}, { privacyNotice: 'Texto institucional de prueba', privacyVersion: 'test-1' }).commit());
  const anonymous = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(ref(anonymous, 'publicPrivacy', 'notice')));
  await assertFails(getDocs(query(collection(anonymous, 'publicPrivacy'), limit(200))));
  await assertFails(getDoc(ref(anonymous, 'appSettings', 'general')));
  await assertFails(getDoc(ref(anonymous, 'publicPrivacy', 'another')));
  await assertFails(setDoc(ref(db, 'publicPrivacy', 'notice'), privacy({ privacyNotice: 'Texto desincronizado' })));
  await assertFails(updateDoc(ref(db, 'appSettings', 'general'), { privacyNotice: 'Texto sin publicar', updatedBy: adminUid, updatedAt: serverTimestamp() }));
  await assertFails(settingsBatch(db, {}, { email: 'private@example.test' }).commit());
  await assertSucceeds(getDoc(ref(captainDb(), 'appSettings', 'general')));
  await assertFails(settingsBatch(captainDb(), { updatedBy: 'captainA' }).commit());
});
test('inscripciones cerradas, torneo terminado y cupo completo impiden nuevas solicitudes', async () => {
  const db = adminDb();
  await assertSucceeds(settingsBatch(db, { registrationEnabled: false }).commit());
  await assertFails(setDoc(ref(captainDb(), 'tournamentRegistrations', registrationId()), registration()));
  await assertSucceeds(settingsBatch(db, { registrationEnabled: true }).commit());
  await env.withSecurityRulesDisabled(context => updateDoc(ref(context.firestore(), 'adminTournaments', 'registrationCup'), { maxTeams: 2, teamCount: 2 }));
  await assertFails(setDoc(ref(captainDb(), 'tournamentRegistrations', registrationId()), registration()));
  await env.withSecurityRulesDisabled(context => updateDoc(ref(context.firestore(), 'adminTournaments', 'registrationCup'), { teamCount: 0, endDate: Timestamp.fromMillis(Date.now() - 86400000 * 2) }));
  await assertFails(setDoc(ref(captainDb(), 'tournamentRegistrations', registrationId()), registration()));
});
test('edición administrativa de torneo preserva fechas, cuenta y propiedad', async () => {
  const db = adminDb();
  const meta = { updatedBy: adminUid, updatedAt: serverTimestamp() };
  await assertSucceeds(updateDoc(ref(db, 'adminTournaments', 'cup'), { name: 'Copa actualizada', maxTeams: 4, ...meta }));
  await assertFails(updateDoc(ref(db, 'adminTournaments', 'cup'), { maxTeams: 1, ...meta }));
  await assertFails(updateDoc(ref(db, 'adminTournaments', 'cup'), { startDate: end, ...meta }));
  await assertFails(updateDoc(ref(db, 'adminTournaments', 'cup'), { teamCount: 1, ...meta }));
  await assertFails(updateDoc(ref(captainDb(), 'adminTournaments', 'cup'), { name: 'Cambio no autorizado', updatedBy: 'captainA', updatedAt: serverTimestamp() }));
});

test('configuración rechaza tipos incorrectos, textos extremos y campos privilegiados', async () => {
  const db = adminDb();
  for (const override of [{ registrationEnabled: 'true' }, { announcement: 'x'.repeat(1001) },
    { privacyResponsible: 'x'.repeat(201) }, { privacyContact: 'x'.repeat(201) },
    { privacyNotice: 'x'.repeat(10001) }, { privacyVersion: 'x'.repeat(41) }, { admin: true }]) {
    await assertFails(settingsBatch(db, override).commit());
  }
  const anonymous = env.unauthenticatedContext().firestore();
  await assertFails(setDoc(ref(anonymous, 'publicPrivacy', 'notice'), privacy()));
  await assertFails(deleteDoc(ref(db, 'publicPrivacy', 'notice')));
});
