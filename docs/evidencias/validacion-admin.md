# Validación del administrador

Revisión local del 9 de octubre de 2026. Base: `origin/chore/limpieza` en
`b99d21c`. Rama de implementación: `feature/administrador`.

El 12 de octubre se confirmó continuar con Cloud Firestore y se volvió a
ejecutar `npm audit --audit-level=critical`: salida 0, manteniendo 7 entradas
altas, 5 moderadas y 0 críticas. Las pruebas de aplicación y emulador indicadas
abajo fueron ejecutadas el 9 de octubre; no se les atribuye una fecha nueva.

## Resultados ejecutados

| Control | Estado | Resultado real |
| --- | --- | --- |
| Formato Dart | Verificado | 26 archivos revisados, 0 cambios al ejecutar el formato final. |
| Análisis Flutter | Verificado | `flutter analyze --no-pub`: `No issues found`. |
| Pruebas Flutter | Verificado | `flutter test --no-pub --reporter expanded`: 35 pasaron, 0 fallaron. |
| Reglas de Firestore | Verificado en emulador | `npm test`: 26 pasaron, 0 fallaron, proyecto `demo-futschool-admin`. |
| Compilación web release | Verificado | `flutter build web --release --no-pub`: `Built build/web`, salida 0. |
| Script de operador | Verificado parcialmente | Sintaxis Node y `--help` correctos; no se ejecutó asignación o revocación real. |
| Detección de credenciales | Verificado parcialmente | 0 coincidencias de los patrones de claves privadas, tokens GitHub, refresh tokens y client secrets en archivos de texto versionables. |
| Revisión cruzada del repositorio y reglas | Ejecutada | No se encontraron incompatibilidades materiales de campos o permisos. No equivale a certificación o auditoría completa. |
| Dependencias Node | Revisadas, alertas residuales | `npm audit --json`: 0 críticas, 7 altas, 5 moderadas; 12 entradas de paquetes afectadas, incluyendo propagación transitiva. |
| Proyecto Firebase real | Comprobado parcialmente | Consola del 12 de octubre: base `(default)` Standard/nativa creada en `nam5`, reglas iniciales de denegación total. Claim y pruebas de extremo a extremo pendientes. |
| CI de GitHub y revisión del equipo | Correcciones preparadas | PR 14 sigue en borrador. SonarQube identificó 2 hallazgos de seguridad y 4 de mantenimiento; corregidos en código, nuevo análisis remoto pendiente. |

Herramientas de cliente: Flutter 3.47.5 y Dart 3.13.4. Herramientas del emulador:
Node.js 24.13.0, Java 21 y Firebase CLI 15.33.0. Las versiones instalables quedan
registradas en `app/pubspec.lock` y `tests/firestore/package-lock.json`.

## Dependencias y riesgos residuales

La auditoría inicial de las herramientas Node reportó 29 entradas afectadas,
incluida una crítica. Se actualizó Firebase CLI a 15.33.0, Firebase Admin a
14.5.0 y las pruebas a rules-unit-testing 6.0.0/Firebase 13.0.0. Se fijó
`@grpc/grpc-js` 1.14.5 mediante override para corregir sus advisories. Es una
versión de la misma línea mayor, fuera del rango `~1.9` fijado por el SDK;
las pruebas contra el emulador se repitieron después del cambio. La operación
del script sobre una cuenta real permanece pendiente.

Quedan 7 entradas altas y 5 moderadas en las herramientas de desarrollo y de
operación, que no se empaquetan con Flutter. El número incluye paquetes que
heredan un mismo advisory; no significa 12 vulnerabilidades independientes:

- [basic-ftp, procesamiento de listados](https://github.com/advisories/GHSA-c475-qrg2-pj4r): corrección en 6.2.1; la dependencia instalada usa la línea 5. La actualización mayor requiere comprobar la integración `get-uri`/proxy. Las pruebas de Firestore no validan FTP.
- [braces, patrones profundamente anidados](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm): sin versión corregida indicada en el advisory consultado. Se propaga por Chokidar y Firebase CLI.
- Alertas moderadas de OpenTelemetry, re2 y uuid y su propagación por dependencias de la CLI: quedan pendientes de actualización compatible.

No se ejecuta `npm audit fix --force` ni se baja Firebase a una versión antigua
para obtener un contador menor. El CI comprueba la auditoría y falla ante alertas
críticas; las demás alertas permanecen visibles. No se considera aceptado el
riesgo para operación institucional o despliegue. Antes de utilizar las
herramientas con credenciales administrativas reales, el responsable debe
revisar estas alertas, el alcance de los comandos necesarios y las correcciones
disponibles. No se ejecutó un despliegue con estas herramientas.

## Alcance de las pruebas

El 12 de octubre se repitió la suite de reglas tras `npm ci --ignore-scripts`:
26 pruebas aprobadas, 0 fallidas. Se verificaron la sintaxis y `--help` del script
de operador después de corregir los constructores de error y la copia de claims.
No se ejecutó el script con credenciales ni se alteraron usuarios reales.

Las acciones de `admin-validation.yml` quedaron fijadas a SHA completos obtenidos
de los repositorios oficiales, y la instalación de npm desactiva scripts de ciclo
de vida. Estos cambios corrigen los hallazgos de suministro de dependencias del
análisis remoto, sin desactivar el Quality Gate ni excluir archivos del análisis.

Las 35 pruebas Flutter incluyen 18 casos de validación administrativa, 4 de
interfaz, 3 de control de acceso, 3 del servicio de registro y 7 de regresión del
inicio de sesión, registro y arranque existentes. Se comprobó una pantalla de
320 × 568 px con texto al 200 %, rechazo de formularios vacíos, conservación de
datos tras fallo del repositorio y bloqueo de envío duplicado. Los errores de
toques fuera de pantalla se tratan como fallos de las pruebas de interfaz.

El servicio de registro cierra la sesión incluso si falla actualizar el perfil
o enviar la verificación después de crear la cuenta. El mensaje distingue ese
estado para evitar intentar registrarla de nuevo.

Las 26 pruebas de reglas emplean identidades sintéticas: acceso administrativo
válido, rechazo anónimo/regular/no verificado, rol enviado en datos sin autoridad,
listas sin límite, campos inesperados, límites de cupo, contador atómico, equipos
de otro torneo, reservas incompletas o en conflicto, cambios de autor, estados y
marcadores inválidos, cancelación y denegación de colecciones no declaradas.
Los mensajes `PERMISSION_DENIED` en casos negativos son rechazos esperados; los
asserts comprueban tanto esos rechazos como las operaciones que deben permitirse.

## Lo que no se ha comprobado

No se realizaron altas, cambios de cuentas ni pruebas de autenticación en el
proyecto real. Tampoco se publicó un sitio, se desplegaron reglas, se verificó
IAM, se probó el repositorio Flutter de extremo a extremo contra Firebase real,
se comprobó un respaldo o se ejecutó la app en Android/iOS en esta entrega.
Los dobles de prueba y el emulador no sustituyen esas verificaciones.

La compilación web emitió un aviso sobre la familia `CupertinoIcons` y terminó
correctamente. No se declara comprobada la presentación visual en todas las
plataformas a partir de la compilación o de las pruebas de widgets.

La sesión sin rol no consulta datos administrativos. El gate elimina sus rutas
cuando recibe un cambio de rol y deniega acceso si la comprobación falla. Las
reglas publicadas serán la autoridad para peticiones manipuladas y acceso
directo. Los ID tokens ya emitidos pueden conservar permisos hasta renovarse o
expirar; las escrituras del repositorio fuerzan la renovación. No se afirma
revocación instantánea.

La configuración cliente de Firebase es pública y no es una credencial Admin SDK.
La búsqueda de patrones no sustituye un escáner completo del historial de Git.
No se publican tokens ni contraseñas reales en esta evidencia.

Los pasos de activación, privacidad de la universidad pública, retención,
restauración y límites operativos están en [la guía de administración](../administrador.md).
