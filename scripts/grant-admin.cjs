'use strict';

// This trusted operator script never belongs in a browser or Flutter bundle.
const path = require('node:path');
const { createRequire } = require('node:module');
const adminRequire = createRequire(path.resolve(__dirname, '../tests/firestore/package.json'));
const { initializeApp, applicationDefault, deleteApp } = adminRequire('firebase-admin/app');
const { getAuth } = adminRequire('firebase-admin/auth');

const projectId = 'futschool-2ef84';
const administratorEmail = 'ernex9897@gmail.com';
const args = new Set(process.argv.slice(2));
const allowedArgs = new Set(['--apply', '--revoke', '--help']);
if ([...args].some(argument => !allowedArgs.has(argument))) {
  console.error('Argumento desconocido. Usa --help.');
  process.exit(1);
}
if (args.has('--help')) {
  console.log('Uso: npm run grant-admin -- [--apply] [--revoke]');
  console.log('Cuenta fija: ernex9897@gmail.com; proyecto fijo: futschool-2ef84.');
  console.log('Sin --apply comprueba la cuenta y muestra el cambio, sin modificarla.');
  console.log('Requiere credenciales Application Default Credentials de un operador autorizado.');
  process.exit(0);
}
if (process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Este script opera la cuenta real configurada. Retira FIREBASE_AUTH_EMULATOR_HOST antes de usarlo.');
  process.exit(1);
}

async function main() {
  const app = initializeApp({ projectId, credential: applicationDefault() });
  try {
    const auth = getAuth(app);
    const user = await auth.getUserByEmail(administratorEmail);
    if (user.email !== administratorEmail) throw Object.assign(new Error('Configured account email mismatch'), { code: 'local/email-mismatch' });
    if (user.disabled) throw Object.assign(new Error('Configured account is disabled'), { code: 'local/account-disabled' });
    if (!args.has('--revoke') && !user.emailVerified) {
      throw Object.assign(new Error('Configured account email is not verified'), { code: 'local/email-not-verified' });
    }
    // Preserve unrelated existing claims. Never mark an email verified here.
    const claims = { ...user.customClaims };
    if (args.has('--revoke')) delete claims.admin;
    else claims.admin = true;
    if (!args.has('--apply')) {
      console.log(args.has('--revoke') ? 'Validación completada: se retiraría el permiso admin. No se modificó la cuenta.'
        : 'Cuenta verificada: se asignaría admin=true. No se modificó la cuenta.');
      return;
    }
    await auth.setCustomUserClaims(user.uid, claims);
    if (args.has('--revoke')) {
      await auth.revokeRefreshTokens(user.uid);
      console.log('Permiso admin retirado y refresh tokens revocados. Los ID tokens emitidos pueden seguir vigentes hasta su expiración.');
    } else {
      console.log('Permiso admin asignado. La cuenta debe cerrar sesión e iniciar sesión de nuevo para recibir el nuevo claim.');
    }
  } finally {
    await deleteApp(app);
  }
}
main().catch(error => {
  const messages = {
    'auth/user-not-found': 'La cuenta configurada aún no existe en Firebase Authentication.',
    'local/email-mismatch': 'La identidad obtenida no coincide con la cuenta configurada.',
    'local/account-disabled': 'La cuenta configurada está deshabilitada.',
    'local/email-not-verified': 'Verifica el correo mediante Firebase antes de asignar el permiso admin.',
    'auth/insufficient-permission': 'Las credenciales del operador no tienen permisos suficientes para administrar Authentication.',
  };
  console.error(messages[error.code] || 'No se completó la operación. Comprueba ADC, conectividad y permisos del operador; no compartas credenciales.');
  process.exitCode = 1;
});
