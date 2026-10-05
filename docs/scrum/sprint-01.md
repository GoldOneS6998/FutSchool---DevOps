# Sprint 01 · Acceso a FutSchool

Registro del incremento preparado, no acta de una ceremonia realizada.
Periodo, capacidad, estimaciones y responsables: por acordar en Planning.

## Objetivo propuesto

Permitir al usuario entrar y salir de FutSchool con correo/contraseña o Google
en Android, con errores comprensibles y sesión administrada por Firebase.

## Sprint Backlog

Seguimiento: [HU-03 / Issue #3](https://github.com/HecCol/FutSchool---DevOps/issues/3)
y [AUTH-GOOGLE / Issue #4](https://github.com/HecCol/FutSchool---DevOps/issues/4).

| Tarea | Historia | Estado | Evidencia o dependencia |
| --- | --- | --- | --- |
| Formulario y validaciones | HU-03 | Implementada | `app/lib/features/auth/presentation/login_page.dart` |
| Contrato y adaptación Firebase | HU-03 | Implementada | `domain/auth_service.dart`, `data/firebase_auth_service.dart` |
| Acceso Google | AUTH-GOOGLE | Implementada | Cliente Google y credencial Firebase |
| Sesión y cierre | HU-03 | Implementada | `app/app.dart`, bienvenida |
| Configuración Android | Ambas | Incorporada | JSON real y Gradle; falta certificado en consola |
| Registrar SHA-1 y confirmar proveedor correo | Ambas | Pendiente | Acción en cuenta Firebase propietaria |
| Pruebas de widgets | Ambas | Ejecución autorizada | Consultar logs y artefactos de GitHub Actions |
| Build Android final | Ambas | Ejecución autorizada | Consultar GitHub Actions |
| Pruebas de acceso real en teléfono | Ambas | Pendiente | Certificado y cuenta real |
| Revisión independiente e integración | Ambas | Pendiente | PR borrador |
| Documentación y plantillas | Ambas | Preparadas | `docs/`, `.github/`, `ci/` |

## Impedimentos y decisiones

- Firebase todavía requiere configuración de certificado para Google Android.
- Sin confirmación del proveedor correo ni acceso real verificado.
- El propietario autorizó pruebas en GitHub Actions; los resultados en la
  documentación quedan vacíos para que él los complete. DoD sigue pendiente.
- La cuenta de publicación no tiene permiso de escritura en el repositorio
  destino; entrega mediante fork y PR, conservando su `main`.
- Vista web fuera del objetivo Android actual; preparación pausada.

## Review y retrospectiva

Pendientes. Cuando se realicen, registrar fecha, participantes reales, feedback,
decisiones y una mejora verificable. No se afirma aceptación ni velocidad.
