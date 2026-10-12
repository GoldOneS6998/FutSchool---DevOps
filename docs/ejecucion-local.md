# Ejecutar FutSchool localmente

Para revisar el incremento de administración, utiliza `feature/administrador`
o el checkout local `FutSchool-admin`. Iniciar la web muestra el login; el panel
requiere Firestore habilitado, reglas publicadas y el claim de la cuenta
administradora asignado según [la guía](administrador.md). No hay un modo público
que omita estos permisos.

Mientras la propuesta siga en revisión, la rama está publicada en el fork
`GoldOneS6998/FutSchool---DevOps`. Desde un clon sin cambios pendientes:

```sh
git fetch https://github.com/GoldOneS6998/FutSchool---DevOps.git feature/administrador
git switch --detach FETCH_HEAD
```

Estos comandos permiten revisar la versión propuesta antes de que se integre en
`HecCol/FutSchool---DevOps`. El cambio de rama no publica ni configura Firebase.

## Flutter instalado en PATH

```sh
cd app
flutter pub get
flutter run -d web-server --web-port 5318
```

Abrir `http://localhost:5318` en el navegador del mismo equipo. Usar web-server
evita depender del arranque automático de Edge en modo de depuración.

## Equipo Windows de desarrollo actual

Desde la carpeta `FutSchool---DevOps/app`, en PowerShell:

```powershell
$taskFlutter = (Resolve-Path "../../tmp/framework-tools/flutter-3.47.5/bin/flutter.bat").Path
& $taskFlutter pub get
& $taskFlutter run -d web-server --web-port 5318
```

La ruta al SDK es local a este workspace; otros equipos deben instalar Flutter
y usar su propia ruta. Mantener la terminal abierta; `q` detiene el servidor.
Si el puerto está ocupado, detener la instancia anterior o elegir otro puerto.

Si Windows informa que los plugins requieren symlinks, habilitar Modo de
desarrollador desde Configuración. Para abrir esa página:

```powershell
Start-Process "ms-settings:developers"
```

## Firebase y teléfono

La app utiliza opciones web reales; confirmar `localhost` en Dominios
autorizados de Firebase para el popup Google. Ver [Firebase](firebase.md).
El enlace localhost solo funciona en el equipo que sirve la app; un teléfono
requiere acceso de red o un enlace externo y su dominio autorizado.

No hay enlace externo publicado ni cuenta de prueba confirmada por esta entrega.
La configuración no crea usuarios automáticamente. La autenticación real y
sus resultados se registran por separado en la plantilla de validación.
