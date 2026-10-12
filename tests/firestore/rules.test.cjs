'use strict';

const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, collection, query, limit, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp } = require('firebase/firestore');

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
