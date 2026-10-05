# Cliente Flutter

Entrada: `lib/main.dart`. `FutSchoolApp` muestra login o bienvenida según el
estado Firebase. Si no se puede inicializar, muestra acceso deshabilitado.

`features/auth/` separa widgets, contrato `AuthService` y adaptación Firebase.
Las pruebas usan un servicio de prueba, sin autenticar contra Firebase real.
El test del contador de ejemplo fue sustituido por los del login.

Android usa paquete `mx.futschool.futschool` y proyecto `futschool-2ef84`.
Consulta [Firebase](../docs/firebase.md), [arquitectura](../docs/arquitectura.md)
y [validación](../docs/evidencias/validacion-login.md).

```sh
flutter pub get
flutter run -d ID_DEL_DISPOSITIVO_ANDROID
```

Las carpetas web/iOS/escritorio se conservan como base; falta configuración
Firebase. No hay túnel ni vista web publicada.
