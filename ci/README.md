# Integración continua

`admin-validation.yml` valida Pull Requests que modifican la app, las reglas o
las pruebas de Firestore. También permite ejecución manual. Comprueba formato,
análisis, regresión Flutter y compilación web; en otro job ejecuta las reglas
contra `demo-futschool-admin` en el emulador. Usa Node.js 24 y Java 21 para las
herramientas actuales de Firebase. No utiliza secretos ni despliega a Firebase.
La auditoría de npm bloquea alertas críticas y muestra las demás; su alcance y
los riesgos residuales de las herramientas están documentados en la evidencia.

Los resultados locales del incremento están registrados en
[`docs/evidencias/validacion-admin.md`](../docs/evidencias/validacion-admin.md).
La ejecución de CI remoto se comprueba por separado; no se da por aprobada al
añadir un workflow.

El workflow existente `ci.yml` conserva su validación estructural automática
en push a main y Pull Request. No ejecuta pruebas de la app.

`flutter-validation.yml` agrega un control **manual** (`workflow_dispatch`)
de formato, análisis, pruebas y APK Android, con Flutter 3.47.5 y JDK 17.
El propietario autorizó su ejecución en GitHub Actions. Los resultados reales
se conservan en los logs y en el artefacto `futschool-test-results`; el registro
Markdown mantiene campos vacíos para completar manualmente.

El equipo puede iniciarlo desde Actions tras integrar el
workflow en la rama predeterminada, seleccionando la referencia correspondiente.
Para validar el PR antes de integrar, ejecutar los comandos de CONTRIBUTING en
una copia de su rama. Un workflow escrito no equivale a un resultado aprobado.

El APK debug se conserva como artefacto temporal; no es release de producción.
Firma release, protección de ramas, entornos y permisos de despliegue quedan
pendientes de configuración por administradores. No se publican tiendas ni sitios.
