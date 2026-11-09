# foxdock-designer

El plugin `designer` de FoxDock, el sistema de plugins para el IDE de Visual FoxPro 9. Herramientas para el Diseñador de formularios y el de clases: inspeccionar la selección, copiarla como código y saber qué control hay bajo el ratón.

> También en inglés ([README.md](README.md)) y en alemán ([README_DE.md](README_DE.md)).

## Instalar

Hacen falta FoxDock y [FoxPack](https://irwinrodriguez.dev/products/foxpack).

- En FoxDock: **FoxDock > Plugins > Centro de plugins...**, **Disponibles**, elige `designer` y pulsa **Instalar**.
- Desde una consola: `foxpack plugin add designer`.

Si `designer` vino con tu instalador de FoxDock, el centro de plugins enseña sus versiones nuevas en **Actualizaciones**.

## El paquete `designer`

**FoxDock > Diseñador** (FoxDock > Designer) trabaja sobre el Form Designer o el Class Designer que esté abierto. No hace falta
que esté delante: con un editor encima lo sigue viendo; con varios diseñadores abiertos, trabaja sobre el
último que se puso delante.

| Barra o tecla | Qué hace |
|---|---|
| **Inspeccionar la selección** (Inspect selection) | Lo seleccionado (o, sin nada seleccionado, el formulario o la clase): cada objeto con su ruta y su clase, sus propiedades cambiadas (las que no tienen su valor por defecto, con la expresión cuando la tienen) y sus métodos con código, en `%LOCALAPPDATA%\FoxDock\designer\inspect.txt`, abierto de solo lectura |
| **Copiar la selección como código** (Copy selection as code) | Lo mismo como código, al portapapeles: un `DEFINE CLASS ... ENDDEFINE` por objeto, con sus propiedades cambiadas, los objetos que contiene (`ADD OBJECT ... WITH`, un nivel: uno más hondo lleva un comentario, porque `ADD OBJECT` no anida) y cada método con código. Un objeto que ya trae la clase padre no se añade: sale como comentario (`* tmrBase (Timer): inherited from ...`). Un formulario que se llama como su clase (lo normal en uno basado en una clase) sale como `<nombre>_copy`, con un comentario que lo dice: con el mismo nombre la clase sería recursiva. Compila |
| **Ctrl+F12** | El control que hay bajo el ratón, con su ruta y su clase, en el aviso de arriba a la derecha de VFP y en el log; dice si está en el diseñador o en un formulario en marcha |

Sin un diseñador abierto, las barras lo dicen en el aviso de arriba a la derecha de VFP y no hacen nada. Ninguna abre un
diálogo.

Con un clic derecho en el diseñador, el log gana una línea con el control que había debajo
(`designer: context menu in the designer on Form.cmdOk (Commandbutton)`). Nada más: el menú de VFP sale
como siempre.

**Builder...** FoxDock se pone como builder de VFP (`_BUILDER`), delante del que hubiera (el `BUILDER.APP` de
VFP, o el tuyo), y le pasa todas las llamadas: **Builder...** abre lo mismo que antes, y el log gana una línea
con lo que llegó. Cuando FoxDock se desmonta o se cierra el IDE, `_BUILDER` vuelve a ser el de antes, salvo
que alguien lo haya cambiado entretanto.

Las opciones van en `"options": { "designer": { ... } }`:

| Opción | Por defecto | |
|---|---|---|
| `inspect.enabled` | `.T.` | `.F.`: ni **Inspeccionar la selección**, ni **Copiar la selección como código**, ni ninguna de las diez tools `ide_designer_*` |
| `mouse.enabled` | `.T.` | `.F.`: ni Ctrl+F12 ni la línea del clic derecho |
| `builder.enabled` | `.T.` | `.F.`: FoxDock no toca `_BUILDER` |

La tecla se cambia en `"keys"`, como el atajo de una barra: `"keys": { "designer.InspectUnderMouse": "ALT+F12" }`,
y `""` la quita.

Qué persiste y qué no:

- Lo que el agente cambia con las tools del diseñador persiste al guardar el formulario, y al cerrar el
  diseñador VFP pregunta, como con un cambio hecho a mano.
- Un método escrito con `WriteMethod` de VFP, una expresión con `WriteExpression`, un control añadido con
  `AddObject` y una propiedad: cada uno, solo, deja el formulario como cambiado. Un control quitado con
  `RemoveObject`, solo, no, y al cerrar VFP no preguntaría: la tool de FoxDock se ocupa.
- Ningún cambio hecho por código entra en el deshacer del diseñador.

Para el agente hay diez tools: AGENT-TOOLS_ES.md § 9.

## Sobre este manual

Este texto es la sección sobre `designer` del manual de plugins de FoxDock. Las referencias a otras secciones (§) y a AGENT-TOOLS apuntan a los documentos que FoxDock instala en su carpeta `docs`.

## Licencia

MIT. Está en [LICENSE](LICENSE).
