# Firebase y Google Sign-In

## Configuración incorporada

- Proyecto: `futschool-2ef84`.
- Paquete Android: `mx.futschool.futschool`.
- Archivo: `app/android/app/google-services.json`, proporcionado por el propietario.
- Google Services configurado en Gradle Kotlin DSL.
- Plugins Flutter: `firebase_core`, `firebase_auth` y `google_sign_in`.

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
4. Crear una cuenta de prueba de correo en la consola; no hay registro en UI.
5. Cuando se autoricen pruebas, verificar acceso, cancelación, errores,
   persistencia y cierre en un dispositivo Android con Google Play.

Cada desarrollador debe registrar sus propias huellas sin compartir la clave
privada. Producción requiere firma definitiva y huellas Google Play si aplica.

## Teléfono mediante navegador

El enlace solicitado está pausado. Requiere registrar una app web, obtener sus
opciones reales, inicializar Firebase web y autorizar el dominio de vista previa.
El JSON Android no contiene un app ID web válido. No hay túnel ni despliegue.

## Referencias

- [Flutter](https://firebase.google.com/docs/flutter/setup).
- [Google Sign-In](https://firebase.google.com/docs/auth/flutter/federated-auth).
- [Android](https://firebase.google.com/docs/android/setup).
