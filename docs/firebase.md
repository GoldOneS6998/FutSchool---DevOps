# Firebase y Google Sign-In

## Configuración incorporada

- Proyecto: `futschool-2ef84`.
- Paquete Android: `mx.futschool.futschool`.
- Archivo: `app/android/app/google-services.json`, proporcionado por el propietario.
- Google Services configurado en Gradle Kotlin DSL.
- Plugins Flutter: `firebase_core`, `firebase_auth` y `google_sign_in`.
- Web: opciones proporcionadas por el propietario en
  `app/lib/app/firebase_web_options.dart`, usadas al inicializar Firebase web.

Elegir Kotlin en la consola es compatible con Android en Flutter. Los plugins
Flutter aportan los SDK; no se añade una segunda app ni dependencias duplicadas.

Se versiona el JSON de cliente para configurar este proyecto Android. Cuentas
de servicio, certificados privados y tokens administrativos se excluyen. La
autorización y restricciones de API se administran en Firebase/Google Cloud.

## Pendientes antes de probar

1. Confirmar Correo electrónico/contraseña habilitado. La captura proporcionada
   confirma Google habilitado.
2. Agregar huellas en Configuración del proyecto → Tus apps → Android:

   - SHA-1: `29:DD:E4:4F:9C:6C:28:24:E4:8A:6E:B4:77:15:16:36:09:8E:1B:E6`
   - SHA-256: `FD:C6:60:4E:E3:68:DA:F4:FF:2E:75:C0:CA:C0:35:DA:64:CE:9B:19:15:0E:69:F9:D2:3D:45:4E:97:30:EC:A8`

3. Descargar nuevamente el JSON tras registrar huellas. El archivo recibido
   contiene cliente OAuth web, pero no cliente Android vinculado a SHA-1.
4. Confirmar que la cuenta de prueba informada aparece en la lista Usuarios;
   no hay registro de cuentas en la UI de FutSchool.
5. Cuando se autoricen pruebas, verificar acceso, cancelación, errores,
   persistencia y cierre en un dispositivo Android con Google Play.

Cada desarrollador debe registrar sus propias huellas sin compartir la clave
privada. Producción requiere firma definitiva y huellas Google Play si aplica.

## Teléfono mediante navegador

La app web está registrada y sus opciones se incorporaron el 2026-10-06.
El acceso por correo y el popup Google usan Firebase Authentication.
No se crea automáticamente una cuenta de prueba ni se agrega Analytics.

Para probar localmente, iniciar `flutter run -d web-server --web-port 5318`
y abrir `http://localhost:5318`. En Authentication → Configuración → Dominios
autorizados confirmar `localhost`; si se usa `127.0.0.1`, autorizar también ese
host. Cualquier dominio futuro del enlace para teléfono requiere autorización.
El túnel y el despliegue siguen pendientes. Las opciones cliente no prueban
que el acceso con una cuenta real funcione ni habilitan los proveedores.

## Cuenta de prueba

El propietario informó la creación de una cuenta el 2026-10-06. La captura
recibida muestra el formulario de alta todavía abierto y la lista sin usuarios;
su guardado no está confirmado por evidencia posterior.

1. En Authentication → Usuarios, confirmar que el usuario esté listado.
2. Confirmar Correo electrónico/contraseña en Método de acceso.
3. Abrir la app e introducir las credenciales de forma privada.
4. Comprobar bienvenida, persistencia y cierre antes de registrar resultados.

No se publica el correo, contraseña ni la captura que contiene credenciales.
La contraseña visible en esa captura debe reemplazarse antes de usar la cuenta.
La tabla de resultados reales continúa vacía para que el propietario la complete.

## Referencias

- [Flutter](https://firebase.google.com/docs/flutter/setup).
- [Google Sign-In](https://firebase.google.com/docs/auth/flutter/federated-auth).
- [Android](https://firebase.google.com/docs/android/setup).
