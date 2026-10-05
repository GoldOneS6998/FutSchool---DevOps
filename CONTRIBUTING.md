# Contribuir a FutSchool

## Antes de desarrollar

Selecciona una historia del [backlog](docs/scrum/product-backlog.md), crea o
vincula su Issue y confirma criterios de aceptación. El equipo acuerda
responsable, prioridad y estimación; no se asignan personas sin su acuerdo.

## GitHub Flow

1. Actualiza `main` y crea `feature/hu-XX-descripcion` para nuevas funciones o
   `hotfix/descripcion` para correcciones urgentes.
2. Trabaja en `app/`, conservando módulos y capas. Documenta decisiones
   relevantes en `docs/adr/` y cambios de configuración en `docs/`.
3. Versiona `pubspec.lock`; excluye compilaciones, credenciales privadas y
   configuración de cada equipo. El JSON Firebase es configuración del cliente,
   no una cuenta de servicio.
4. Cuando el propietario autorice verificaciones, ejecuta desde `app/`:

   ```sh
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   flutter build apk --debug
   ```

5. Usa commits convencionales: `feat(auth): implementar login Firebase`,
   `docs(scrum): documentar sprint`, `fix(auth): corregir sesión`.
6. Publica la rama y abre un PR. Usa borrador si hay verificaciones pendientes.
   Vincula la historia, explica el comportamiento y adjunta evidencia real.
7. Solicita revisión independiente. Integra con squash al cumplir Definition
   of Done; no fuerces `main` ni declares terminado el acceso sin validarlo.

## Publicación actual

El propietario autorizó ejecutar las verificaciones en GitHub Actions.
El workflow Flutter sigue siendo manual y conserva sus resultados reales en
logs y artefactos. La plantilla de documentación queda vacía para completarla
por el propietario. No marques verificaciones sin comprobar los resultados.

Consulta [el proceso Scrum](docs/scrum/proceso.md).
