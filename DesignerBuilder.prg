*==================================================================
* DesignerBuilder.prg: el módulo «builder» del paquete «designer».
*
* FoxDock se pone como _BUILDER, delante del que hubiera (el BUILDER.APP de
* VFP, o el que el usuario tenga), y le pasa siempre la llamada: «Builder...»
* sigue abriendo lo mismo que antes. Lo único que añade es una línea en
* el log con lo que llegó.
*
* CÓMO, Y POR QUÉ ASÍ:
*   - VFP llama a _BUILDER con dos parámetros: el objeto del diseñador y el
*     origen («RTMOUSE» desde el menú contextual).
*   - _BUILDER = la ruta de FoxDock.APP. FoxDockMain.prg ve que el primer
*     parámetro es un objeto y va por FoxDockBuilder ANTES de su TRY: dentro de
*     un TRY, al cancelar el builder de VFP sale el error 2060 (RETURN/RETRY
*     statement not allowed in TRY/CATCH) en un diálogo.
*   - El gancho no se puede llamar *BUILDER.FXP: wbmain.prg mira SYS(16, 1) y,
*     si lo lleva, busca su tabla en BUILDERS\. FoxDock.APP no lo lleva.
*   - Los parámetros van por valor.
* La ruta del de antes se guarda también en _screen.cFoxDockBuilderPrev (texto:
* sobrevive a CLEAR ALL), para encadenar aunque el host no esté.
*
* Al desmontar o cerrar el IDE (OnShutdown del paquete), _BUILDER vuelve a ser el
* de antes, si sigue siendo FoxDock; si otro lo cambió después, se queda el suyo.
*==================================================================

DEFINE CLASS DesignerBuilder AS Custom
	cId = "builder"
	oHost = .NULL.
	cPrevious = ""    && el _BUILDER que había al montar
	cOurs = ""        && el nuestro: la ruta de FoxDock.APP
	nCalls = 0
	cLast = ""

	PROCEDURE Init
		LPARAMETERS toHost
		This.oHost = toHost
		This.cOurs = toHost.cAppPath
		This.Hook()
	ENDPROC

	PROCEDURE BuildMenu
		LPARAMETERS toMenu
	ENDPROC

	PROCEDURE GetAgentTools
		LPARAMETERS toTools
		RETURN 0
	ENDPROC

	PROCEDURE IsOurs
		LPARAMETERS tcPath
		RETURN !EMPTY(tcPath) AND UPPER(ALLTRIM(tcPath)) == UPPER(ALLTRIM(This.cOurs))
	ENDPROC

	PROCEDURE Hook
		IF !PEMSTATUS(_screen, "cFoxDockBuilderPrev", 5)
			_screen.AddProperty("cFoxDockBuilderPrev", "")
		ENDIF
		IF This.IsOurs(_BUILDER)
			*-- Ya era nuestro (un «wake» tras CLEAR ALL): el de antes es el guardado.
			This.cPrevious = _screen.cFoxDockBuilderPrev
		ELSE
			This.cPrevious = _BUILDER
			_screen.cFoxDockBuilderPrev = _BUILDER
			_BUILDER = This.cOurs
		ENDIF
		This.oHost.Log("designer: _BUILDER is FoxDock (" + This.cOurs + "); it passes every call to " + ;
			IIF(EMPTY(This.cPrevious), "(none: _BUILDER was empty)", This.cPrevious))
	ENDPROC

	PROCEDURE Restore
		IF This.IsOurs(_BUILDER)
			_BUILDER = This.cPrevious
			This.oHost.Log("designer: _BUILDER is back to " + IIF(EMPTY(This.cPrevious), "(empty)", This.cPrevious))
		ELSE
			This.oHost.Log("designer: _BUILDER was changed after FoxDock (now " + _BUILDER + "); left as it is")
		ENDIF
		IF PEMSTATUS(_screen, "cFoxDockBuilderPrev", 5)
			_screen.cFoxDockBuilderPrev = ""
		ENDIF
	ENDPROC

	*-- Una llamada de VFP: se anota y se devuelve a quién pasarla.
	PROCEDURE Called
		LPARAMETERS tnCount, tv1, tv2
		LOCAL lcWhat, loS, loP
		loP = This.oHost.PluginById("designer")
		loS = loP.oScope
		This.nCalls = This.nCalls + 1
		lcWhat = IIF(VARTYPE(tv1) == "O", loS.PathOf(tv1) + " (" + tv1.Class + ")", TRANSFORM(tv1)) + ;
			IIF(tnCount >= 2, ", " + TRANSFORM(tv2), "")
		This.cLast = lcWhat
		This.oHost.Log("designer: Builder... on " + lcWhat + "; passed to " + ;
			IIF(EMPTY(This.cPrevious) OR This.IsOurs(This.cPrevious), "nobody (there was no builder before)", This.cPrevious))
		RETURN IIF(This.IsOurs(This.cPrevious), "", This.cPrevious)
	ENDPROC
ENDDEFINE
