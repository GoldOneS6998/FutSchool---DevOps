# Registro de validación del login

Plantilla de resultados para completar por el propietario. Los campos de
resultados reales y evidencia se dejan vacíos por solicitud expresa.

## Ejecución automatizada

El workflow `flutter-validation.yml` ejecuta formato, análisis, pruebas de
widgets y compilación Android. Los logs y artefactos reales se conservan en
GitHub Actions; esta plantilla no los sustituye ni afirma resultados.

La ejecución se realiza en el fork de publicación sobre la rama del PR:
[Actions](https://github.com/GoldOneS6998/FutSchool---DevOps/actions).
No requiere integrar todavía el PR en el repositorio destino.

| Campo | Valor a completar |
| --- | --- |
| Fecha y responsable | |
| Commit/ref comprobado | |
| Enlace a ejecución de Actions | |
| Entorno y dispositivo | |

| Control | Resultado real | Evidencia / observaciones |
| --- | --- | --- |
| Formato sobre el commit comprobado | | |
| Análisis estático | | |
| Pruebas de widgets | | |
| Build Android debug | | |
| Acceso Firebase con correo real | | |
| Acceso Google real | | |
| Cancelación del selector Google | | |
| Persistencia de sesión en teléfono | | |
| Cierre de sesión en teléfono | | |
| Revisión independiente | | |
| Vista web/enlace remoto | | |

## Alcance de las pruebas

Los widgets usan un servicio de prueba: verifican el formulario y las
transiciones de sesión sin autenticar contra Firebase real. La compilación
verifica integración técnica; no demuestra acceso OAuth en un dispositivo.

La prueba manual depende de registrar las huellas, confirmar los proveedores y
usar cuentas reales. El enlace web sigue pausado y sin configuración Firebase
web. No completar los campos de estas pruebas con resultados de widgets.

Registrar solo evidencia observada, sin contraseñas, tokens ni datos personales.
No declarar Definition of Done sin validación real y revisión independiente.
