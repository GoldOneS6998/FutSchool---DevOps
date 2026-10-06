# Product Backlog

Fecha de actualización: 2026-10-06. Priorización propuesta, pendiente de acuerdo
del equipo. P1: siguiente entrega; P2: después del acceso; P3: ampliación.
Estimaciones y responsables pendientes; no se inventan puntos ni compromisos.

| ID | Historia | Prioridad | Estado |
| --- | --- | --- | --- |
| HU-03 | Como usuario registrado quiero acceder con correo y contraseña para consultar torneos | P1 | Implementada, revisión y validación real pendientes |
| AUTH-GOOGLE | Como usuario quiero acceder con Google para usar mi cuenta existente | P1 | Implementada, certificado y validación pendientes |
| HU-01 | Como usuario quiero navegar al inicio para encontrar las funciones principales | P2 | Solo bienvenida, navegación restante pendiente |
| HU-02 | Como estudiante quiero crear una cuenta para acceder al sistema | P2 | Backlog |
| HU-04 | Como administrador quiero funciones autorizadas para gestionar el sistema | P2 | Backlog |
| HU-05 | Como administrador quiero crear torneos para organizarlos | P2 | Backlog |
| HU-06 | Como usuario quiero consultar torneos y su detalle | P2 | Backlog |
| HU-07 | Como capitán quiero registrar mi equipo | P2 | Backlog |
| HU-08 | Como capitán quiero agregar y editar jugadores | P2 | Backlog |
| HU-09 | Como capitán quiero solicitar inscripción a un torneo | P2 | Backlog |
| HU-10 | Como administrador quiero registrar partidos de equipos inscritos | P2 | Backlog |
| AUTH-RESET | Como usuario quiero recuperar mi contraseña | P3 | Propuesta a refinar |
| WEB-PREVIEW | Como propietario quiero probar desde el navegador de mi teléfono | P3 | Configuración web incorporada; enlace externo y acceso real pendientes |

Los identificadores HU provienen del alcance previo. Google y vista web son
pedidos posteriores del propietario.

## Seguimiento en GitHub

| Historia | Issue del repositorio destino | Situación |
| --- | --- | --- |
| HU-03 | [#3 · Correo, sesión y cierre](https://github.com/HecCol/FutSchool---DevOps/issues/3) | Abierta; verificación pendiente |
| AUTH-GOOGLE | [#4 · Certificado y Google Sign-In](https://github.com/HecCol/FutSchool---DevOps/issues/4) | Abierta; dependencia Firebase |

Las demás historias todavía no tienen Issues creadas por esta entrega.

## Aceptación del incremento de acceso

### HU-03

- Campos vacíos o correo inválido muestran error sin enviar credenciales.
- Contraseña se oculta y puede mostrarse de forma explícita.
- Firebase rechaza credenciales inválidas sin mostrar bienvenida.
- Credenciales válidas generan sesión y abren bienvenida.
- Se bloquean envíos repetidos mientras hay operación pendiente.
- La sesión restaurada abre bienvenida; cerrar sesión devuelve al formulario.

### AUTH-GOOGLE

- El botón inicia el selector Google en Android.
- Solo una credencial validada por Firebase permite acceder.
- Cancelar o fallar el acceso permite reintentar y mantiene el login.
- No solicita permisos de contactos ni permisos administrativos.
- El cierre Firebase devuelve al login sin eliminar la cuenta del teléfono.

### WEB-PREVIEW

App Firebase web registrada y opciones incorporadas. Antes de publicar el enlace:
confirmar dominio autorizado y acordar alcance/duración. El arranque local no
confirma autenticación real ni acceso desde otro dispositivo.
