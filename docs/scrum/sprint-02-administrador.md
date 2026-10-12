# Incremento de administración

## Objetivo

Permitir a una cuenta administradora verificada crear torneos, registrar equipos,
programar partidos y actualizar resultados con persistencia en Firestore.
La cuenta inicial indicada por el propietario es ernex9897@gmail.com. El correo
no otorga permisos en el cliente: se requiere el custom claim firmado `admin`.

## Historias y aceptación

| Historia | Criterios |
| --- | --- |
| ADM 01 Acceso | Sin sesión, sin claim o sin correo verificado no se consultan datos administrativos. Firestore rechaza peticiones directas. |
| ADM 02 Torneos | Nombre, fechas y cupo válidos; fallo de red mantiene el formulario. |
| ADM 03 Equipos | Torneo existente y cupo disponible; contador y equipo se guardan juntos. |
| ADM 04 Partidos | Local y visitante distintos del mismo torneo; rango de fechas; reserva atómica de cancha y ambos equipos. |
| ADM 05 Resultados | Estados permitidos y goles entre 0 y 99; finalizados no se reabren. |
| ADM 06 Mantenimiento | Análisis estático, regresión de login y reglas en emulador; configuración documentada. |

## Límites de esta implementación

Se conserva la navegación actual del alumnado. Los módulos existentes de torneos
y Mi Equipo usan sus datos de ejemplo; no se migran de manera automática.
La administración usa colecciones separadas para evitar alterar esos contratos.
No se añaden listas de alumnos, datos de salud, teléfonos o matrículas.
La gestión de cuentas de Authentication y configuración institucional requiere
un servicio confiable y requisitos adicionales; no se representa con botones sin función.
No se implementa autoasignación de administradores.

Partidos de 60 minutos que comienzan a una hora completa; una cancelación conserva
su reserva para evitar cambios silenciosos de calendario. Reprogramar, liberar reservas
y distintas duraciones requieren un flujo posterior con reglas y pruebas propias.
Listas limitadas a 200 documentos, con indicador del límite visible.

## Estado

Implementación en `feature/administrador`, basada en `origin/chore/limpieza`.
El código y las pruebas tienen estados independientes de la activación de Firestore,
la publicación de reglas y la asignación del claim en el proyecto real.
No hay despliegue automático ni declaración de preparación para producción.
Los resultados concretos de esta revisión se registran en `docs/evidencias/validacion-admin.md`.
No se atribuyen responsables, fechas de sprint ni ceremonias no acordadas.
