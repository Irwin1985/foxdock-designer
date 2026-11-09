*==================================================================
* DesignerInspect.prg: el módulo «inspect» del paquete «designer».
*
*   Inspect selection         lo seleccionado en el diseñador (o, sin nada
*                             seleccionado, el formulario o la clase): cada
*                             objeto con su ruta, su clase, sus propiedades
*                             cambiadas y los métodos que tienen código, en
*                             %LOCALAPPDATA%\FoxDock\designer\inspect.txt,
*                             abierto de solo lectura (NOEDIT), como el diff
*                             de history
*   Copy selection as code    lo mismo como DEFINE CLASS ... ENDDEFINE, al
*                             portapapeles (DesignerScope.AsCode); la barra de
*                             estado dice cuántos objetos
*   tools                     las diez ide_designer_* (DesignerTools.prg)
*
* Sin un diseñador abierto, las barras lo dicen en la barra de estado y no
* hacen nada. No hace falta que esté delante. Nada abre un diálogo.
*
* Fichero en CP1252, con los acentos escritos.
*==================================================================

#DEFINE CRLF CHR(13) + CHR(10)

DEFINE CLASS DesignerInspect AS Custom
	cId = "inspect"
	oHost = .NULL.
	cLastFile = ""
	cLastCode = ""
	nLastObjects = 0

	PROCEDURE Init
		LPARAMETERS toHost
		This.oHost = toHost
	ENDPROC

	*-- El paquete, por el host: el módulo no guarda una referencia a él.
	PROCEDURE Plugin
		RETURN This.oHost.PluginById("designer")
	ENDPROC

	PROCEDURE BuildMenu
		LPARAMETERS toMenu
		*-- Los textos, en el idioma de FoxDock (DesignerStrings.prg).
		toMenu.AddBar(This.oHost.Translate("designer.inspect"), "InspectSelection", This.oHost.Translate("designer.inspect.message"))
		toMenu.AddBar(This.oHost.Translate("designer.copyCode"), "CopySelectionAsCode", This.oHost.Translate("designer.copyCode.message"))
	ENDPROC

	PROCEDURE GetAgentTools
		LPARAMETERS toTools
		toTools.Add(CREATEOBJECT("IdeDesignerListTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerGetControlTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerSetPropertyTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerSelectionTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerReadMethodTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerWriteMethodTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerAddControlTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerRemoveControlTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerDataEnvironmentTool"))
		toTools.Add(CREATEOBJECT("IdeDesignerSaveTool"))
		RETURN 10
	ENDPROC

	*-- Lo que tratan las barras: lo seleccionado, o la raíz si no hay nada.
	*-- Devuelve cuántos objetos hay en toList (0: no hay diseñador).
	PROCEDURE Targets
		LPARAMETERS toList
		LOCAL loS, loRoot, lnN, lnI, loP
		LOCAL ARRAY laSel[1]
		loP = This.Plugin()
		loS = loP.oScope
		loRoot = loS.Root()
		IF ISNULL(loRoot)
			RETURN 0
		ENDIF
		lnN = loS.Selected(@laSel)
		FOR lnI = 1 TO lnN
			IF VARTYPE(laSel[lnI]) == "O"
				toList.Add(laSel[lnI])
			ENDIF
		ENDFOR
		IF toList.Count = 0
			toList.Add(loRoot)
		ENDIF
		RETURN toList.Count
	ENDPROC

	PROCEDURE NoDesigner
		This.oHost.NotifyKey("designer.noDesigner")
		RETURN .F.
	ENDPROC

	*--------------------------------------------------------------
	* Las barras.
	*--------------------------------------------------------------
	PROCEDURE InspectSelection
		LOCAL loP, loS, loList, loO, lcText, lnN, lnI, lcFile, lcSafety
		LOCAL ARRAY laP[1], laM[1], laSrc[1]
		loP = This.Plugin()
		loS = loP.oScope
		loList = CREATEOBJECT("Collection")
		IF This.Targets(loList) = 0
			RETURN This.NoDesigner()
		ENDIF
		lcText = "* Inspect selection, " + TTOC(DATETIME(), 3)
		IF loS.Source(@laSrc) >= 2
			lcText = lcText + ", " + TRANSFORM(laSrc[2])
		ENDIF
		lcText = lcText + CRLF
		FOR EACH loO IN loList FOXOBJECT
			lcText = lcText + CRLF + "* " + loS.PathOf(loO) + " (" + loO.Class + ;
				IIF(UPPER(loO.Class) == UPPER(loO.BaseClass), "", ", based on " + loO.BaseClass) + ")" + CRLF
			lnN = loS.Changed(loO, @laP)
			IF lnN = 0
				lcText = lcText + "  (no changed properties)" + CRLF
			ENDIF
			FOR lnI = 1 TO lnN
				lcText = lcText + "  " + laP[lnI, 1] + " = " + laP[lnI, 2] + CRLF
			ENDFOR
			lnN = loS.Methods(loO, @laM)
			FOR lnI = 1 TO lnN
				lcText = lcText + "  PROCEDURE " + laM[lnI, 1] + ": " + TRANSFORM(ALINES(laP, laM[lnI, 2])) + " line(s)" + CRLF
			ENDFOR
		ENDFOR
		lcFile = loP.OutDir() + "inspect.txt"
		*-- Con SET SAFETY ON, lo de fábrica, STRTOFILE sobre
		*-- el inspect.txt de la vez anterior preguntaría «overwrite it?».
		lcSafety = SET("SAFETY")
		SET SAFETY OFF
		STRTOFILE(lcText, lcFile, 0)
		SET SAFETY &lcSafety
		This.cLastFile = lcFile
		This.nLastObjects = loList.Count
		MODIFY FILE (lcFile) NOWAIT NOEDIT
		This.oHost.NotifyKey("designer.inspected", loList.Count, lcFile)
		RETURN .T.
	ENDPROC

	PROCEDURE CopySelectionAsCode
		LOCAL loS, loList, loO, lcCode, loP
		loP = This.Plugin()
		loS = loP.oScope
		loList = CREATEOBJECT("Collection")
		IF This.Targets(loList) = 0
			RETURN This.NoDesigner()
		ENDIF
		lcCode = ""
		FOR EACH loO IN loList FOXOBJECT
			lcCode = lcCode + IIF(EMPTY(lcCode), "", CRLF) + loS.AsCode(loO)
		ENDFOR
		This.cLastCode = lcCode
		This.nLastObjects = loList.Count
		*-- Otro programa puede tener el portapapeles: se dice.
		IF !This.oHost.ToClipboard(lcCode, "Copy selection as code")
			This.oHost.NotifyKey("designer.copyHeld", loList.Count)
			RETURN .F.
		ENDIF
		This.oHost.NotifyKey("designer.copied", loList.Count)
		RETURN .T.
	ENDPROC
ENDDEFINE
