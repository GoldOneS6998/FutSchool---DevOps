# FutSchool · DevOps

Aplicación para organizar y consultar torneos escolares de fútbol. Este
repositorio concentra el cliente Flutter, la documentación del producto y el
flujo de colaboración Scrum con integración por Pull Request.

## Estado del incremento

El login sustituye la aplicación de ejemplo: correo y contraseña, Google,
validación, mensajes de error, observación de sesión y cierre de sesión.
Android está configurado con Firebase `futschool-2ef84`.

**Estado: revisión pendiente, no listo para producción.** Falta registrar el
certificado Android, confirmar el proveedor de correo y comprobar el acceso
con cuentas reales. El propietario autorizó ejecutar las verificaciones en GitHub Actions;
los resultados se consultan allí y la plantilla de evidencia se deja vacía. La vista web y el enlace para probar desde un
teléfono siguen pendientes; no hay un sitio publicado.

## Estructura

```text
app/                       Cliente Flutter y proyectos de plataforma
  lib/app/                 Aplicación, tema y selección de pantalla
  lib/features/auth/       Presentación, contrato y servicio Firebase
  lib/features/home/       Bienvenida tras el acceso
  lib/core/                Infraestructura compartida reservada
  lib/shared/              Componentes compartidos reservados
  test/                    Pruebas de widgets del login
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

Completa primero [Firebase](docs/firebase.md). iOS, web y escritorio requieren
configuración específica y aún no se han validado.

## Trabajo del equipo

- [Documentación](docs/README.md).
- [Product Backlog](docs/scrum/product-backlog.md).
- [Sprint de autenticación](docs/scrum/sprint-01.md).
- [Scrum, Definition of Ready y Definition of Done](docs/scrum/proceso.md).
- [Arquitectura](docs/arquitectura.md) y [decisión Firebase](docs/adr/0001-firebase-auth.md).
- [Contribución](CONTRIBUTING.md), [CI](ci/README.md) y [validación](docs/evidencias/validacion-login.md).

Estimaciones, responsables y calendario se acuerdan en planificación. No se
atribuyen aprobaciones, ceremonias ni resultados que no hayan ocurrido.
