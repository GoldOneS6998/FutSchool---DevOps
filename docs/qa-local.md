# QA local de ambos roles

Estas cuentas y datos son ficticios; funcionan únicamente en los emuladores.
El proyecto `demo-futschool-admin` no utiliza credenciales administrativas reales.
El cliente de QA verifica que se abra en `localhost` o `127.0.0.1` y conecta
Authentication a 9099 y Firestore a 8080. Todos los servicios escuchan en loopback.

1. En `tests/firestore`, con Node 24.12+ y Java 21+, instalar con
   `npm ci --ignore-scripts` y arrancar:

   ```powershell
   npx firebase emulators:start --only auth,firestore --project demo-futschool-admin --config ../../firebase.json
   ```

2. En otra terminal, desde `tests/firestore`, preparar cuentas ficticias:

   ```powershell
   $env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
   $env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
   $qaSecret = Read-Host 'Contraseña temporal de QA (mínimo 12 caracteres)' -AsSecureString
   $env:FUTSCHOOL_QA_PASSWORD = [Net.NetworkCredential]::new('', $qaSecret).Password
   node preview-seed.cjs
   Remove-Item Env:FUTSCHOOL_QA_PASSWORD
   ```

3. Desde `app`, compilar/abrir el cliente exclusivamente local:

   ```powershell
   flutter pub get --enforce-lockfile
   flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5431 --target test/support/preview_main.dart
   ```

   En Windows sin modo desarrollador, si solo se requiere web, asignar antes
   `$env:FLUTTER_WINDOWS='false'`. Es una selección temporal del destino de Flutter,
   no un cambio de permisos de Windows ni una modificación de Security Rules.

4. Abrir `http://localhost:5431/`. Correo `captain.demo@example.test` para capitán,
   `admin.demo@example.test` para administrador y `other.demo@example.test` para
   segundo capitán. Usa la contraseña temporal que introdujiste en el paso 2;
   no existe una contraseña predeterminada. Nunca reutilices una contraseña real.
   El script no imprime esa contraseña ni reinicia el cupo de un torneo existente. Asigna
   verificación/claim solo en el emulador y rechaza ejecutarse sin los dos destinos
   locales explícitos.

5. Comprobar: equipo → jugador → inscripción pendiente → cambiar a admin →
   revisar/aprobar → volver a capitán → aprobación visible. Crear otro participante
   y programar un partido; corregir resultado y revisar calendario/posiciones.
   Probar también rechazos de acceso a datos ajenos mediante la suite de reglas.

Detener emuladores al concluir. Los datos locales no se sincronizan con el
proyecto real. Ejecutar `npm test` utiliza otro ciclo de emulador sobre el mismo
puerto: detener primero la vista local para evitar conflicto y no atribuir
resultados de QA a producción. Google real, correos reales, respaldos e IAM no
se validan con estas cuentas ficticias.
