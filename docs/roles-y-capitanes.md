# Login compartido, administración y capitanes

Incremento del 13 de octubre de 2026, sobre `feature/administrador` y la estructura
Flutter de `chore/limpieza`. Referencia: [diseño de FutSchool](https://www.figma.com/design/m0DC5yuKG7wTfFsdnggSKJ/?node-id=0-1).
La interfaz adapta el diseño verde a formularios desplazables y texto ampliado.

## Funciones y recorrido

El mismo login de correo/contraseña o Google sirve para ambos roles. Firebase
verifica la identidad; el claim firmado `admin: true` distingue al administrador.
El correo escrito en un formulario o un campo `role` no concede permisos. Se
exige correo verificado antes de gestionar datos. También se incorporaron
recuperación de contraseña, reenvío de verificación y actualización de sesión.

| Administrador | Capitán |
| --- | --- |
| Inicio con accesos y solicitudes pendientes reales | Inicio con equipo, próximo partido, torneo y solicitudes |
| Crear torneos y editar nombre, descripción y cupo | Buscar, filtrar y consultar torneos |
| Gestionar perfiles de capitanes y suspender/restablecer acceso a FutSchool | Editar el nombre del perfil; correo procedente de Authentication |
| Consultar equipos e integrantes privados | Crear/editar el equipo propio y su escudo |
| Aprobar/rechazar solicitudes con observaciones | Agregar, editar y eliminar jugadores del propio equipo |
| Programar partidos, validar cancha/equipos y registrar resultados | Solicitar inscripción y consultar el resultado de la revisión |
| Configurar apertura de inscripciones, avisos y privacidad | Consultar participantes, partidos, calendario y tabla derivada de resultados finales |

Las listas contienen hasta 200 documentos; el límite se señala en la interfaz.
No se presentan conteos cargados como un censo ilimitado. La tabla de posiciones
usa exclusivamente partidos finalizados: victoria 3 puntos, empate 1, derrota 0,
orden por puntos, diferencia de goles, goles a favor y nombre. Estas reglas de
presentación no asignan automáticamente un campeón ni sustituyen un reglamento.

Gestionar usuarios aquí significa gestionar perfiles y acceso a **FutSchool**.
No cambia contraseñas, deshabilita Authentication, elimina cuentas ni asigna
administradores desde el cliente. La cuenta administradora solicitada sigue
siendo `ernex9897@gmail.com`, con asignación por operador según
[administración](administrador.md).

## Persistencia y límites de confianza

Flutter utiliza los SDK de Authentication y Cloud Firestore sobre HTTPS en el
proyecto real. Firestore Security Rules validan cada lectura/escritura; no hay un
servidor REST propio ni un secreto JWT en la aplicación. Las contraseñas y tokens
son gestionados por Firebase y no se duplican en documentos de Firestore.

| Ruta | Datos y permisos |
| --- | --- |
| `captainProfiles/{uid}` | Nombre, correo de la identidad verificada, suspensión y autoría. Lectura del propietario o admin; solo admin cambia suspensión. |
| `captainTeams/{uid}` | Un equipo por capitán: nombre, descripción y escudo opcional. Propietario modifica; admin consulta. |
| `captainTeams/{uid}/players/{dorsal}` | Nombre, posición y dorsal 0–99. Privado para propietario/admin; solo propietario modifica. |
| `tournamentRegistrations/{torneo}__{uid}` | Una solicitud por equipo/torneo, estado, observación y participante aprobado. Propietario consulta; admin revisa. |
| `adminTournaments`, `adminTeams`, `adminMatches` | Competición compartida con cuentas verificadas y activas; únicamente admin escribe. Los nombres de equipos aprobados y UID de referencia del capitán quedan en el participante compartido. |
| `adminReservations` | Reservas de cancha/equipos, acceso exclusivo administrativo. |
| `appSettings/general` | Configuración general; lectura autenticada activa y escritura administrativa. |
| `publicPrivacy/notice` | Aviso y contacto de privacidad; lectura pública de ese documento fijo, sin listar perfiles ni otras configuraciones. |

Una solicitud nueva queda `pending`. La aprobación crea el participante en
`adminTeams`, incrementa el contador sin superar el cupo y cambia la solicitud a
`approved` en una sola transacción. El rechazo es `rejected`, con observación
opcional. Las decisiones son terminales en este incremento; no existe nueva
solicitud tras rechazo ni retiro de participantes aprobados. Cambiar el nombre
del equipo no reescribe el nombre histórico de una inscripción ya presentada.

Los dorsales se usan como ID: dos jugadores no pueden ocupar el mismo dorsal.
Cambiarlo crea el nuevo documento y elimina el anterior atómicamente. La pantalla
pide confirmar un borrado. Los IDs admiten letras, números, guion y guion bajo,
hasta 128 caracteres, incluido el ID compuesto de inscripción; UID personalizados
que excedan ese límite reciben un error controlado. Los UID normales generados
por Firebase y los torneos creados por la aplicación caben en ese límite.

Un escudo admite PNG/JPEG, máximo 50 KiB y 1024 × 1024 píxeles en el cliente. Se
guarda como base64 acotado en el documento, sin agregar Firebase Storage ni URLs
remotas de seguimiento. Las reglas comprueban tamaño y prefijo; Firestore no
decodifica imágenes. La interfaz verifica firma, dimensiones y decodificación
tanto al seleccionar como al leer un escudo y muestra un escudo genérico cuando
falla. El campo se excluye de índices. Para un volumen mayor debe evaluarse un
servicio de archivos con validación de contenido en servidor.

## Amenazas y controles proporcionales

| Riesgo | Control incorporado |
| --- | --- |
| Leer o cambiar otro equipo (IDOR/BOLA) | UID del token y ruta del documento verificados en servidor; consultas de inscripciones filtradas por dueño. |
| Escalar a administrador o restablecer una suspensión | Campos permitidos y diferencias de actualización exactas; claim firmado y cambios administrativos limitados. |
| Sobrepasar el cupo o aprobar dos veces | Transacción y validación `getAfter` de participante, solicitud y contador. |
| Manipular marcadores o reservas | Escritura exclusiva de admin y validación existente de estados, puntajes y reservas atómicas. |
| Datos inesperados o autores falsificados | Esquemas cerrados, rangos, UID autenticado y marcas de tiempo del servidor. |
| Imágenes malformadas o con expansión desproporcionada | Límites de bytes y dimensiones antes de decodificar; no se admiten SVG ni URLs del usuario. |
| Errores de conexión o dependencias | Mensajes controlados, reintento, conservación del formulario y bloqueo de envíos duplicados. |
| Filtrar datos por aviso público | Documento público separado con cuatro campos de aviso/contacto, sin UID de auditoría ni perfiles; configuración/aviso se guardan juntos. |

Las rutas abiertas se descartan al cambiar identidad (UID), cambiar rol, perder
la verificación o cerrar sesión. La suspensión se comprueba en Firestore en cada operación; no se afirma
que elimine automáticamente toda caché del dispositivo. La revocación del claim
administrativo conserva la limitación de los tokens ya emitidos hasta su
renovación/expiración. No se implementa SQL, cookies de sesión propias, cargas SVG
de usuarios ni un backend de comandos: sus controles específicos no aplican a
este incremento. App Check, cuotas, MFA administrativo, monitoreo y respaldo
restaurable requieren configuración institucional antes de operar.

## Privacidad de la universidad pública

El usuario confirmó universidad pública y participantes adultos. Se minimizan
datos: no se recopilan fecha de nacimiento, matrícula, documentos, datos médicos
ni teléfono. Los nombres de jugadores se mantienen privados para capitán/admin;
el capitán debe tener autorización institucional para registrarlos. El contacto
de privacidad proporcionado es `ernex9897@gmail.com`, prellenado en configuración.
Faltan nombre del responsable, texto aprobado, versión, conservación y bases del
tratamiento. No se inventó un aviso ni se presenta un texto incompleto como
cumplimiento legal. Hasta completar la evaluación, usar datos ficticios.

Se consultó el [texto oficial de la LGPDPPSO](https://www.diputados.gob.mx/LeyesBiblio/pdf/LGPDPPSO.pdf),
cuya portada indica última reforma DOF 14-11-2025. La aplicabilidad concreta de
normativa estatal, autonomía universitaria, transferencias/proveedor Firebase y
consentimiento debe revisarla la institución. No se afirma cumplimiento o
certificación. El aviso accesible desde login/registro/perfil admite responsable,
finalidades/transferencias, contacto y cambios; su contenido debe reflejar la
operación real antes de registrar datos personales reales.

Procedimiento operativo ARCO pendiente de aprobar: recibir por el contacto
institucional, verificar identidad sin pedir contraseña/token, localizar datos
por UID por un operador autorizado, responder dentro de plazos/excepciones
aplicables y documentar la atención sin duplicar información personal innecesaria.
El capitán puede rectificar su nombre/equipo e integrantes y eliminar un jugador.
La cancelación de una cuenta completa requiere un procedimiento que incluya
Authentication, documentos, inscripciones y conservación de resultados; no hay
un botón que afirme realizar esa cancelación integral.

## Activación y revisión

Las reglas publicadas el 12 de octubre pertenecen al incremento anterior, de
administración solamente. Este incremento cambia permisos y añade rutas: debe
publicarse la nueva versión probada junto con `firestore.indexes.json` después de
revisar el cambio. El claim del administrador real y la prueba con sesiones
reales siguen pendientes; una sesión de consola Firebase no equivale a ADC.

Los resultados ejecutados se registran en
[evidencia de ambos roles](evidencias/validacion-roles.md). El emulador y los dobles
de prueba no demuestran acceso correcto con cuentas reales ni preparación para
producción. La guía de [QA local](qa-local.md) permite revisar el sistema con
cuentas ficticias sin tocar `futschool-2ef84`.
