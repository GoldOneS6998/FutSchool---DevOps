# ADR 0001 · Firebase Authentication

- Fecha: 2026-10-04.
- Estado: aceptada por el propietario; acceso real pendiente de validación.

## Contexto

El cliente Flutter no tenía backend de autenticación. El propietario solicitó
correo/contraseña y Google, eligió Firebase y proporcionó configuración Android.

## Decisión

Usar Firebase Authentication detrás de `AuthService`. Google Sign-In proporciona
el ID token para obtener sesión Firebase. Separar widgets, contrato y adaptador;
presentar errores comprensibles sin registrar credenciales.

## Consecuencias

No se implementa almacenamiento propio de contraseñas. Se requiere OAuth y
certificados por plataforma. La dependencia del proveedor y límites de uso se
revisarán antes del lanzamiento. Los roles se autorizan en servicios de datos o
backend, independientemente del estado visual. No se eligió base de datos ni se
desplegó infraestructura adicional.
