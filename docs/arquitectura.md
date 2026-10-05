# Arquitectura del cliente

`main.dart` inicializa Firebase con configuración nativa Android.
`app/app.dart` escucha `AuthService.sessionChanges` y muestra login o bienvenida.
La transición depende de una sesión Firebase, no de aceptar campos localmente.

| Capa | Ruta dentro de `app/lib/` | Responsabilidad |
| --- | --- | --- |
| Presentación | `features/auth/presentation/` | Formulario, carga, validación y errores |
| Dominio | `features/auth/domain/` | Contrato del acceso y errores para la UI |
| Datos | `features/auth/data/` | Firebase Auth y Google Sign-In |
| Aplicación | `app/` | Tema y pantalla según sesión |
| Inicio | `features/home/presentation/` | Bienvenida y cierre de sesión |

## Flujo de acceso

Correo: formulario → Firebase → estado de sesión → bienvenida.
Google Android: selector de cuenta → ID token → credencial Firebase → sesión.
Google web usa popup Firebase; aún falta configuración de plataforma.

Durante el envío se bloquean ambos botones. La contraseña se oculta de forma
predeterminada y no se registran credenciales en logs. El cierre termina la
sesión Firebase; no elimina la cuenta Google del dispositivo.

## Límites

Registro de correo, recuperación de contraseña, roles, perfiles y torneos
siguen pendientes. Firebase Auth identifica al usuario; los permisos del
futuro backend o servicio de datos requieren autorización independiente.
No se otorgan permisos por ocultar botones en la interfaz.

Android es la plataforma configurada. Web, esquemas OAuth iOS y escritorio
están pendientes. Release aún utiliza firma de desarrollo; producción requiere
un certificado definitivo. Las carpetas reservadas no implican funciones listas.
