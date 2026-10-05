# Integración continua

El workflow existente `ci.yml` conserva su validación estructural automática
en push a main y Pull Request. No ejecuta pruebas de la app.

`flutter-validation.yml` agrega un control **manual** (`workflow_dispatch`)
de formato, análisis, pruebas y APK Android, con Flutter 3.47.5 y JDK 17.
No se dispara por publicar este incremento: el propietario pausó las pruebas.

Cuando se autorice, el equipo puede iniciarlo desde Actions tras integrar el
workflow en la rama predeterminada, seleccionando la referencia correspondiente.
Para validar el PR antes de integrar, ejecutar los comandos de CONTRIBUTING en
una copia de su rama. Un workflow escrito no equivale a un resultado aprobado.

El APK debug se conserva como artefacto temporal; no es release de producción.
Firma release, protección de ramas, entornos y permisos de despliegue quedan
pendientes de configuración por administradores. No se publican tiendas ni sitios.
