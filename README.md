# FutSchool · DevOps

Aplicación para organizar y consultar torneos escolares de fútbol. Este
repositorio concentra el cliente Flutter, la documentación del producto y el
flujo de colaboración Scrum con integración por Pull Request.

## Estado del incremento

El [login compartido y ambos roles](docs/roles-y-capitanes.md) conecta administrador
y capitanes a Firestore: equipo propio, jugadores, inscripciones con revisión,
torneos, calendario, resultados, configuración y privacidad. El incremento
del 13 de octubre tiene [alcance Scrum](docs/scrum/sprint-03-roles.md) y
[evidencia separada](docs/evidencias/validacion-roles.md). La [vista de QA local](docs/qa-local.md)
permite revisar ambos roles con datos ficticios. La nueva versión de reglas y el
claim del administrador real requieren activación; no se declara producción lista.

El módulo de [administrador](docs/administrador.md) agrega torneos, equipos,
partidos y marcadores sobre Firestore, con permisos verificados por Security Rules.
Se trabaja en `feature/administrador`; ver [alcance y aceptación](docs/scrum/sprint-02-administrador.md).
La activación de Firestore y del primer administrador se realiza según la guía.
Los resultados locales del módulo están en [validación del administrador](docs/evidencias/validacion-admin.md);
la plantilla histórica del login no reemplaza esta evidencia.

El login sustituye la aplicación de ejemplo: correo y contraseña, Google,
validación, mensajes de error, observación de sesión y cierre de sesión.
Android está configurado con Firebase `futschool-2ef84`.

**Estado: revisión pendiente, no listo para producción.** Falta registrar el
certificado Android, confirmar el proveedor de correo y comprobar el acceso
con cuentas reales. El propietario autorizó ejecutar las verificaciones en GitHub Actions;
los resultados se consultan allí y la plantilla de evidencia se deja vacía.
Firebase web ya tiene configuración cliente; falta comprobar el acceso real.
El enlace para un teléfono fuera del equipo sigue pendiente; no hay sitio publicado.

## Estructura

```text
app/                       Cliente Flutter y proyectos de plataforma
  lib/app/                 Aplicación, tema y selección de pantalla
  lib/features/auth/       Presentación, contrato y servicio Firebase
  lib/features/home/       Bienvenida tras el acceso
  lib/features/admin/      Administración, contratos y repositorio Firestore
  lib/features/captain/    Equipo propio, integrantes y competición compartida
  lib/features/privacy/    Aviso público accesible antes del registro
  lib/core/                Infraestructura compartida reservada
  lib/shared/              Componentes visuales compartidos
  test/                    Pruebas de autenticación, permisos y administración
tests/firestore/           Pruebas de reglas en emulador y dependencias fijadas
scripts/grant-admin.cjs    Asignación del primer administrador por operador
firestore.rules           Autorización y validación en servidor
docs/                      Documentos originales y documentación técnica
  scrum/                   Backlog, sprint y acuerdos de trabajo
  adr/                     Decisiones de arquitectura
  evidencias/              Registro de validación
ci/                        Guía de controles y ejecución
.github/                   Plantillas de Issues, PR y workflows
```

Los módulos reservados y plataformas generadas no representan funcionalidades
terminadas. Los PDF originales de `docs/` se conservan.

## Inicio rápido

Requisitos del cliente incorporado: Flutter **3.47.5**, Dart **3.13.4**, SDK
Android compatible y JDK. El wrapper fija Gradle **9.3.1**.

```sh
git clone https://github.com/HecCol/FutSchool---DevOps.git
cd FutSchool---DevOps/app
flutter pub get
flutter devices
flutter run -d ID_DEL_DISPOSITIVO_ANDROID
```

Completa primero [Firebase](docs/firebase.md). Android y web tienen configuración
cliente; iOS y escritorio requieren configuración específica. El acceso con
cuentas reales sigue pendiente de validación.

## Trabajo del equipo

- [Documentación](docs/README.md).
- [Ejecutar localmente](docs/ejecucion-local.md).
- [Product Backlog](docs/scrum/product-backlog.md).
- [Sprint de autenticación](docs/scrum/sprint-01.md).
- [Scrum, Definition of Ready y Definition of Done](docs/scrum/proceso.md).
- [Arquitectura](docs/arquitectura.md) y [decisión Firebase](docs/adr/0001-firebase-auth.md).
- [Contribución](CONTRIBUTING.md), [CI](ci/README.md) y [validación](docs/evidencias/validacion-login.md).

Estimaciones, responsables y calendario se acuerdan en planificación. No se
atribuyen aprobaciones, ceremonias ni resultados que no hayan ocurrido.
