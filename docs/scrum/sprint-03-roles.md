# Incremento 03: login común y ambos roles

Fecha: 13 de octubre de 2026. Alcance solicitado por el propietario a partir del
Figma. Este documento organiza el trabajo; no atribuye ceremonias, responsables,
puntos o aprobaciones que no se hayan acordado.

## Objetivo

Completar el panel administrativo y el recorrido del capitán desde el mismo
login, con persistencia y permisos verificables, conservando Flutter y Firebase.

| Historia | Criterio de aceptación | Implementación |
| --- | --- | --- |
| HU-01 | Capitán ve equipo, próximo partido, torneo y solicitudes reales | Inicio de capitán nuevo |
| HU-04 | Admin consulta perfiles/equipos, suspende acceso y configura avisos/inscripciones | Panel y configuración persistente |
| HU-05 | Admin crea torneo y puede corregir nombre, descripción y cupo sin romper participantes | Edición limitada y validación de cupo |
| HU-06 | Capitán busca/filtra torneos y consulta detalle, participantes, agenda y resultados | Listado/detalles conectados a Firestore |
| HU-07 | Cuenta verificada crea/edita exclusivamente su equipo y escudo acotado | Equipo por UID, logo PNG/JPEG |
| HU-08 | Capitán agrega/edita/elimina sus jugadores; dorsal repetido rechazado | Jugadores por dorsal, confirmación de borrado |
| HU-09 | Una solicitud por equipo/torneo, admin aprueba/rechaza, estado visible al dueño | Revisión atómica con control de cupo |
| HU-10 | Admin programa dos participantes del torneo, conserva control de cancha/equipos y corrige resultado | Flujo existente integrado con participantes aprobados |
| AUTH-RESET | Correo inválido rechazado y respuesta de recuperación no enumera cuentas | Recuperación mediante Firebase |
| PRIVACIDAD | Aviso accesible antes del registro y contacto/versión editables; incompleto señalado | Documento público separado, evaluación institucional pendiente |

## Definición de terminado para este incremento

- Implementación completa, esquemas compatibles y sin botones ficticios en los flujos nuevos.
- Reglas con pruebas negativas de propiedad, permisos, campos y operaciones atómicas.
- Regresión de login, rutas por rol, cierre de sesión y errores de conexión.
- Análisis, formato y compilación web revisados.
- Evidencia real registrada sin contraseñas ni tokens de usuarios reales.
- Activación externa, privacidad y riesgos residuales distinguidos de validación local.

El [registro de evidencia](../evidencias/validacion-roles.md) es la autoridad para
los resultados, no la existencia de esta lista. Revisión del equipo, despliegue de
reglas nuevas, claim administrativo, sesiones reales y aprobación del aviso no
se consideran realizados por entregar código o ejecutar emuladores.
