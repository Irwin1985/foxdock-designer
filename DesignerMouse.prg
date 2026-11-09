*==================================================================
* DesignerMouse.prg: el módulo «mouse» del paquete «designer».
*
*   CTRL+F12     el control que hay bajo el ratón: su ruta y su clase, a la
*                barra de estado y al log. Es un ON KEY LABEL (AddKey) y se
*                cambia o se quita en config.json como un atajo de barra:
*                "keys": { "designer.InspectUnderMouse": "ALT+F12" } ("" la quita)
*   menú         en un clic derecho sobre un diseñador, una línea de log con el
*   contextual   control que había debajo. Solo se anota: el menú de VFP
*                sale igual
*
* El control sale de SYS(1270, x, y), con el punto del ratón (GetCursorPos) o
* el del lParam del WM_CONTEXTMENU: da el objeto del
* formulario en diseño. Sin coordenadas, y con el ratón fuera de VFP, SYS(1270)
* da _SCREEN y no .F.: _SCREEN no es un control, y se dice que no hay ninguno.
*
* Fichero en CP1252, con los acentos escritos.
*==================================================================

DEFINE CLASS DesignerMouse AS Custom
	cId = "mouse"
	oHost = .NULL.
	cKey = ""
	cLast = ""        && lo último que dijo (para la suite)

	PROCEDURE Init
		LPARAMETERS toHost
		This.oHost = toHost
		DECLARE INTEGER GetCursorPos IN user32 AS FdDsgGetCursorPos STRING @lpPoint
	ENDPROC

	PROCEDURE Plugin
		RETURN This.oHost.PluginById("designer")
	ENDPROC

	*-- La tecla: la de "keys" de config.json si está, si no CTRL+F12. Los
	*-- "keys" se leen aquí: el host los lee al construir el menú, que en el
	*-- montaje va DESPUÉS de los BuildMenu (CollectMenus).
	PROCEDURE BuildMenu
		LPARAMETERS toMenu
		LOCAL loO
		loO = This.oHost.oOptions
		loO.ReadKeys()
		This.cKey = loO.ShortcutFor("designer", "InspectUnderMouse", "CTRL+F12")
		IF EMPTY(This.cKey)
			This.oHost.Log("designer: the key of InspectUnderMouse is off in config.json (keys)")
			RETURN
		ENDIF
		toMenu.AddKey(This.cKey, "InspectUnderMouse")
	ENDPROC

	PROCEDURE GetAgentTools
		LPARAMETERS toTools
		RETURN 0
	ENDPROC

	*-- El objeto bajo un punto del escritorio, o .NULL. si no es un control.
	PROCEDURE ObjectAt
		LPARAMETERS tnX, tnY
		LOCAL luO, loErr
		luO = .NULL.
		TRY
			luO = SYS(1270, tnX, tnY)
		CATCH TO loErr
			luO = .NULL.
		ENDTRY
		IF VARTYPE(luO) # "O"
			RETURN .NULL.
		ENDIF
		IF TYPE("luO.Parent") # "O" AND UPPER(luO.BaseClass) == "FORM" AND UPPER(luO.Name) == UPPER(_screen.Name)
			RETURN .NULL.
		ENDIF
		RETURN luO
	ENDPROC

	*-- ¿Cuelga del formulario (o la clase) que hay en el diseñador?
	PROCEDURE InDesigner
		LPARAMETERS toO
		LOCAL loS, loRoot, loTop, llIn, loErr
		loS = This.Plugin()
		loS = loS.oScope
		loRoot = loS.Root()
		IF ISNULL(loRoot)
			RETURN .F.
		ENDIF
		llIn = .F.
		TRY
			loTop = loS.TopForm(toO)
			llIn = (loTop.HWnd = loRoot.HWnd) AND loTop.Name == loRoot.Name
		CATCH TO loErr
			llIn = .F.
		ENDTRY
		RETURN llIn
	ENDPROC

	PROCEDURE Describe
		LPARAMETERS toO
		LOCAL loS
		loS = This.Plugin()
		loS = loS.oScope
		RETURN loS.PathOf(toO) + " (" + toO.Class + IIF(UPPER(toO.Class) == UPPER(toO.BaseClass), "", ", based on " + toO.BaseClass) + ")"
	ENDPROC

	*-- La tecla.
	PROCEDURE InspectUnderMouse
		LOCAL lcPt, lnX, lnY, loO
		lcPt = REPLICATE(CHR(0), 8)
		=FdDsgGetCursorPos(@lcPt)
		lnX = CTOBIN(LEFT(lcPt, 4), "4RS")
		lnY = CTOBIN(RIGHT(lcPt, 4), "4RS")
		RETURN This.InspectAt(lnX, lnY)
	ENDPROC

	*-- Lo de la tecla con un punto dado (la suite y el arnés lo llaman así).
	PROCEDURE InspectAt
		LPARAMETERS tnX, tnY
		LOCAL loO
		loO = This.ObjectAt(tnX, tnY)
		*-- cLast, en inglés (la suite y el log); el aviso, en el idioma de FoxDock.
		IF ISNULL(loO)
			This.cLast = "no control under the mouse (" + TRANSFORM(tnX) + "," + TRANSFORM(tnY) + ")"
			This.oHost.Notify(This.oHost.Translate("designer.mouse.none", tnX, tnY), "Designer: " + This.cLast)
		ELSE
			This.cLast = IIF(This.InDesigner(loO), "in the designer: ", "running: ") + This.Describe(loO)
			This.oHost.Notify(This.oHost.Translate(IIF(This.InDesigner(loO), "designer.mouse.inDesigner", "designer.mouse.running"), ;
				This.Describe(loO)), "Designer: " + This.cLast)
		ENDIF
		RETURN !ISNULL(loO)
	ENDPROC

	*-- El menú contextual: una línea de log si el clic cayó en un
	*-- diseñador; nada más, y el menú de VFP sale igual.
	PROCEDURE OnContextMenu
		LPARAMETERS toInfo
		LOCAL loO
		IF VARTYPE(toInfo) # "O" OR !PEMSTATUS(toInfo, "x", 5)
			RETURN .F.
		ENDIF
		loO = This.ObjectAt(toInfo.x, toInfo.y)
		IF ISNULL(loO) OR !This.InDesigner(loO)
			RETURN .F.
		ENDIF
		This.cLast = "context menu in the designer on " + This.Describe(loO)
		This.oHost.Log("designer: " + This.cLast)
		RETURN .T.
	ENDPROC
ENDDEFINE
