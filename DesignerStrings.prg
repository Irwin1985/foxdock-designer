*==================================================================
* DesignerStrings.prg: las cadenas del plugin designer, en inglés,
* español y alemán. Lo ejecuta el host al cargar el plugin (LoadPluginStrings),
* antes de su BuildMenu: una llamada toHost.AddString(<idioma>, <clave>, <texto>)
* por cadena. Las tres listas llevan las mismas claves, en el mismo orden; una que
* falte en español o alemán sale en inglés. {1} a {4}, los valores. \< marca la
* tecla de acceso. Los nombres propios (FoxDock, FoxAgent, VFP, GUID, JSON) no se
* traducen.
*==================================================================

LPARAMETERS toHost

*-- English
toHost.AddString("en", "designer.title", "Designer")
toHost.AddString("en", "designer.inspect", "\<Inspect selection")
toHost.AddString("en", "designer.inspect.message", "The changed properties and the methods with code of what is selected in the Form or Class Designer")
toHost.AddString("en", "designer.copyCode", "\<Copy selection as code")
toHost.AddString("en", "designer.copyCode.message", "What is selected in the Form or Class Designer, as DEFINE CLASS code on the clipboard")
toHost.AddString("en", "designer.noDesigner", "Designer: no Form Designer or Class Designer is open")
toHost.AddString("en", "designer.inspected", "Designer: {1} object(s) inspected in {2}")
toHost.AddString("en", "designer.copyHeld", "Designer: {1} object(s) as DEFINE CLASS: the clipboard is held by another program, nothing was copied. Try again in a moment.")
toHost.AddString("en", "designer.copied", "Designer: {1} object(s) on the clipboard as DEFINE CLASS")
toHost.AddString("en", "designer.mouse.none", "Designer: no control under the mouse ({1},{2})")
toHost.AddString("en", "designer.mouse.inDesigner", "Designer: in the designer: {1}")
toHost.AddString("en", "designer.mouse.running", "Designer: running: {1}")

*-- Español
toHost.AddString("es", "designer.title", "Diseñador")
toHost.AddString("es", "designer.inspect", "\<Inspeccionar la selección")
toHost.AddString("es", "designer.inspect.message", "Las propiedades cambiadas y los métodos con código de lo que está seleccionado en el Form o el Class Designer")
toHost.AddString("es", "designer.copyCode", "\<Copiar la selección como código")
toHost.AddString("es", "designer.copyCode.message", "Lo que está seleccionado en el Form o el Class Designer, como código DEFINE CLASS en el portapapeles")
toHost.AddString("es", "designer.noDesigner", "Diseñador: no hay ningún Form Designer ni Class Designer abierto")
toHost.AddString("es", "designer.inspected", "Diseñador: {1} objeto(s) inspeccionado(s) en {2}")
toHost.AddString("es", "designer.copyHeld", "Diseñador: {1} objeto(s) como DEFINE CLASS: otro programa tiene ocupado el portapapeles, no se ha copiado nada. Vuelve a intentarlo en un momento.")
toHost.AddString("es", "designer.copied", "Diseñador: {1} objeto(s) en el portapapeles como DEFINE CLASS")
toHost.AddString("es", "designer.mouse.none", "Diseñador: no hay ningún control bajo el ratón ({1},{2})")
toHost.AddString("es", "designer.mouse.inDesigner", "Diseñador: en el diseñador: {1}")
toHost.AddString("es", "designer.mouse.running", "Diseñador: en ejecución: {1}")

*-- Deutsch
toHost.AddString("de", "designer.title", "Designer")
toHost.AddString("de", "designer.inspect", "Auswahl \<untersuchen")
toHost.AddString("de", "designer.inspect.message", "Die geänderten Eigenschaften und die Methoden mit Code der Auswahl im Form- oder Class Designer")
toHost.AddString("de", "designer.copyCode", "Auswahl als Code \<kopieren")
toHost.AddString("de", "designer.copyCode.message", "Die Auswahl im Form- oder Class Designer als DEFINE CLASS-Code in der Zwischenablage")
toHost.AddString("de", "designer.noDesigner", "Designer: Kein Form Designer oder Class Designer ist geöffnet")
toHost.AddString("de", "designer.inspected", "Designer: {1} Objekt(e) untersucht in {2}")
toHost.AddString("de", "designer.copyHeld", "Designer: {1} Objekt(e) als DEFINE CLASS: Ein anderes Programm hält die Zwischenablage fest, es wurde nichts kopiert. Versuchen Sie es gleich noch einmal.")
toHost.AddString("de", "designer.copied", "Designer: {1} Objekt(e) als DEFINE CLASS in der Zwischenablage")
toHost.AddString("de", "designer.mouse.none", "Designer: kein Steuerelement unter der Maus ({1},{2})")
toHost.AddString("de", "designer.mouse.inDesigner", "Designer: im Designer: {1}")
toHost.AddString("de", "designer.mouse.running", "Designer: zur Laufzeit: {1}")
