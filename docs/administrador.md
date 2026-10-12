# Administración de FutSchool

## Objetivo y alcance

El módulo permite al administrador crear torneos, registrar equipos, programar partidos de una hora y actualizar su estado y marcador. Prioriza funcionamiento y persistencia real sobre el diseño de las capturas. Flutter utiliza Firebase Authentication para la identidad y Cloud Firestore para los datos y la autorización de cada operación.

La cuenta solicitada es `ernex9897@gmail.com`. El correo identifica la cuenta que el operador asignará; **no constituye una lista de permisos en el cliente**. Solo un ID token firmado por Firebase que incluya `admin: true` y `email_verified: true` permite acceder a las colecciones administrativas. Una persona no obtiene permisos al escribir `admin` en un formulario o documento. La aplicación nunca incluye Firebase Admin SDK ni credenciales de servidor.

El alcance inicial no incluye dar de alta usuarios de Authentication desde la app, editar sus contraseñas, asignar roles desde el navegador, inscripciones públicas, listados nominales de integrantes, liberación automática de reservas canceladas ni eliminación de torneos. Esas operaciones requieren diseño y pruebas adicionales; no se presentan como funciones terminadas.

## Datos y validación

| Colección | Contenido y restricciones principales |
| --- | --- |
| `adminTournaments` | Nombre de 3 a 100 caracteres, descripción de hasta 2000, fechas coherentes, cupo de 2 a 64 equipos, contador y último equipo agregado. |
| `adminTeams` | Nombre de equipo de 2 a 80 caracteres y referencia a su torneo. No se recopilan matrículas, teléfonos, documentos ni integrantes individuales. |
| `adminMatches` | Torneo, dos equipos distintos del mismo torneo, cancha con identificador normalizado, fecha/hora, estado y marcador. |
| `adminReservations` | Reservas de cancha y de ambos equipos vinculadas al partido, sin datos personales adicionales. |

Los documentos tienen `createdBy` y `createdAt`. Las correcciones de estado/marcador tienen `updatedBy` y `updatedAt`. El servidor comprueba el UID autenticado y las marcas de tiempo de servidor; el cliente no puede falsificar otro autor. No se aceptan campos desconocidos ni nombres vacíos o compuestos solo de espacios.

Las fechas del torneo representan la medianoche del calendario local del dispositivo, convertida a un instante UTC. El día final es inclusivo. Los partidos usan instantes UTC, empiezan en una hora completa y duran una hora; deben terminar antes de concluir el día final del torneo. La institución debe fijar su zona horaria antes de operar con dispositivos en regiones distintas; el módulo inicial no administra zonas institucionales o cambios de horario.

Crear un equipo exige una transacción que agregue el documento y aumente `teamCount` en uno sin superar el cupo. `lastTeamId` demuestra que se agregó un equipo nuevo, no reutilizado ni perteneciente a otro torneo. El contador no puede modificarse independientemente.

Crear un partido exige una transacción con tres reservas nuevas: `court_<cancha>_<epochMs>`, `team_<local>_<epochMs>` y `team_<visitante>_<epochMs>`. Las reglas comprueban con `getAfter` que todos los documentos concuerdan en la misma operación. Dos solicitudes simultáneas no pueden reservar la misma cancha o un mismo equipo en esa hora.

Los estados son `scheduled`, `live`, `finished` y `cancelled`. Desde programado se puede pasar a cualquier estado; desde en curso no se regresa a programado; finalizado solo admite corrección de su resultado; cancelado permanece cancelado. Los marcadores en curso/finalizado son enteros de 0 a 99; programado/cancelado tiene ambos marcadores nulos. Cancelar **conserva las reservas** para evitar liberar horarios sin un procedimiento explícito.

## Controles de acceso

`firestore.rules` aplica las mismas comprobaciones independientemente de la pantalla o herramienta utilizada. Un usuario anónimo, regular o administrador sin correo verificado no puede leer ni escribir estos datos. Un administrador puede gestionar todos los recursos administrativos: ese alcance es deliberado, no una comprobación de propiedad por estudiante. Las listas deben solicitar un límite de hasta 200 documentos. No hay permiso general para otras colecciones, actualizaciones de equipos, borrado de recursos ni reescritura de reservas.

Las operaciones administrativas vuelven a comprobar el claim; una validación de interfaz es solo una ayuda de navegación. Firebase administra contraseñas y tokens mediante sus SDK: no se almacenan contraseñas, secretos JWT ni claves privadas en Firestore, código, capturas de pruebas o logs. La configuración pública de una app Firebase no sustituye las reglas ni es una credencial de servidor.

Los campos de auditoría facilitan identificar quién cambió un resultado, pero no equivalen a un historial inmutable completo. Respaldo, restauración, monitoreo y retención deben configurarse antes de la operación institucional. La protección contra enumeración de correos debe conservarse en Authentication. App Check y presupuestos/cuotas deben evaluarse según el tráfico real; no se afirma que estén habilitados.

## Habilitar Firestore y asignar al administrador

Estado inicial conocido: Firestore no está confirmado como habilitado y el claim administrativo no ha sido asignado por este trabajo. No se ejecutó un despliegue remoto ni se modificó la cuenta solicitada.

Actualización del 12 de octubre: se comprobó en la consola que la base `(default)`
está creada en edición Standard, modo nativo y ubicación `nam5`. Las reglas
publicadas todavía son la denegación total inicial. Falta publicar las reglas de
este proyecto y asignar el claim desde un operador autorizado.

El 12 de octubre de 2026 se confirmó conservar Cloud Firestore después de recibir
un enlace de Realtime Database. Ese enlace pertenece a otro servicio y no se
utiliza como URL de conexión de este módulo; la app usa el proyecto Firebase ya
configurado y su base Firestore predeterminada `(default)`.

1. Un operador autorizado del proyecto debe abrir la [consola Firebase de FutSchool](https://console.firebase.google.com/project/futschool-2ef84/firestore), crear una base Cloud Firestore Standard en **modo producción** y decidir su ubicación considerando la institución y el tratamiento de datos. No activar reglas abiertas de modo prueba.
2. Revisar las reglas existentes antes de desplegar este archivo: el archivo deniega las demás colecciones. Si existen colecciones usadas por otra funcionalidad, integrar sus permisos comprobados; no publicar un `allow read, write: if true` para resolver errores.
3. Desde la raíz de este proyecto, instalar las herramientas y ejecutar las pruebas locales:

   ```powershell
   cd tests/firestore
   npm ci --ignore-scripts
   npm test
   ```

   Las dependencias quedan fijadas por `package-lock.json`. Se requiere Node.js 24.12 o posterior y Java 21 o posterior. La CLI está fijada para compatibilidad del emulador; cualquier actualización debe revisar requisitos y repetir las pruebas. La primera ejecución puede descargar el emulador oficial.
4. Después de las pruebas y de revisar el impacto en otras colecciones, el operador puede publicar solo las reglas e índices:

   ```powershell
   npx firebase login
   npx firebase deploy --only firestore --project futschool-2ef84 --config ../../firebase.json
   ```

5. La cuenta `ernex9897@gmail.com` debe existir en Authentication y confirmar su correo por el flujo normal de Firebase. El script no crea la cuenta, no conoce su contraseña y no marca artificialmente el correo como verificado.
6. El operador configura [Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc) con una identidad autorizada para consultar/actualizar usuarios de Authentication. Por ejemplo, en un equipo confiable con Google Cloud CLI instalada:

   ```powershell
   gcloud auth application-default login
   gcloud auth application-default set-quota-project futschool-2ef84
   npm run grant-admin
   npm run grant-admin -- --apply
   ```

   El primer comando del script comprueba la cuenta sin modificarla; `--apply` asigna el claim. Se conservan los otros claims. `firebase login` y las credenciales ADC son mecanismos diferentes: iniciar sesión en el navegador no otorga automáticamente credenciales al script. No guardar credenciales de servicio en el repositorio ni enviarlas por el chat. Usar permisos mínimos de operador, sin acceso administrativo concedido a estudiantes.
7. Cerrar sesión e iniciar sesión nuevamente para obtener el claim actualizado. La aplicación debe mostrar el panel únicamente a esa sesión autorizada. Comprobar también que una segunda cuenta regular recibe rechazo de Firestore, aunque modifique la interfaz.

Para retirar acceso:

```powershell
npm run grant-admin -- --revoke --apply
```

Se retira el claim y se revocan refresh tokens. Un ID token previamente emitido puede seguir siendo válido hasta su expiración, normalmente hasta una hora. Las reglas que comprueban claims no consultan automáticamente la revocación en cada solicitud; no se promete revocación instantánea. Si el riesgo exige bloqueo inmediato, se debe añadir un control de estado en el servidor/reglas y verificarlo con pruebas antes de ofrecer esa garantía.

## Pruebas y evidencia

`tests/firestore/rules.test.cjs` usa el emulador oficial y el proyecto `demo-futschool-admin`. Rechaza la ejecución sin `FIRESTORE_EMULATOR_HOST` de loopback. Los contextos de autenticación falsos se utilizan solo en ese emulador para comprobar las reglas: no crean usuarios reales ni validan el inicio de sesión Google real.

Se diseñaron casos de creación válida, acceso anónimo/regular/no verificado, rol falsificado en datos, listas ilimitadas, campos desconocidos, nombres vacíos, fechas inválidas, autor falsificado, cupos agotados, incremento de contador sin equipo, reservas incompletas, equipos ajenos, colisiones, estados y marcadores inválidos, cambios de equipos/autor, cancelación y denegación de colecciones no declaradas.

Estado de la ejecución debe registrarse a partir de la salida real de `npm test` y del CI. Este documento describe el alcance; no sustituye la evidencia ni afirma éxito de pruebas de producción. El emulador no verifica IAM de una cuenta real, facturación, configuración de Authentication, correo verificado real, App Check, región, copias de seguridad o accesibilidad del entorno desplegado. Falta comprobar esas condiciones después de habilitar los servicios.

## Privacidad y contexto de universidad pública

El usuario informó que participarán personas adultas de una universidad pública. Debe determinarse la institución que actúa como responsable, su carácter jurídico, normativa general/local aplicable y la unidad competente para atender derechos. La cuenta del administrador no identifica por sí misma al responsable institucional.

La [Ley General de Protección de Datos Personales en Posesión de Sujetos Obligados](https://www.diputados.gob.mx/LeyesBiblio/pdf/LGPDPPSO.pdf) es una referencia a evaluar para ese contexto; el texto oficial consultado indica última reforma de 14 de noviembre de 2025. No se aplica automáticamente un aviso de particulares ni se declara cumplimiento jurídico. La entidad responsable y los detalles de implementación deben revisarse con la universidad.

Pendientes antes del uso institucional: nombre y contacto del responsable/unidad de transparencia; aviso accesible que describa Authentication, proveedores, finalidades y posibles transferencias; procedimiento ARCO con verificación de identidad; periodos de conservación y eliminación de cuentas/datos; base jurídica y consentimiento cuando corresponda; evaluación de contratación y ubicación de servicios Firebase. Los contactos, plazos internos y finalidades opcionales no se inventan.

El módulo agrega únicamente nombres de equipos/torneos y referencias operativas. El nombre y correo del usuario autenticado ya forman parte de Authentication; el UID del autor es un identificador personal indirecto sujeto a control. No incluir nombres personales en equipos, descripciones o canchas salvo necesidad institucional justificada. No activar analítica o comunicaciones promocionales para completar este módulo.

## Riesgos residuales y operación

| Riesgo | Medida implementada | Pendiente |
| --- | --- | --- |
| Escalada desde el cliente | Claims firmados, correo verificado y reglas por operación | Asignación del claim por operador e IAM real. |
| Manipulación de cupos o agendas | Transacciones, comprobación `getAfter`, reservas inmutables | Habilitación/despliegue y prueba con sesiones reales. |
| Exposición de datos de administración | Lectura exclusiva de administrador, denegación por defecto | Aviso, retención y gestión institucional. |
| Robo de sesión administrativa | SDK Firebase, cierre de sesión, sin secretos de servidor en el cliente | MFA según evaluación de riesgo, protección del dispositivo y revocación rápida si requerida. |
| Abuso/costos y dependencias | Límites de listas/campos, versiones fijadas y pruebas | Presupuestos, cuotas, App Check y revisión de actualizaciones. |
| Pérdida de datos | No se simula un respaldo con datos de ejemplo | Configurar y comprobar restauración de respaldos. |

No hay SQL, uploads, cookies de sesión propias o backend HTTP propio en este alcance; controles como consultas SQL parametrizadas, cargas de archivos y CORS de un servidor propio no aplican a estas operaciones. Si se agregan esos componentes, se evaluarán sus controles específicos. Este módulo no se declara listo para producción hasta resolver y verificar los pendientes relevantes.

Referencias técnicas: [condiciones y operaciones atómicas en reglas Firestore](https://firebase.google.com/docs/firestore/security/rules-conditions), [custom claims](https://firebase.google.com/docs/auth/admin/custom-claims) y [pruebas de reglas](https://firebase.google.com/docs/rules/unit-tests).
