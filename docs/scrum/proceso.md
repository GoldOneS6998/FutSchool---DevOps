# Acuerdos Scrum

Proceso propuesto para que el equipo confirme en su próxima planificación.
Este documento no acredita ceremonias realizadas ni asigna integrantes.

## Responsabilidades

| Responsabilidad | Trabajo esperado | Asignación |
| --- | --- | --- |
| Product Owner | Ordenar backlog y aceptar valor del incremento | Por confirmar por el equipo |
| Scrum Master | Facilitar eventos y remover impedimentos | Por confirmar por el equipo |
| Developers | Diseñar, implementar, verificar y mantener el incremento | Por confirmar por el equipo |

## Cadencia propuesta

Sprint de dos semanas, fechas por confirmar. Planning: objetivo, capacidad,
historias y tareas. Daily de hasta 15 minutos: progreso hacia el objetivo y
ajuste del plan. Refinamiento: aclarar criterios y dependencias. Review:
demostrar solo comportamiento verificable y obtener feedback. Retrospectiva:
elegir una mejora concreta con responsable acordado. Las actas se registran
después de cada evento; no se rellenan retrospectivamente como si hubieran ocurrido.

## Definition of Ready

- Historia describe usuario, necesidad y valor.
- Criterios de aceptación observables y dependencias identificadas.
- Datos, permisos y plataforma acordados.
- Equipo estima tamaño y confirma capacidad en Planning.

## Definition of Done

- Criterios de aceptación satisfechos con evidencia verificable.
- Revisión independiente aprobada y PR integrado según acuerdos del repositorio.
- Formato, análisis, pruebas relevantes y build exitosos sobre el cambio final.
- Para autenticación: validación real de ambos proveedores, persistencia y cierre.
- Configuración y documentación actualizadas; sin credenciales administrativas.
- Sin fallos críticos conocidos; aceptación registrada por el equipo.

La instrucción de no ejecutar pruebas pausa la verificación, pero no reduce la
DoD. El login permanece en revisión; no se mueve a Done ni se publica como release.

## Tablero propuesto

Backlog → Ready → In Progress → Review → Done. Bloqueos se registran como
dependencia/impedimento dentro del estado actual. Cada Issue enlaza historia,
criterios, PR y evidencia. GitHub Projects es opcional; este backlog versionado
es la referencia hasta configurar un tablero real. No hay burndown ni velocidad
sin estimaciones y datos históricos reales.
