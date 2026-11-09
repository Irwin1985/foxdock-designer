*==================================================================
* DesignerTools.prg: las tools del paquete «designer» para el agente.
*
* Heredan de IdeTool (plugins\foxagent\IdeTools.prg): el host, J(), Done(),
* los parámetros y el rol que pide cada una.
*
*   ide_designer_list              lo que hay en el diseñador (lee)
*   ide_designer_get_control       las propiedades de un control (lee)
*   ide_designer_set_property      una propiedad (actúa: rol 10)
*   ide_designer_selection         lo seleccionado, el fichero y la ventana de código (lee)
*   ide_designer_read_method       el código de un método (lee)
*   ide_designer_write_method      escribe un método (actúa: rol 10)
*   ide_designer_add_control       añade un control (actúa: rol 10)
*   ide_designer_remove_control    quita un control (actúa: rol 10)
*   ide_designer_dataenvironment   cursores y relaciones del entorno de datos (lee)
*   ide_designer_save              guarda el diseñador por su menú; con otra ventana delante, en diferido (actúa: rol 10)
*
* Todas son del módulo inspect: apagado, no existe ninguna. Lo que usan del
* diseñador: ASELOBJ ve el diseñador aunque no
* esté delante; RemoveObject no deja el formulario como cambiado y por eso
* remove_control reasigna una propiedad; AddObject pone el nombre en
* mayúsculas y add_control lo deja como lo pidió el agente; el código que
* manda el agente llega en CP1252 y se escribe tal cual.
*
* Superficie pública en inglés. Fichero en CP1252.
*==================================================================

#DEFINE CRLF CHR(13) + CHR(10)
#DEFINE DS_NO_HOST "FoxDock is not mounted (after CLEAR ALL it sleeps until a FoxDock menu bar or key is pressed)"
#DEFINE DS_NAME_HELP "The control's name or path, as ide_designer_list gives it; the form's (or class's) name, or empty, for the form itself."

*------------------------------------------------------------------
* La base: el diseñador por el DesignerScope del paquete.
*------------------------------------------------------------------
DEFINE CLASS IdeDesignerTool AS IdeTool
	oScope = .NULL.

	PROCEDURE Scope
		LOCAL loP
		IF ISNULL(This.oScope) AND !ISNULL(THIS.Host())
			loP = _screen.oFoxDock.PluginById("designer")
			IF !ISNULL(loP)
				This.oScope = loP.oScope
			ENDIF
		ENDIF
		RETURN This.oScope
	ENDPROC

	*-- Por qué no hay nada que hacer: sin host, sin paquete o sin diseñador.
	PROCEDURE Unready
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(DS_NO_HOST)
		ENDIF
		IF ISNULL(This.Scope())
			RETURN THIS.Err("The designer package is not loaded in this IDE (FoxDock > Plugins).")
		ENDIF
		RETURN THIS.NoDesigner()
	ENDPROC

	PROCEDURE Root
		LOCAL loS
		loS = This.Scope()
		RETURN IIF(ISNULL(loS), .NULL., loS.Root())
	ENDPROC

	*-- lastDeferredSave: lo que hizo el último guardado diferido, o
	*-- null si no ha habido ninguno; hasta que otro lo sustituye.
	PROCEDURE PutLastDeferred
		LPARAMETERS toJ, toD
		LOCAL loP, loL, loO
		loP = _screen.oFoxDock.PluginById("designer")
		loL = IIF(ISNULL(loP), .NULL., loP.oLastDeferred)
		IF ISNULL(loL)
			toJ.Put(toD, "lastDeferredSave", .NULL.)
			RETURN
		ENDIF
		loO = toJ.MakeObject()
		toJ.Put(loO, "file", LOWER(loL.cFile))
		toJ.Put(loO, "written", loL.lWritten)
		toJ.Put(loO, "attempts", loL.nAttempts)
		toJ.Put(loO, "when", loL.cWhen)
		toJ.Put(loO, "result", loL.cResult)
		toJ.Put(toD, "lastDeferredSave", loO)
	ENDPROC

	PROCEDURE NoDesigner
		RETURN THIS.Err("No Form Designer or Class Designer is open in the IDE. Open a form with ide_open_file and its " + ;
			".scx. It does not have to be the window in front; with several open, the tools work on the last one activated.")
	ENDPROC

	PROCEDURE Find
		LPARAMETERS toRoot, tcName
		LOCAL loS
		loS = This.Scope()
		RETURN loS.Find(toRoot, tcName)
	ENDPROC

	PROCEDURE PathOf
		LPARAMETERS toO
		LOCAL loS
		loS = This.Scope()
		RETURN loS.PathOf(toO)
	ENDPROC

	PROCEDURE Prop
		LPARAMETERS toO, tcProp
		LOCAL loS
		loS = This.Scope()
		RETURN loS.Prop(toO, tcProp)
	ENDPROC

	PROCEDURE NoControl
		LPARAMETERS toRoot, tcName
		RETURN THIS.Err("There is no control '" + tcName + "' in " + toRoot.Name + ". List them with ide_designer_list.")
	ENDPROC

	*-- El diseñador y su fichero, para las respuestas.
	PROCEDURE PutSource
		LPARAMETERS toD
		LOCAL loJ, loS
		LOCAL ARRAY laS[1]
		loJ = THIS.J()
		loS = This.Scope()
		IF loS.Source(@laS) >= 2
			loJ.Put(toD, "file", LOWER(TRANSFORM(laS[2])))
		ENDIF
		loJ.Put(toD, "designer", loS.Kind())
	ENDPROC
ENDDEFINE


DEFINE CLASS IdeDesignerListTool AS IdeDesignerTool
	ToolName = "ide_designer_list"
	ToolDescription = "What is being designed in the Form Designer or Class Designer of the Visual FoxPro IDE: the " + ;
		"form (or class) and all its controls, each with name, path, class, baseClass, parent, top, left, width, height " + ;
		"and caption, and which are selected; and lastDeferredSave, what the last deferred ide_designer_save did (null " + ;
		"if there was none). Reads only. The designer does not have to be in front; with several open, " + ;
		"it is the last one activated."

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loD, loList, loSel, lnN, lnI, loS
		LOCAL ARRAY laS[1]
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "name", loRoot.Name)
		loJ.Put(loD, "class", loRoot.Class)
		loJ.Put(loD, "baseClass", loRoot.BaseClass)
		loJ.Put(loD, "caption", THIS.Prop(loRoot, "Caption"))
		loJ.Put(loD, "width", THIS.Prop(loRoot, "Width"))
		loJ.Put(loD, "height", THIS.Prop(loRoot, "Height"))
		loList = loJ.MakeArray()
		THIS.Walk(loRoot, loList)
		loJ.Put(loD, "controlCount", loList.Count)
		loJ.Put(loD, "controls", loList)
		loSel = loJ.MakeArray()
		loS = THIS.Scope()
		lnN = loS.Selected(@laS)
		FOR lnI = 1 TO lnN
			IF VARTYPE(laS[lnI]) == "O"
				loSel.Add(THIS.PathOf(laS[lnI]))
			ENDIF
		ENDFOR
		loJ.Put(loD, "selected", loSel)
		THIS.PutLastDeferred(loJ, loD)
		RETURN THIS.Done(loD)
	ENDFUNC

	PROCEDURE Walk
		LPARAMETERS toC, toList
		LOCAL loK, loJ, loE
		IF !PEMSTATUS(toC, "Objects", 5)
			RETURN
		ENDIF
		loJ = THIS.J()
		FOR EACH loK IN toC.Objects FOXOBJECT
			loE = loJ.MakeObject()
			loJ.Put(loE, "name", loK.Name)
			loJ.Put(loE, "path", THIS.PathOf(loK))
			loJ.Put(loE, "class", loK.Class)
			loJ.Put(loE, "baseClass", loK.BaseClass)
			loJ.Put(loE, "parent", toC.Name)
			loJ.Put(loE, "top", THIS.Prop(loK, "Top"))
			loJ.Put(loE, "left", THIS.Prop(loK, "Left"))
			loJ.Put(loE, "width", THIS.Prop(loK, "Width"))
			loJ.Put(loE, "height", THIS.Prop(loK, "Height"))
			loJ.Put(loE, "caption", THIS.Prop(loK, "Caption"))
			toList.Add(loE)
			THIS.Walk(loK, toList)
		ENDFOR
	ENDPROC
ENDDEFINE


DEFINE CLASS IdeDesignerGetControlTool AS IdeDesignerTool
	ToolName = "ide_designer_get_control"
	ToolDescription = "The properties of one control (or of the form itself) in the Form Designer or Class Designer " + ;
		"of the Visual FoxPro IDE, found by its name ('cmdOk') or its path ('Form1.cmdOk'): the ones not at their default " + ;
		"value, or all of them with all=true. Reads only."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", DS_NAME_HELP, .T.)
		THIS.AddParam("all", "boolean", "true: every property, not only the changed ones.", .F.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loO, loD, loP, lnN, lnI, llAll, lcName, luV
		LOCAL ARRAY laM[1]
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lcName = THIS.PText(toContext, "name")
		loO = THIS.Find(loRoot, lcName)
		IF ISNULL(loO)
			RETURN THIS.NoControl(loRoot, lcName)
		ENDIF
		loJ = THIS.J()
		llAll = THIS.PBool(toContext, "all")
		loP = loJ.MakeObject()
		lnN = AMEMBERS(laM, loO, 1)
		FOR lnI = 1 TO lnN
			IF !(UPPER(laM[lnI, 2]) == "PROPERTY")
				LOOP
			ENDIF
			IF !llAll AND !PEMSTATUS(loO, laM[lnI, 1], 0)
				LOOP
			ENDIF
			luV = THIS.Prop(loO, laM[lnI, 1])
			loJ.Put(loP, PROPER(laM[lnI, 1]), luV)
		ENDFOR
		loD = loJ.MakeObject()
		loJ.Put(loD, "name", loO.Name)
		loJ.Put(loD, "path", THIS.PathOf(loO))
		loJ.Put(loD, "class", loO.Class)
		loJ.Put(loD, "baseClass", loO.BaseClass)
		loJ.Put(loD, "onlyChanged", !llAll)
		loJ.Put(loD, "properties", loP)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerSetPropertyTool AS IdeDesignerTool
	ToolName = "ide_designer_set_property"
	lActsOnIde = .T.
	ToolDescription = "Sets one property of a control (or of the form) in the Form Designer or Class Designer of the " + ;
		"Visual FoxPro IDE, on the live object, as the Properties window would: 'value' is converted to the property's " + ;
		"type (number, true/false, text). Says the previous value. The designer counts it as a change, like one made by " + ;
		"hand: it is saved when the form is saved, and closing the designer asks. FoxDock cannot put it into the " + ;
		"designer's undo: to undo, set 'previous' back."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", DS_NAME_HELP, .T.)
		THIS.AddParam("property", "string", "The property, for example Caption.", .T.)
		THIS.AddParam("value", "string", "The new value, as text: 'Save', '120', 'true'.", .T.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loO, loD, lcName, lcProp, lcVal, luOld, luNew, lcCmd, loErr, lcFail
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(DS_NO_HOST)
		ENDIF
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lcName = THIS.PText(toContext, "name")
		lcProp = THIS.PText(toContext, "property")
		lcVal = GETPEM(toContext.Parameters, "value")
		lcVal = IIF(VARTYPE(lcVal) == "C", lcVal, TRANSFORM(lcVal))
		loO = THIS.Find(loRoot, lcName)
		IF ISNULL(loO)
			RETURN THIS.NoControl(loRoot, lcName)
		ENDIF
		IF !PEMSTATUS(loO, lcProp, 5) OR !(UPPER(PEMSTATUS(loO, lcProp, 3)) == "PROPERTY")
			RETURN THIS.Err(loO.Name + " has no property '" + lcProp + "'.")
		ENDIF
		IF PEMSTATUS(loO, lcProp, 1)
			RETURN THIS.Err(lcProp + " is read-only on " + loO.Name + ".")
		ENDIF
		luOld = GETPEM(loO, lcProp)
		DO CASE
			CASE VARTYPE(luOld) == "N"
				luNew = VAL(lcVal)
			CASE VARTYPE(luOld) == "L"
				luNew = INLIST(UPPER(ALLTRIM(lcVal)), "TRUE", ".T.", "T", "1", "YES", "Y")
			OTHERWISE
				luNew = lcVal
		ENDCASE
		lcFail = ""
		TRY
			lcCmd = "loO." + lcProp + " = luNew"
			&lcCmd
		CATCH TO loErr
			lcFail = TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
		ENDTRY
		IF !EMPTY(lcFail)
			RETURN THIS.Err("Could not set " + loO.Name + "." + lcProp + ": " + lcFail)
		ENDIF
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "name", loO.Name)
		loJ.Put(loD, "path", THIS.PathOf(loO))
		loJ.Put(loD, "property", lcProp)
		loJ.Put(loD, "previous", IIF(VARTYPE(luOld) == "O", .NULL., luOld))
		loJ.Put(loD, "value", GETPEM(loO, lcProp))
		loJ.Put(loD, "saved", .F.)
		_screen.oFoxDock.AgentDid("set " + THIS.PathOf(loO) + "." + lcProp + " to " + LEFT(TRANSFORM(GETPEM(loO, lcProp)), 60))
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerSelectionTool AS IdeDesignerTool
	ToolName = "ide_designer_selection"
	ToolDescription = "What is selected now in the Form Designer or Class Designer of the Visual FoxPro IDE: each " + ;
		"selected object with name, path, class and baseClass, and the container they are in. Also the designer " + ;
		"('form' or 'class'), its file (.scx or .vcx) and #INCLUDE file, the window in front, and, when the window in " + ;
		"front is a method's code window, which object and method it is ('codeWindow'; VFP's ASELOBJ gives the form " + ;
		"there, not the control, so this comes from the window's title). Nothing selected: an empty 'selected'. Reads only."

	FUNCTION Run(toContext)
		LOCAL loJ, loS, loRoot, loD, loSel, loE, lnN, lnI, lcTop, loC, lnDot
		LOCAL ARRAY laSel[1], laS[1], laC[1]
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		loS = THIS.Scope()
		loJ = THIS.J()
		loD = loJ.MakeObject()
		THIS.PutSource(loD)
		loJ.Put(loD, "include", "")
		IF loS.Source(@laS) >= 3
			loJ.Put(loD, "include", LOWER(TRANSFORM(laS[3])))
		ENDIF
		loJ.Put(loD, "root", loRoot.Name)
		loJ.Put(loD, "container", "")
		IF ASELOBJ(laC, 1) > 0 AND VARTYPE(laC[1]) == "O"
			loJ.Put(loD, "container", THIS.PathOf(laC[1]))
		ENDIF
		loSel = loJ.MakeArray()
		lnN = loS.Selected(@laSel)
		FOR lnI = 1 TO lnN
			IF VARTYPE(laSel[lnI]) == "O"
				loE = loJ.MakeObject()
				loJ.Put(loE, "name", laSel[lnI].Name)
				loJ.Put(loE, "path", THIS.PathOf(laSel[lnI]))
				loJ.Put(loE, "class", laSel[lnI].Class)
				loJ.Put(loE, "baseClass", laSel[lnI].BaseClass)
				loSel.Add(loE)
			ENDIF
		ENDFOR
		loJ.Put(loD, "count", loSel.Count)
		loJ.Put(loD, "selected", loSel)
		lcTop = WONTOP()
		loJ.Put(loD, "window", lcTop)
		loC = .NULL.
		lnDot = RAT(".", lcTop)
		IF lnDot > 1 AND !(" " $ ALLTRIM(lcTop)) AND !INLIST(UPPER(JUSTEXT(lcTop)), "PRG", "SCX", "VCX", "TXT", "H", "MPR", "QPR")
			loC = loJ.MakeObject()
			loJ.Put(loC, "object", LEFT(lcTop, lnDot - 1))
			loJ.Put(loC, "method", SUBSTR(lcTop, lnDot + 1))
		ENDIF
		loJ.Put(loD, "codeWindow", loC)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerReadMethodTool AS IdeDesignerTool
	ToolName = "ide_designer_read_method"
	ToolDescription = "The code of one method or event of a control (or of the form) in the Form Designer or Class " + ;
		"Designer of the Visual FoxPro IDE, as it is in the designer now (saved or not). Empty code: the method exists " + ;
		"and has no code at this level. A method the object does not have: the error says so and lists the ones " + ;
		"with code and all the others. Reads only."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", DS_NAME_HELP, .T.)
		THIS.AddParam("method", "string", "The method or event, for example Click or Init.", .T.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loO, loD, lcName, lcMethod, lcCode, lnN, lnI, lcWith, loS
		LOCAL ARRAY laM[1]
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lcName = THIS.PText(toContext, "name")
		lcMethod = THIS.PText(toContext, "method")
		loO = THIS.Find(loRoot, lcName)
		IF ISNULL(loO)
			RETURN THIS.NoControl(loRoot, lcName)
		ENDIF
		IF EMPTY(lcMethod) OR !PEMSTATUS(loO, lcMethod, 5) OR !INLIST(UPPER(PEMSTATUS(loO, lcMethod, 3)), "METHOD", "EVENT")
			loS = THIS.Scope()
			lnN = loS.Methods(loO, @laM)
			lcWith = ""
			FOR lnI = 1 TO lnN
				lcWith = lcWith + IIF(lnI = 1, "", ", ") + laM[lnI, 1]
			ENDFOR
			RETURN THIS.Err(loO.Name + " has no method or event '" + lcMethod + "'. With code: " + ;
				IIF(EMPTY(lcWith), "none", lcWith) + ". All of them: " + loS.MethodNames(loO) + ".")
		ENDIF
		lcCode = loO.ReadMethod(lcMethod)
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "name", loO.Name)
		loJ.Put(loD, "path", THIS.PathOf(loO))
		loJ.Put(loD, "method", PROPER(lcMethod))
		loJ.Put(loD, "hasCode", !EMPTY(lcCode))
		loJ.Put(loD, "code", lcCode)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerWriteMethodTool AS IdeDesignerTool
	ToolName = "ide_designer_write_method"
	lActsOnIde = .T.
	ToolDescription = "Writes the code of one method or event of a control (or of the form) in the Form Designer or " + ;
		"Class Designer of the Visual FoxPro IDE (VFP's WriteMethod), replacing what it had; with create=true a method " + ;
		"the object does not have is created. Returns the previous code. Line breaks may be \n or \r\n. The designer " + ;
		"counts it as a change: it is saved with the form (ide_designer_save, or by hand), and closing the designer asks. " + ;
		"Accents and other characters arrive in the IDE's code page (Windows-1252) and are written as they arrive."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", DS_NAME_HELP, .T.)
		THIS.AddParam("method", "string", "The method or event, for example Click.", .T.)
		THIS.AddParam("code", "string", "The whole code of the method, without PROCEDURE and ENDPROC.", .T.)
		THIS.AddParam("create", "boolean", "true: create the method if the object does not have it.", .F.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loO, loD, lcName, lcMethod, lcCode, lcOld, llCreate, llNew, loErr, lcFail, loS
		LOCAL ARRAY laL[1]
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(DS_NO_HOST)
		ENDIF
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lcName = THIS.PText(toContext, "name")
		lcMethod = THIS.PText(toContext, "method")
		llCreate = THIS.PBool(toContext, "create")
		lcCode = GETPEM(toContext.Parameters, "code")
		lcCode = THIS.VfpText(IIF(VARTYPE(lcCode) == "C", lcCode, ""))
		loO = THIS.Find(loRoot, lcName)
		IF ISNULL(loO)
			RETURN THIS.NoControl(loRoot, lcName)
		ENDIF
		IF EMPTY(lcMethod) OR !(lcMethod == CHRTRAN(lcMethod, " .()[]", ""))
			RETURN THIS.Err("'" + lcMethod + "' is not a method name.")
		ENDIF
		llNew = !PEMSTATUS(loO, lcMethod, 5)
		IF !llNew AND !INLIST(UPPER(PEMSTATUS(loO, lcMethod, 3)), "METHOD", "EVENT")
			RETURN THIS.Err(loO.Name + "." + lcMethod + " is a property, not a method.")
		ENDIF
		IF llNew AND !llCreate
			loS = THIS.Scope()
			RETURN THIS.Err(loO.Name + " has no method '" + lcMethod + "'. Send create=true to create it. Its methods: " + ;
				loS.MethodNames(loO) + ".")
		ENDIF
		lcOld = IIF(llNew, "", loO.ReadMethod(lcMethod))
		lcFail = ""
		TRY
			IF llNew
				loO.WriteMethod(lcMethod, lcCode, .T.)
			ELSE
				loO.WriteMethod(lcMethod, lcCode)
			ENDIF
		CATCH TO loErr
			lcFail = TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
		ENDTRY
		IF !EMPTY(lcFail)
			RETURN THIS.Err("Could not write " + loO.Name + "." + lcMethod + ": " + lcFail)
		ENDIF
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "name", loO.Name)
		loJ.Put(loD, "path", THIS.PathOf(loO))
		loJ.Put(loD, "method", lcMethod)
		loJ.Put(loD, "created", llNew)
		loJ.Put(loD, "previous", lcOld)
		loJ.Put(loD, "lines", ALINES(laL, lcCode))
		loJ.Put(loD, "saved", .F.)
		_screen.oFoxDock.AgentDid(IIF(llNew, "created ", "wrote ") + THIS.PathOf(loO) + "." + lcMethod)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerAddControlTool AS IdeDesignerTool
	ToolName = "ide_designer_add_control"
	lActsOnIde = .T.
	ToolDescription = "Adds a control to the form (or to a container in it) in the Form Designer or Class Designer of " + ;
		"the Visual FoxPro IDE, as dropping it from the toolbox would: a base class ('TextBox', 'CommandButton') or a " + ;
		"class of a class library ('classLibrary': the .vcx). It gets the name you give, with your capitals, and the " + ;
		"top, left, width and height you give (the class's own where left out). The designer counts it as a change: " + ;
		"saved with the form, and closing the designer asks. Returns its path."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", "The new control's name, for example txtCustomer.", .T.)
		THIS.AddParam("class", "string", "Its class: a base class (TextBox) or a class of classLibrary.", .T.)
		THIS.AddParam("classLibrary", "string", "The .vcx of the class; empty for a base class.", .F.)
		THIS.AddParam("parent", "string", "The container it goes in, by name or path; empty for the form itself.", .F.)
		THIS.AddParam("top", "number", "Top, in pixels.", .F.)
		THIS.AddParam("left", "number", "Left, in pixels.", .F.)
		THIS.AddParam("width", "number", "Width, in pixels.", .F.)
		THIS.AddParam("height", "number", "Height, in pixels.", .F.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loParent, loO, loD, lcName, lcClass, lcLib, lcParent, loErr, lcFail, lcProp, lnV
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(DS_NO_HOST)
		ENDIF
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lcName = THIS.PText(toContext, "name")
		lcClass = THIS.PText(toContext, "class")
		lcLib = THIS.PText(toContext, "classLibrary")
		lcParent = THIS.PText(toContext, "parent")
		loParent = THIS.Find(loRoot, lcParent)
		IF ISNULL(loParent)
			RETURN THIS.NoControl(loRoot, lcParent)
		ENDIF
		IF EMPTY(lcName) OR !(lcName == CHRTRAN(lcName, " .()[]", ""))
			RETURN THIS.Err("'" + lcName + "' is not a control name.")
		ENDIF
		IF PEMSTATUS(loParent, lcName, 5)
			RETURN THIS.Err(loParent.Name + " already has a member '" + lcName + "'.")
		ENDIF
		lcFail = ""
		TRY
			IF EMPTY(lcLib)
				loParent.AddObject(lcName, lcClass)
			ELSE
				loParent.NewObject(lcName, lcClass, lcLib)
			ENDIF
			loO = GETPEM(loParent, lcName)
			*-- AddObject deja el nombre en mayúsculas: se le devuelve el suyo.
			loO.Name = lcName
		CATCH TO loErr
			lcFail = TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
		ENDTRY
		IF !EMPTY(lcFail)
			RETURN THIS.Err("Could not add " + lcName + " (" + lcClass + IIF(EMPTY(lcLib), "", " of " + lcLib) + ") to " + ;
				loParent.Name + ": " + lcFail)
		ENDIF
		THIS.Place(loO, toContext, "top", "Top")
		THIS.Place(loO, toContext, "left", "Left")
		THIS.Place(loO, toContext, "width", "Width")
		THIS.Place(loO, toContext, "height", "Height")
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "name", loO.Name)
		loJ.Put(loD, "path", THIS.PathOf(loO))
		loJ.Put(loD, "class", loO.Class)
		loJ.Put(loD, "baseClass", loO.BaseClass)
		loJ.Put(loD, "top", THIS.Prop(loO, "Top"))
		loJ.Put(loD, "left", THIS.Prop(loO, "Left"))
		loJ.Put(loD, "width", THIS.Prop(loO, "Width"))
		loJ.Put(loD, "height", THIS.Prop(loO, "Height"))
		loJ.Put(loD, "saved", .F.)
		_screen.oFoxDock.AgentDid("added " + THIS.PathOf(loO) + " (" + loO.Class + ")")
		RETURN THIS.Done(loD)
	ENDFUNC

	*-- Un tamaño o una posición que vino (solo si es un número) a su propiedad.
	PROCEDURE Place
		LPARAMETERS toO, toContext, tcParam, tcProp
		LOCAL luV, loErr, lcCmd
		IF !PEMSTATUS(toContext.Parameters, tcParam, 5) OR !PEMSTATUS(toO, tcProp, 5)
			RETURN
		ENDIF
		luV = GETPEM(toContext.Parameters, tcParam)
		IF VARTYPE(luV) # "N"
			luV = VAL(TRANSFORM(luV))
		ENDIF
		TRY
			lcCmd = "toO." + tcProp + " = luV"
			&lcCmd
		CATCH TO loErr
		ENDTRY
	ENDPROC
ENDDEFINE


DEFINE CLASS IdeDesignerRemoveControlTool AS IdeDesignerTool
	ToolName = "ide_designer_remove_control"
	lActsOnIde = .T.
	ToolDescription = "Removes a control, and whatever it contains, from the form in the Form Designer or Class Designer " + ;
		"of the Visual FoxPro IDE, as deleting it by hand would. The designer counts it as a change: saved with the form, " + ;
		"and closing the designer asks (VFP alone would not ask after a removal: FoxDock marks the form as changed). " + ;
		"A control that comes from the parent class cannot be removed, and the error says so."

	FUNCTION DefineParameters()
		THIS.AddParam("name", "string", "The control's name or path, as ide_designer_list gives it.", .T.)
	ENDFUNC

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loO, loParent, loD, lcName, lcPath, lcClass, lcMember, loErr, lcFail
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(DS_NO_HOST)
		ENDIF
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lcName = THIS.PText(toContext, "name")
		loO = THIS.Find(loRoot, lcName)
		IF ISNULL(loO) OR EMPTY(lcName)
			RETURN THIS.NoControl(loRoot, lcName)
		ENDIF
		IF UPPER(loO.Name) == UPPER(loRoot.Name) AND TYPE("loO.Parent") # "O"
			RETURN THIS.Err("That is the form itself: it cannot be removed.")
		ENDIF
		lcPath = THIS.PathOf(loO)
		lcClass = loO.Class
		lcMember = loO.Name
		loParent = loO.Parent
		loO = .NULL.
		*-- Un miembro de la clase padre no se quita en la subclase. VFP deja
		*-- quitarlo del objeto vivo sin error, y luego no guarda el formulario
		*-- (1756) y se pierde todo lo demás. PEMSTATUS(<su
		*-- contenedor>, <él>, 6) dice si es heredado, también en el diseñador.
		IF PEMSTATUS(loParent, lcMember, 6)
			RETURN THIS.Err(lcPath + " (" + lcClass + ") comes from the parent class " + loParent.Class + ;
				IIF(EMPTY(loParent.ClassLibrary), "", " (" + loParent.ClassLibrary + ")") + ;
				": in Visual FoxPro a member inherited from the parent class cannot be removed in the subclass, " + ;
				"and nothing was changed. To get it out of the way, hide it or switch it off with " + ;
				"ide_designer_set_property (Visible = .F. or Enabled = .F., whichever the control has).")
		ENDIF
		lcFail = ""
		TRY
			loParent.RemoveObject(lcMember)
			*-- RemoveObject solo no deja el formulario como cambiado: una
			*-- propiedad reasignada con su mismo valor sí.
			loRoot.Width = loRoot.Width
		CATCH TO loErr
			lcFail = TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
		ENDTRY
		IF !EMPTY(lcFail)
			RETURN THIS.Err("Could not remove " + lcPath + ": " + lcFail)
		ENDIF
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "removed", lcPath)
		loJ.Put(loD, "class", lcClass)
		loJ.Put(loD, "saved", .F.)
		_screen.oFoxDock.AgentDid("removed " + lcPath)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerDataEnvironmentTool AS IdeDesignerTool
	ToolName = "ide_designer_dataenvironment"
	ToolDescription = "The data environment of the form in the Form Designer of the Visual FoxPro IDE: each cursor " + ;
		"(name, alias, cursorSource, database, order, readOnly, exclusive, bufferModeOverride) and each relation (name, " + ;
		"parentAlias, childAlias, relationalExpr, childOrder, oneToMany), and autoOpenTables and autoCloseTables. " + ;
		"Reads only; it does not open the tables. A class in the Class Designer has no data environment."

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loDe, loD, loCursors, loRelations, loE, loK, lnN
		LOCAL ARRAY laD[1]
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		lnN = 0
		TRY
			lnN = ASELOBJ(laD, 2)
		CATCH
			lnN = 0
		ENDTRY
		IF lnN = 0 OR VARTYPE(laD[1]) # "O"
			RETURN THIS.Err("The designer has no data environment (a class in the Class Designer has none).")
		ENDIF
		loDe = laD[1]
		loJ = THIS.J()
		loCursors = loJ.MakeArray()
		loRelations = loJ.MakeArray()
		IF PEMSTATUS(loDe, "Objects", 5)
			FOR EACH loK IN loDe.Objects FOXOBJECT
				loE = loJ.MakeObject()
				loJ.Put(loE, "name", loK.Name)
				DO CASE
					CASE UPPER(loK.BaseClass) == "CURSOR"
						loJ.Put(loE, "alias", THIS.Prop(loK, "Alias"))
						loJ.Put(loE, "cursorSource", THIS.Prop(loK, "CursorSource"))
						loJ.Put(loE, "database", THIS.Prop(loK, "Database"))
						loJ.Put(loE, "order", THIS.Prop(loK, "Order"))
						loJ.Put(loE, "readOnly", THIS.Prop(loK, "ReadOnly"))
						loJ.Put(loE, "exclusive", THIS.Prop(loK, "Exclusive"))
						loJ.Put(loE, "bufferModeOverride", THIS.Prop(loK, "BufferModeOverride"))
						loCursors.Add(loE)
					CASE UPPER(loK.BaseClass) == "RELATION"
						loJ.Put(loE, "parentAlias", THIS.Prop(loK, "ParentAlias"))
						loJ.Put(loE, "childAlias", THIS.Prop(loK, "ChildAlias"))
						loJ.Put(loE, "relationalExpr", THIS.Prop(loK, "RelationalExpr"))
						loJ.Put(loE, "childOrder", THIS.Prop(loK, "ChildOrder"))
						loJ.Put(loE, "oneToMany", THIS.Prop(loK, "OneToMany"))
						loRelations.Add(loE)
				ENDCASE
			ENDFOR
		ENDIF
		loD = loJ.MakeObject()
		loJ.Put(loD, "form", loRoot.Name)
		loJ.Put(loD, "autoOpenTables", THIS.Prop(loDe, "AutoOpenTables"))
		loJ.Put(loD, "autoCloseTables", THIS.Prop(loDe, "AutoCloseTables"))
		loJ.Put(loD, "cursors", loCursors)
		loJ.Put(loD, "relations", loRelations)
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE


DEFINE CLASS IdeDesignerSaveTool AS IdeDesignerTool
	ToolName = "ide_designer_save"
	lActsOnIde = .T.
	ToolDescription = "Saves the Form Designer or Class Designer of the Visual FoxPro IDE as File > Save would (VFP's " + ;
		"SYS(1500, '_MFI_SAVE', '_MFILE')). With the designer or the Properties window in front it saves at once and says " + ;
		"whether the files were written: the date and size of the .scx (or .vcx) and of its memo file (.sct, .vct) " + ;
		"before and after. With another window in front (an editor), File > Save would save that one, so FoxDock brings " + ;
		"the designer to the front and the save runs right after this answer, when VFP is back in its loop " + ;
		"(deferred:true); then the window that was in front comes back. What that save wrote comes in lastDeferredSave " + ;
		"(file, written, attempts, when, result) of the next call to ide_designer_save or ide_designer_list; every answer " + ;
		"of this tool carries the last one (null if there was none)."

	FUNCTION Run(toContext)
		LOCAL loJ, loRoot, loD, loS, loP, loL, lcFile, lcTop, lcWin, lcBefore, lcAfter, loErr, lcFail
		LOCAL ARRAY laS[1]
		IF ISNULL(THIS.Host())
			RETURN THIS.Err(DS_NO_HOST)
		ENDIF
		loRoot = THIS.Root()
		IF ISNULL(loRoot)
			RETURN THIS.Unready()
		ENDIF
		loS = THIS.Scope()
		lcFile = ""
		IF loS.Source(@laS) >= 2
			lcFile = TRANSFORM(laS[2])
		ENDIF
		IF EMPTY(lcFile)
			RETURN THIS.Err("FoxDock cannot tell which file the designer has open (ASELOBJ gives none): nothing was saved.")
		ENDIF
		lcTop = WONTOP()
		lcWin = loS.WindowName(loRoot, lcFile)
		lcBefore = loS.Stamp(lcFile)
		loJ = THIS.J()
		loD = loJ.MakeObject()
		loJ.Put(loD, "file", LOWER(lcFile))
		loJ.Put(loD, "before", lcBefore)
		THIS.PutLastDeferred(loJ, loD)
		*-- Con el diseñador o la ventana de propiedades delante, File >
		*-- Save guarda el formulario en el acto.
		IF UPPER(lcTop) == UPPER(lcWin) OR UPPER(lcTop) == "PROPERTIES"
			lcFail = ""
			TRY
				=SYS(1500, "_MFI_SAVE", "_MFILE")
			CATCH TO loErr
				lcFail = TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
			ENDTRY
			IF !EMPTY(lcFail)
				RETURN THIS.Err("File > Save failed: " + lcFail)
			ENDIF
			lcAfter = loS.Stamp(lcFile)
			loJ.Put(loD, "after", lcAfter)
			loJ.Put(loD, "written", !(lcBefore == lcAfter))
			loJ.Put(loD, "deferred", .F.)
			_screen.oFoxDock.AgentDid("saved " + JUSTFNAME(lcFile) + IIF(lcBefore == lcAfter, " (nothing to write)", ""))
			RETURN THIS.Done(loD)
		ENDIF
		*-- Con otra delante: se trae el diseñador, y el guardado y la vuelta van
		*-- en un Timer (en el mismo programa, SYS(1500) no lo guarda).
		lcFail = ""
		TRY
			ACTIVATE WINDOW (lcWin)
		CATCH TO loErr
			lcFail = TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
		ENDTRY
		IF !EMPTY(lcFail) OR !(UPPER(WONTOP()) == UPPER(lcWin))
			RETURN THIS.Err("The window in front is '" + lcTop + "', and FoxDock could not bring '" + lcWin + "' to the front" + ;
				IIF(EMPTY(lcFail), "", " (" + lcFail + ")") + ". Nothing was saved.")
		ENDIF
		loP = _screen.oFoxDock.PluginById("designer")
		loL = CREATEOBJECT("DesignerSaveLater")
		loL.cFile = lcFile
		loL.cDesigner = lcWin
		loL.cWas = lcTop
		loL.cBefore = lcBefore
		loL.oScope = loS
		loP.oSaveLater = loL
		loL.Enabled = .T.
		loJ.Put(loD, "deferred", .T.)
		loJ.Put(loD, "inFront", lcTop)
		loJ.Put(loD, "note", "The designer is in front now and the save runs right after this answer; then '" + lcTop + ;
			"' comes back to the front. What it wrote comes in lastDeferredSave of the next call to ide_designer_save or " + ;
			"ide_designer_list.")
		_screen.oFoxDock.AgentDid("brought " + lcWin + " to the front to save it (" + lcTop + " was in front)")
		RETURN THIS.Done(loD)
	ENDFUNC
ENDDEFINE
