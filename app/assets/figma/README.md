# Recursos visuales de FutSchool

SVG exportados mediante el conector Figma del archivo proporcionado por el
propietario `m0DC5yuKG7wTfFsdnggSKJ`. Se conservan localmente, sin URLs temporales
en la aplicación. Las dimensiones de los iconos corresponden a sus nodos de origen.

| Carpeta | Pantallas de origen |
| --- | --- |
| `auth/` | `1:4`, login compartido: marca, ojo y resplandores |
| `admin/` | `43:74`, `43:10`, `43:155`, `43:225`, `43:358` |
| `captain/` | `36:860`, `27:61`, `27:155`, `55:62`, `39:5`, `21:17`, `55:185` |

Flutter utiliza layouts nativos adaptables y `flutter_svg`; no ejecuta el React
generado por el conector. El renderer SVG avisa que no soporta `filter`; el
desenfoque de los resplandores se reproduce con `ImageFiltered`, sin cambiar los
archivos originales. No se incluyen capturas de pantallas completas como fondo
de implementación. Los escudos proporcionados por usuarios son datos dinámicos
PNG/JPEG validados, separados de estos recursos estáticos.
