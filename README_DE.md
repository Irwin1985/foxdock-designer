# foxdock-designer

Das Plugin `designer` für FoxDock, das Plugin-System für die IDE von Visual FoxPro 9. Werkzeuge für den Formular- und den Klassen-Designer: die Auswahl untersuchen, als Code kopieren und das Steuerelement unter der Maus finden.

> Auch auf Englisch ([README.md](README.md)) und Spanisch ([README_ES.md](README_ES.md)).

## Installieren

Sie brauchen FoxDock und [FoxPack](https://irwinrodriguez.dev/products/foxpack).

- In FoxDock: **FoxDock > Plugins > Plugin-Center...**, **Verfügbar**, `designer` auswählen und **Installieren** drücken.
- Von der Konsole: `foxpack plugin add designer`.

Wenn `designer` mit Ihrem FoxDock-Installer kam, zeigt das Plugin-Center seine neuen Versionen unter **Aktualisierungen**.

## Das Paket `designer`

**FoxDock > Designer** arbeitet mit dem Formular-Designer oder Klassen-Designer, der offen ist. Er muss nicht
im Vordergrund sein: mit einem Editor darüber sieht es ihn weiter; sind mehrere Designer offen, arbeitet es
mit dem, der zuletzt in den Vordergrund kam.

| Menüpunkt oder Taste | Was er tut |
|---|---|
| **Auswahl untersuchen** (Inspect selection) | Das Ausgewählte (oder, wenn nichts ausgewählt ist, das Formular oder die Klasse): jedes Objekt mit seinem Pfad und seiner Klasse, seinen geänderten Eigenschaften (denen, die nicht auf ihrem Standardwert stehen, mit dem Ausdruck, wenn sie einen haben) und seinen Methoden mit Code, in `%LOCALAPPDATA%\FoxDock\designer\inspect.txt`, schreibgeschützt geöffnet |
| **Auswahl als Code kopieren** (Copy selection as code) | Dasselbe als Code in die Zwischenablage: ein `DEFINE CLASS ... ENDDEFINE` pro Objekt, mit seinen geänderten Eigenschaften, den Objekten, die es enthält (`ADD OBJECT ... WITH`, eine Ebene: ein tieferes bekommt einen Kommentar, weil `ADD OBJECT` nicht verschachtelt), und jeder Methode mit Code. Ein Objekt, das die Elternklasse schon mitbringt, wird nicht hinzugefügt: Es erscheint als Kommentar (`* tmrBase (Timer): inherited from ...`). Ein Formular, das so heißt wie seine Klasse (üblich bei einem Formular auf Basis einer Klasse), erscheint als `<name>_copy`, mit einem Kommentar dazu: Mit demselben Namen wäre die Klasse rekursiv. Es lässt sich kompilieren |
| **Strg+F12** | Das Steuerelement unter der Maus, mit seinem Pfad und seiner Klasse, im Hinweis oben rechts in VFP und im Log; es sagt, ob es im Designer oder in einem laufenden Formular ist |

Ohne offenen Designer sagen die Menüpunkte das im Hinweis oben rechts in VFP und tun nichts. Keiner öffnet einen
Dialog.

Bei einem Rechtsklick im Designer bekommt das Log eine Zeile mit dem Steuerelement unter der Maus
(`designer: context menu in the designer on Form.cmdOk (Commandbutton)`). Mehr nicht: das Menü von VFP
erscheint wie immer.

**Builder...** FoxDock setzt sich als Builder von VFP (`_BUILDER`), vor den, der da war (das `BUILDER.APP` von
VFP, oder Ihren), und reicht ihm jeden Aufruf weiter: **Builder...** öffnet dasselbe wie vorher, und das Log
bekommt eine Zeile mit dem, was ankam. Wenn FoxDock entladen oder die IDE geschlossen wird, ist `_BUILDER`
wieder der von vorher, außer jemand hat ihn inzwischen geändert.

Die Optionen stehen in `"options": { "designer": { ... } }`:

| Option | Standard | |
|---|---|---|
| `inspect.enabled` | `.T.` | `.F.`: weder **Auswahl untersuchen** noch **Auswahl als Code kopieren** noch eines der zehn Tools `ide_designer_*` |
| `mouse.enabled` | `.T.` | `.F.`: weder Strg+F12 noch die Zeile beim Rechtsklick |
| `builder.enabled` | `.T.` | `.F.`: FoxDock rührt `_BUILDER` nicht an |

Die Taste wird in `"keys"` geändert, wie das Tastenkürzel eines Menüpunkts:
`"keys": { "designer.InspectUnderMouse": "ALT+F12" }`, und `""` nimmt sie weg.

Was bleibt und was nicht:

- Was der Agent mit den Tools des Designers ändert, bleibt, wenn das Formular gespeichert wird, und beim
  Schließen des Designers fragt VFP, wie bei einer Änderung von Hand.
- Eine mit `WriteMethod` von VFP geschriebene Methode, ein Ausdruck mit `WriteExpression`, ein mit
  `AddObject` hinzugefügtes Steuerelement und eine Eigenschaft: jedes für sich lässt das Formular als
  geändert zurück. Ein mit `RemoveObject` allein entferntes Steuerelement nicht, und beim Schließen würde
  VFP nicht fragen: das Tool von FoxDock kümmert sich darum.
- Keine Änderung aus Code kommt in den Rückgängig-Verlauf des Designers.

Für den Agenten gibt es zehn Tools: AGENT-TOOLS_DE.md § 9.

## Über dieses Handbuch

Dieser Text ist der Abschnitt über `designer` aus dem Plugin-Handbuch von FoxDock. Die Verweise auf andere Abschnitte (§) und auf AGENT-TOOLS zeigen auf die Dokumente, die FoxDock in seinem Ordner `docs` installiert.

## Lizenz

MIT. Siehe [LICENSE](LICENSE).
