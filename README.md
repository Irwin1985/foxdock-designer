# foxdock-designer

The `designer` plugin of FoxDock, the plugin system for the Visual FoxPro 9 IDE. Tools for the Form Designer and the Class Designer: inspect the selection, copy it as code, and find the control under the mouse.

> Also in Spanish ([README_ES.md](README_ES.md)) and German ([README_DE.md](README_DE.md)).

## Install

You need FoxDock and [FoxPack](https://irwinrodriguez.dev/products/foxpack).

- In FoxDock: **FoxDock > Plugins > Plugin center...**, **Available**, choose `designer` and press **Install**.
- From a console: `foxpack plugin add designer`.

If `designer` came with your FoxDock installer, the plugin center shows its new versions in **Updates**.

## The `designer` package

**FoxDock > Designer** works on the Form Designer or Class Designer that is open. It does not have to be
in front: with an editor on top, it still sees it; with several designers open, it works on the last one
that came to the front.

| Bar or key | What it does |
|---|---|
| **Inspect selection** | What is selected (or, with nothing selected, the form or the class): each object with its path and its class, its changed properties (the ones not at their default value, with the expression when they have one) and its methods with code, in `%LOCALAPPDATA%\FoxDock\designer\inspect.txt`, opened read-only |
| **Copy selection as code** | The same as code, on the clipboard: a `DEFINE CLASS ... ENDDEFINE` per object, with its changed properties, the objects it contains (`ADD OBJECT ... WITH`, one level: a deeper one gets a comment, because `ADD OBJECT` does not nest) and every method with code. An object the parent class already brings is not added: it comes out as a comment (`* tmrBase (Timer): inherited from ...`). A form named like its class (the usual thing in one based on a class) comes out as `<name>_copy`, with a comment that says so: with the same name the class would be recursive. It compiles |
| **Ctrl+F12** | The control under the mouse, with its path and its class, in the notice at the top right of VFP and the log; it says whether it is in the designer or in a running form |

Without a designer open, the bars say so in the notice at the top right of VFP and do nothing. None of them opens a dialog.

On a right click in the designer, the log gets a line with the control under the mouse
(`designer: context menu in the designer on Form.cmdOk (Commandbutton)`). Nothing more: VFP's menu comes out
as always.

**Builder...** FoxDock puts itself as VFP's builder (`_BUILDER`), in front of the one there was (VFP's
`BUILDER.APP`, or yours), and passes every call on to it: **Builder...** opens the same as before, and the log
gets a line with what arrived. When FoxDock unloads or the IDE closes, `_BUILDER` goes back to the one there
was, unless someone changed it in between.

The options go in `"options": { "designer": { ... } }`:

| Option | Default | |
|---|---|---|
| `inspect.enabled` | `.T.` | `.F.`: no **Inspect selection**, no **Copy selection as code** and none of the ten `ide_designer_*` tools |
| `mouse.enabled` | `.T.` | `.F.`: no Ctrl+F12 and no line on a right click |
| `builder.enabled` | `.T.` | `.F.`: FoxDock does not touch `_BUILDER` |

The key is changed in `"keys"`, like the shortcut of a bar: `"keys": { "designer.InspectUnderMouse": "ALT+F12" }`,
and `""` takes it away.

What persists and what does not:

- What the agent changes with the designer tools persists when the form is saved, and closing the designer
  asks, as with a change made by hand.
- A method written with VFP's `WriteMethod`, an expression with `WriteExpression`, a control added with
  `AddObject` and a property: each one alone leaves the form changed. A control removed with `RemoveObject`
  alone does not, and closing would not ask: the FoxDock tool takes care of it.
- No change made from code goes into the designer's undo.

For the agent there are ten tools: AGENT-TOOLS_EN.md § 9.

## About this manual

This text is the section about `designer` of the FoxDock plugin manual. The references to other sections (§) and to AGENT-TOOLS point to the documents FoxDock installs in its `docs` folder.

## License

MIT. See [LICENSE](LICENSE).
