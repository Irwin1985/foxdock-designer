*==================================================================
* DesignerPlugin.prg: el paquete «designer» de FoxDock.
*
* El tercer paquete, con el molde de «editor» y «data»: un módulo por .prg con
* el prefijo del paquete, que se apaga en config.json y apagado no existe, ni
* sus barras ni su tecla ni sus tools:
*   "options": { "designer": { "mouse": { "enabled": false } } }
*
* Los módulos (ModuleList):
*   inspect   las barras Inspect selection y Copy selection as code, y las
*             diez tools ide_designer_* (DesignerTools.prg)
*   mouse     CTRL+F12 (configurable: "keys": { "designer.InspectUnderMouse": ... }):
*             el control bajo el ratón a la barra de estado y al log; y, en un
*             menú contextual sobre un diseñador, una línea de log (solo
*             se anota)
*   builder   FoxDock como _BUILDER, delante del que hubiera, al que llama
*             siempre; una línea de log por llamada, y nada más
*
* LO QUE SE SABE DEL DISEÑADOR Y SE USA AQUÍ:
*   - ASELOBJ ve el diseñador aunque no esté delante: con varios
*     abiertos, el último que se activó. ASELOBJ(, 3) da el contenedor, no el
*     control de la ventana de código: ese lo dice WONTOP() («CMDOK.CLICK»).
*   - WriteMethod, WriteExpression, AddObject y una propiedad dejan el
*     formulario como cambiado; RemoveObject NO: quien quita, reasigna
*     una propiedad con su mismo valor. AddObject pone el nombre en mayúsculas.
*   - SYS(1270, x, y) da el control del diseñador; sin coordenadas y con
*     el ratón fuera de VFP da _SCREEN, no .F.
*   - _BUILDER se encadena si el programa del gancho no se llama
*     *BUILDER.FXP, la llamada al de antes no está dentro de un TRY y los
*     parámetros van por valor. Por eso la llamada entra por FoxDockMain.prg
*     ANTES de su TRY (FoxDockBuilder).
*   - El texto que manda el agente llega en CP1252: no se convierte.
*==================================================================

#DEFINE CRLF CHR(13) + CHR(10)

DEFINE CLASS DesignerPlugin AS PluginBase
	cId = "designer"
	cTitle = "Designer"
	nOrder = 940
	cVersion = "0.1.1"
	lWantsIdle = .T.
	oModules = .NULL.
	oScope = .NULL.
	oSaveLater = .NULL.    && el guardado diferido de ide_designer_save
	oLastDeferred = .NULL. && lo que hizo el último diferido: file, written, attempts, when, result

	PROCEDURE Init
		LPARAMETERS toHost
		DODEFAULT(toHost)
		This.oScope = CREATEOBJECT("DesignerScope")
	ENDPROC

	*-- Los módulos del paquete, uno por línea: id, clase y .prg.
	PROCEDURE ModuleList
		RETURN "inspect,DesignerInspect,DesignerInspect.prg" + CRLF + ;
			"mouse,DesignerMouse,DesignerMouse.prg" + CRLF + ;
			"builder,DesignerBuilder,DesignerBuilder.prg"
	ENDPROC

	PROCEDURE Modules
		LOCAL lnI
		LOCAL ARRAY laM[1], laP[1]
		IF ISNULL(This.oModules)
			This.oModules = CREATEOBJECT("Collection")
			FOR lnI = 1 TO ALINES(laM, This.ModuleList(), 1 + 4)
				IF ALINES(laP, laM[lnI], 1, ",") = 3
					This.LoadModule(LOWER(laP[1]), laP[2], laP[3])
				ENDIF
			ENDFOR
		ENDIF
		RETURN This.oModules
	ENDPROC

	PROCEDURE Module
		LPARAMETERS tcId
		LOCAL loMods
		loMods = This.Modules()
		IF loMods.GetKey(LOWER(tcId)) > 0
			RETURN loMods.Item(LOWER(tcId))
		ENDIF
		RETURN .NULL.
	ENDPROC

	PROTECTED PROCEDURE LoadModule
		LPARAMETERS tcId, tcClass, tcPrg
		LOCAL loM, loErr
		IF !This.oHost.Options.Get(This.cId, tcId + ".enabled", .T.)
			This.oHost.Log(This.cId + ": module " + tcId + " is off in config.json (options." + This.cId + "." + ;
				tcId + ".enabled): its bars, keys and tools are not there")
			RETURN
		ENDIF
		TRY
			SET PROCEDURE TO (This.CodeFile(tcPrg)) ADDITIVE
			loM = CREATEOBJECT(tcClass, This.oHost)
			This.oModules.Add(loM, tcId)
			This.oHost.Log(This.cId + ": module " + tcId + " loaded")
		CATCH TO loErr
			This.oHost.LogFault(This.cId + ": module " + tcId + " failed to load: " + TRANSFORM(loErr.ErrorNo) + ;
				" " + loErr.Message)
		ENDTRY
	ENDPROC

	*-- Barras planas: cada módulo pone las suyas (y su tecla) con AddBar y AddKey.
	PROCEDURE BuildMenu
		LPARAMETERS toMenu
		LOCAL loMods, loM
		*-- El título, en el idioma de FoxDock (DesignerStrings.prg).
		This.cTitle = This.oHost.Translate("designer.title")
		loMods = This.Modules()
		FOR EACH loM IN loMods FOXOBJECT
			loM.BuildMenu(toMenu)
		ENDFOR
	ENDPROC

	PROCEDURE GetAgentTools
		LPARAMETERS toTools
		LOCAL loMods, loM, lnN
		IF !("\IDETOOLS." $ UPPER(SET("PROCEDURE")))
			RETURN 0
		ENDIF
		This.EnsureProcedures()
		lnN = 0
		loMods = This.Modules()
		FOR EACH loM IN loMods FOXOBJECT
			lnN = lnN + loM.GetAgentTools(toTools)
		ENDFOR
		RETURN lnN
	ENDPROC

	*-- Las clases de las tools tienen que seguir visibles: el Bridge crea una
	*-- por llamada, por su nombre (y CLOSE ALL vacía SET PROCEDURE).
	PROCEDURE OnIdle
		This.EnsureProcedures()
	ENDPROC

	PROCEDURE EnsureProcedures
		LOCAL lcTools, loErr
		lcTools = This.CodeFile("DesignerTools.prg")
		IF !EMPTY(This.cHome) AND !("\DESIGNERTOOLS." $ UPPER(SET("PROCEDURE"))) AND ;
				"\IDETOOLS." $ UPPER(SET("PROCEDURE")) AND FILE(lcTools)
			TRY
				SET PROCEDURE TO (lcTools) ADDITIVE
			CATCH TO loErr
				This.oHost.LogWarn("designer: " + lcTools + " not loaded: " + loErr.Message)
			ENDTRY
		ENDIF
	ENDPROC

	*-- El menú contextual solo se anota (módulo mouse).
	PROCEDURE OnContextMenu
		LPARAMETERS toInfo
		LOCAL loM
		loM = This.Module("mouse")
		IF ISNULL(loM)
			RETURN .F.
		ENDIF
		RETURN loM.OnContextMenu(toInfo)
	ENDPROC

	*-- Al cerrar el IDE o desmontar FoxDock, _BUILDER vuelve a ser el de antes.
	PROCEDURE OnShutdown
		LOCAL loM
		loM = This.Module("builder")
		IF !ISNULL(loM)
			loM.Restore()
		ENDIF
	ENDPROC

	*-- La carpeta de los ficheros del paquete: %LOCALAPPDATA%\FoxDock\designer\.
	PROCEDURE OutDir
		LOCAL lcDir
		lcDir = This.oHost.DataDir + "designer\"
		IF !DIRECTORY(lcDir, 1)
			MKDIR (lcDir)
		ENDIF
		RETURN lcDir
	ENDPROC

	*-- Las acciones de las barras y de la tecla. Con el módulo apagado no hay
	*-- barra que las llame; si llega una (una barra vieja), se dice y no pasa nada.
	PROCEDURE InspectSelection
		LOCAL loM
		loM = This.Module("inspect")
		RETURN IIF(ISNULL(loM), This.Off("inspect"), loM.InspectSelection())
	ENDPROC

	PROCEDURE CopySelectionAsCode
		LOCAL loM
		loM = This.Module("inspect")
		RETURN IIF(ISNULL(loM), This.Off("inspect"), loM.CopySelectionAsCode())
	ENDPROC

	PROCEDURE InspectUnderMouse
		LOCAL loM
		loM = This.Module("mouse")
		RETURN IIF(ISNULL(loM), This.Off("mouse"), loM.InspectUnderMouse())
	ENDPROC

	*-- Lo llama FoxDockBuilder (FoxDockMain.prg) cuando VFP llama a _BUILDER:
	*-- anota y devuelve el builder al que hay que pasar la llamada ("" si
	*-- ninguno). La llamada en sí la hace FoxDockMain, fuera de todo TRY.
	PROCEDURE BuilderCalled
		LPARAMETERS tnCount, tv1, tv2
		LOCAL loM
		loM = This.Module("builder")
		IF ISNULL(loM)
			RETURN ""
		ENDIF
		RETURN loM.Called(tnCount, tv1, tv2)
	ENDPROC

	PROTECTED PROCEDURE Off
		LPARAMETERS tcId
		This.oHost.LogWarn(This.cId + ": module " + tcId + " is off or did not load")
		RETURN .F.
	ENDPROC
ENDDEFINE


*------------------------------------------------------------------
* Lo que se lee del diseñador, para las barras y para las tools. Vive en el
* paquete (oScope): las tools lo piden por PluginById("designer").oScope.
*
*   Root()              el formulario o la clase en diseño, o .NULL.
*   Source(@aS)         ASELOBJ(, 3): [1] objeto, [2] .scx/.vcx, [3] #INCLUDE; devuelve 0 o 3
*   Selected(@aSel)     ASELOBJ(, 0): lo seleccionado; devuelve cuántos
*   Find(oRoot, cName)  un objeto por su nombre o su ruta (sin distinguir mayúsculas)
*   PathOf(o)           la ruta hasta el formulario («Form1.Pageframe1.Page1.txtNombre»)
*   Prop(o, cProp)      una propiedad, .NULL. si no se lee o es un objeto
*   Changed(o, @aP)     las propiedades cambiadas: [n, 1] nombre, [n, 2] el código VFP de su valor
*   Methods(o, @aM)     los métodos y eventos con código: [n, 1] nombre, [n, 2] el código
*   AsCode(o)           o como DEFINE CLASS ... ENDDEFINE
*   TopForm(o)          el formulario (o el objeto de arriba) del que cuelga o
*   WindowName(o, f)    el nombre de la ventana del diseñador, para ACTIVATE WINDOW
*   Stamp(cFile)        fecha, hora y tamaño del .scx (o .vcx) y de su memo
*------------------------------------------------------------------
DEFINE CLASS DesignerScope AS Custom

	*-- El objeto raíz en diseño: el contenedor de lo seleccionado (ASELOBJ con
	*-- 1), subiendo por Parent hasta el formulario o la clase. No hace falta que
	*-- el diseñador esté delante.
	PROCEDURE Root
		LOCAL lnN, loO, loErr
		LOCAL ARRAY laO[1]
		loO = .NULL.
		TRY
			lnN = ASELOBJ(laO, 1)
			IF lnN = 0
				lnN = ASELOBJ(laO)
			ENDIF
			IF lnN > 0
				loO = laO[1]
				DO WHILE VARTYPE(loO) == "O" AND TYPE("loO.Parent") == "O" AND ;
						!INLIST(UPPER(loO.BaseClass), "FORM", "FORMSET")
					loO = loO.Parent
				ENDDO
			ENDIF
		CATCH TO loErr
			loO = .NULL.
		ENDTRY
		RETURN loO
	ENDPROC

	PROCEDURE Source
		LPARAMETERS taS
		LOCAL lnN, loErr
		lnN = 0
		TRY
			lnN = ASELOBJ(taS, 3)
		CATCH TO loErr
			lnN = 0
		ENDTRY
		RETURN lnN
	ENDPROC

	PROCEDURE Selected
		LPARAMETERS taSel
		LOCAL lnN, loErr
		lnN = 0
		TRY
			lnN = ASELOBJ(taSel)
		CATCH TO loErr
			lnN = 0
		ENDTRY
		RETURN lnN
	ENDPROC

	*-- «form» (.scx) o «class» (.vcx), por ASELOBJ(, 3).
	PROCEDURE Kind
		LOCAL ARRAY laS[1]
		IF This.Source(@laS) < 2
			RETURN ""
		ENDIF
		RETURN ICASE(UPPER(JUSTEXT(TRANSFORM(laS[2]))) == "SCX", "form", ;
			UPPER(JUSTEXT(TRANSFORM(laS[2]))) == "VCX", "class", "")
	ENDPROC

	*-- Un control por su nombre («cmdOk») o su ruta («Form1.Page1.cmdOk»).
	PROCEDURE Find
		LPARAMETERS toRoot, tcName
		LOCAL lcWant
		lcWant = UPPER(ALLTRIM(tcName))
		IF EMPTY(lcWant) OR UPPER(toRoot.Name) == lcWant
			RETURN toRoot
		ENDIF
		RETURN This.FindIn(toRoot, lcWant, UPPER(toRoot.Name))
	ENDPROC

	PROCEDURE FindIn
		LPARAMETERS toC, tcWant, tcPath
		LOCAL loK, lcPath, loHit
		IF !PEMSTATUS(toC, "Objects", 5)
			RETURN .NULL.
		ENDIF
		FOR EACH loK IN toC.Objects FOXOBJECT
			lcPath = tcPath + "." + UPPER(loK.Name)
			IF UPPER(loK.Name) == tcWant OR lcPath == tcWant
				RETURN loK
			ENDIF
			loHit = This.FindIn(loK, tcWant, lcPath)
			IF VARTYPE(loHit) == "O"
				RETURN loHit
			ENDIF
		ENDFOR
		RETURN .NULL.
	ENDPROC

	PROCEDURE PathOf
		LPARAMETERS toO
		LOCAL lcP, loO
		*-- Hasta el formulario, sin el Formset que el diseñador pone encima.
		lcP = toO.Name
		loO = toO
		DO WHILE TYPE("loO.Parent") == "O" AND !INLIST(UPPER(loO.BaseClass), "FORM", "FORMSET")
			loO = loO.Parent
			lcP = loO.Name + "." + lcP
		ENDDO
		RETURN lcP
	ENDPROC

	*-- El nombre de la ventana del diseñador, el que da WONTOP() y acepta
	*-- ACTIVATE WINDOW sin distinguir mayúsculas: «Form Designer -
	*-- dcust.scx», o «Class Designer - lib.vcx (clase)».
	PROCEDURE WindowName
		LPARAMETERS toRoot, tcFile
		IF UPPER(JUSTEXT(tcFile)) == "VCX"
			RETURN "Class Designer - " + LOWER(JUSTFNAME(tcFile)) + " (" + LOWER(toRoot.Name) + ")"
		ENDIF
		RETURN "Form Designer - " + LOWER(JUSTFNAME(tcFile))
	ENDPROC

	*-- Fecha, hora y tamaño del .scx y de su memo (.sct; .vct de una .vcx): el
	*-- código de un método va al memo, y el .scx, de registros fijos, puede no
	*-- cambiar de tamaño ni, en el mismo segundo, de hora.
	PROCEDURE Stamp
		LPARAMETERS tcFile
		LOCAL lcMemo
		lcMemo = FORCEEXT(tcFile, IIF(UPPER(JUSTEXT(tcFile)) == "VCX", "VCT", "SCT"))
		RETURN This.StampOf(tcFile) + "; " + This.StampOf(lcMemo)
	ENDPROC

	*-- «dcust.scx aaaa-mm-dd hh:mm:ss, 1578 bytes».
	PROCEDURE StampOf
		LPARAMETERS tcFile
		LOCAL ARRAY laF[1]
		IF EMPTY(tcFile) OR ADIR(laF, tcFile) # 1
			RETURN ""
		ENDIF
		RETURN LOWER(laF[1, 1]) + " " + DTOC(laF[1, 3], 1) + " " + laF[1, 4] + ", " + TRANSFORM(laF[1, 2]) + " bytes"
	ENDPROC

	PROCEDURE TopForm
		LPARAMETERS toO
		LOCAL loO
		loO = toO
		DO WHILE TYPE("loO.Parent") == "O" AND !INLIST(UPPER(loO.BaseClass), "FORM", "FORMSET")
			loO = loO.Parent
		ENDDO
		RETURN loO
	ENDPROC

	PROCEDURE Prop
		LPARAMETERS toO, tcProp
		LOCAL luV, loErr
		luV = .NULL.
		TRY
			IF PEMSTATUS(toO, tcProp, 5)
				luV = GETPEM(toO, tcProp)
			ENDIF
		CATCH TO loErr
		ENDTRY
		RETURN IIF(VARTYPE(luV) == "O", .NULL., luV)
	ENDPROC

	*-- Las propiedades cambiadas (PEMSTATUS 0), menos Name, las de solo lectura
	*-- y las que son objetos. El valor, como código de VFP: la expresión si la
	*-- tiene (ReadExpression, sin el «=»), si no el literal.
	PROCEDURE Changed
		LPARAMETERS toO, taP
		LOCAL lnN, lnI, lnOut, lcName, lcCode, loErr
		LOCAL ARRAY laM[1]
		lnOut = 0
		lnN = AMEMBERS(laM, toO, 1)
		FOR lnI = 1 TO lnN
			lcName = laM[lnI, 1]
			IF !(UPPER(laM[lnI, 2]) == "PROPERTY") OR UPPER(lcName) == "NAME"
				LOOP
			ENDIF
			lcCode = ""
			TRY
				IF PEMSTATUS(toO, lcName, 0) AND !PEMSTATUS(toO, lcName, 1)
					lcCode = This.PropCode(toO, lcName)
				ENDIF
			CATCH TO loErr
				lcCode = ""
			ENDTRY
			IF !EMPTY(lcCode)
				lnOut = lnOut + 1
				DIMENSION taP[lnOut, 2]
				taP[lnOut, 1] = PROPER(lcName)
				taP[lnOut, 2] = lcCode
			ENDIF
		ENDFOR
		RETURN lnOut
	ENDPROC

	PROCEDURE PropCode
		LPARAMETERS toO, tcProp
		LOCAL lcExpr, luV, loErr
		lcExpr = ""
		TRY
			lcExpr = toO.ReadExpression(tcProp)
		CATCH TO loErr
			lcExpr = ""
		ENDTRY
		IF !EMPTY(lcExpr)
			RETURN ALLTRIM(IIF(LEFT(LTRIM(lcExpr), 1) == "=", SUBSTR(LTRIM(lcExpr), 2), lcExpr))
		ENDIF
		luV = GETPEM(toO, tcProp)
		RETURN This.Literal(luV)
	ENDPROC

	*-- Un valor como literal de VFP ("" si no tiene: un objeto).
	PROCEDURE Literal
		LPARAMETERS tvV
		DO CASE
			CASE ISNULL(tvV)
				RETURN ".NULL."
			CASE VARTYPE(tvV) == "C"
				RETURN This.Quote(tvV)
			CASE VARTYPE(tvV) == "L"
				RETURN IIF(tvV, ".T.", ".F.")
			CASE VARTYPE(tvV) $ "NY"
				RETURN ALLTRIM(TRANSFORM(tvV))
			CASE VARTYPE(tvV) == "D"
				RETURN IIF(EMPTY(tvV), "{}", "{^" + DTOC(tvV, 1) + "}")
			CASE VARTYPE(tvV) == "T"
				RETURN IIF(EMPTY(tvV), "{}", "{^" + TTOC(tvV, 3) + "}")
		ENDCASE
		RETURN ""
	ENDPROC

	*-- Una cadena entre los delimitadores que no lleve dentro; con los tres,
	*-- trozos unidos con +. Los saltos de línea, con CHR(13) y CHR(10).
	PROCEDURE Quote
		LPARAMETERS tcS
		LOCAL lcS, lcOut, lnP
		lcS = tcS
		IF CHR(13) $ lcS OR CHR(10) $ lcS
			lcS = STRTRAN(STRTRAN(lcS, CHR(13) + CHR(10), CHR(10)), CHR(13), CHR(10))
			lcOut = ""
			lnP = AT(CHR(10), lcS)
			DO WHILE lnP > 0
				lcOut = lcOut + This.Quote(LEFT(lcS, lnP - 1)) + " + CHR(13) + CHR(10) + "
				lcS = SUBSTR(lcS, lnP + 1)
				lnP = AT(CHR(10), lcS)
			ENDDO
			RETURN lcOut + This.Quote(lcS)
		ENDIF
		DO CASE
			CASE !(["] $ lcS)
				RETURN ["] + lcS + ["]
			CASE !(['] $ lcS)
				RETURN ['] + lcS + [']
			CASE !("]" $ lcS) AND !("[" $ lcS)
				RETURN "[" + lcS + "]"
		ENDCASE
		RETURN ["] + STRTRAN(lcS, ["], ["] + ' + ["] + ' + ["]) + ["]
	ENDPROC

	*-- Los métodos y eventos con código en este objeto (ReadMethod).
	PROCEDURE Methods
		LPARAMETERS toO, taM
		LOCAL lnN, lnI, lnOut, lcCode, loErr
		LOCAL ARRAY laM[1]
		lnOut = 0
		lnN = AMEMBERS(laM, toO, 1)
		FOR lnI = 1 TO lnN
			IF !INLIST(UPPER(laM[lnI, 2]), "METHOD", "EVENT")
				LOOP
			ENDIF
			lcCode = ""
			TRY
				lcCode = toO.ReadMethod(laM[lnI, 1])
			CATCH TO loErr
				lcCode = ""
			ENDTRY
			IF !EMPTY(lcCode)
				lnOut = lnOut + 1
				DIMENSION taM[lnOut, 2]
				taM[lnOut, 1] = PROPER(laM[lnI, 1])
				taM[lnOut, 2] = lcCode
			ENDIF
		ENDFOR
		RETURN lnOut
	ENDPROC

	*-- Los nombres de todos los métodos y eventos, separados por comas.
	PROCEDURE MethodNames
		LPARAMETERS toO
		LOCAL lnN, lnI, lcOut
		LOCAL ARRAY laM[1]
		lcOut = ""
		lnN = AMEMBERS(laM, toO, 1)
		FOR lnI = 1 TO lnN
			IF INLIST(UPPER(laM[lnI, 2]), "METHOD", "EVENT")
				lcOut = lcOut + IIF(EMPTY(lcOut), "", ", ") + PROPER(laM[lnI, 1])
			ENDIF
		ENDFOR
		RETURN lcOut
	ENDPROC

	*-- El objeto como DEFINE CLASS: sus propiedades cambiadas, sus objetos de
	*-- un nivel por debajo (ADD OBJECT ... WITH, con las suyas), y los métodos
	*-- con código de él y de esos objetos. Lo que cuelga más abajo no cabe en un
	*-- DEFINE CLASS (ADD OBJECT no anida): se dice en un comentario.
	PROCEDURE AsCode
		LPARAMETERS toO
		LOCAL lcOut, lnN, lnI, loK, lnK, lcWith, lcLib, lcDeep, lcName
		LOCAL ARRAY laP[1], laM[1], laKP[1]
		lcLib = TRANSFORM(This.Prop(toO, "ClassLibrary"))
		*-- Un objeto que se llama como su clase (la raíz de un formulario basado en
		*-- clase: el .scx le pone el nombre de la clase) daría una clase
		*-- recursiva (error 1950): se llama <nombre>_copy, y se dice.
		lcName = toO.Name
		lcOut = ""
		IF UPPER(toO.Name) == UPPER(toO.Class)
			lcName = toO.Name + "_copy"
			lcOut = "* named " + lcName + ": " + toO.Name + " is its parent class" + CRLF
		ENDIF
		lcOut = lcOut + "DEFINE CLASS " + lcName + " AS " + toO.Class + ;
			IIF(EMPTY(lcLib) OR lcLib == ".NULL.", "", " OF " + This.Quote(lcLib)) + CRLF
		lnN = This.Changed(toO, @laP)
		FOR lnI = 1 TO lnN
			lcOut = lcOut + CHR(9) + laP[lnI, 1] + " = " + laP[lnI, 2] + CRLF
		ENDFOR
		lcDeep = ""
		IF PEMSTATUS(toO, "Objects", 5)
			FOR EACH loK IN toO.Objects FOXOBJECT
				*-- Un miembro de la clase padre ya viene con ella: no
				*-- se añade otra vez, se dice.
				IF PEMSTATUS(toO, loK.Name, 6)
					lcOut = lcOut + CHR(9) + "* " + loK.Name + " (" + loK.Class + "): inherited from " + toO.Class + ;
						", not added here" + CRLF
					LOOP
				ENDIF
				lcWith = ""
				lnK = This.Changed(loK, @laKP)
				FOR lnI = 1 TO lnK
					lcWith = lcWith + IIF(lnI = 1, " WITH ;" + CRLF + CHR(9) + CHR(9), ", ;" + CRLF + CHR(9) + CHR(9)) + ;
						laKP[lnI, 1] + " = " + laKP[lnI, 2]
				ENDFOR
				lcOut = lcOut + CHR(9) + "ADD OBJECT " + loK.Name + " AS " + loK.Class + lcWith + CRLF
				IF PEMSTATUS(loK, "Objects", 5) AND loK.Objects.Count > 0
					lcDeep = lcDeep + CHR(9) + "* " + This.PathOf(loK) + ": its " + TRANSFORM(loK.Objects.Count) + ;
						" contained object(s) are not here (ADD OBJECT does not nest)" + CRLF
				ENDIF
			ENDFOR
		ENDIF
		lcOut = lcOut + lcDeep
		lnN = This.Methods(toO, @laM)
		FOR lnI = 1 TO lnN
			lcOut = lcOut + CRLF + CHR(9) + "PROCEDURE " + laM[lnI, 1] + CRLF + This.Body(laM[lnI, 2]) + CHR(9) + "ENDPROC" + CRLF
		ENDFOR
		IF PEMSTATUS(toO, "Objects", 5)
			FOR EACH loK IN toO.Objects FOXOBJECT
				lnN = This.Methods(loK, @laM)
				FOR lnI = 1 TO lnN
					lcOut = lcOut + CRLF + CHR(9) + "PROCEDURE " + loK.Name + "." + laM[lnI, 1] + CRLF + ;
						This.Body(laM[lnI, 2]) + CHR(9) + "ENDPROC" + CRLF
				ENDFOR
			ENDFOR
		ENDIF
		RETURN lcOut + "ENDDEFINE" + CRLF
	ENDPROC

	*-- El código de un método, con dos tabuladores delante de cada línea.
	PROCEDURE Body
		LPARAMETERS tcCode
		LOCAL lnN, lnI, lcOut
		LOCAL ARRAY laL[1]
		lcOut = ""
		lnN = ALINES(laL, tcCode)
		FOR lnI = 1 TO lnN
			lcOut = lcOut + CHR(9) + CHR(9) + laL[lnI] + CRLF
		ENDFOR
		RETURN lcOut
	ENDPROC
ENDDEFINE


*------------------------------------------------------------------
* El guardado diferido de ide_designer_save. Con otra ventana
* delante (un editor), File > Save guarda esa. La tool trae el diseñador con
* ACTIVATE WINDOW, pero SYS(1500) en el mismo programa no lo guarda, ni con
* DOEVENTS: hace falta que VFP vuelva a su bucle. Este Timer lo hace una vez,
* 200 ms después de que la tool conteste: guarda, devuelve delante la ventana
* que estaba, y lo dice en el log y en la barra de estado.
*------------------------------------------------------------------
DEFINE CLASS DesignerSaveLater AS Timer
	Interval = 200
	Enabled = .F.
	cFile = ""        && el .scx o .vcx
	cDesigner = ""    && la ventana del diseñador
	cWas = ""         && la ventana que estaba delante
	cBefore = ""      && el sello de antes
	cSaved = ""       && lo que pasó al guardar
	cResult = ""      && lo que pasó al final (para las pruebas); vacío mientras dura
	nTries = 0        && ticks esperando al diseñador delante
	nBack = 0         && ticks esperando a la ventana que estaba
	cTrail = ""       && lo que vio cada tick
	oScope = .NULL.

	*-- Dos tiempos, un tick cada vez: el ACTIVATE WINDOW no se nota hasta que
	*-- VFP vuelve a su bucle, así que nada se hace en el mismo tick que
	*-- el ACTIVATE que lo prepara.
	*--   1. guardar: con el diseñador delante, SYS(1500); si no lo está (otra
	*--      ventana volvió encima), se trae y al tick siguiente;
	*--   2. volver: se trae la ventana que estaba, y se mira al tick siguiente.
	*-- Cinco intentos en cada tiempo como mucho.
	PROCEDURE Timer
		LOCAL lcAfter, loErr
		This.cTrail = This.cTrail + IIF(EMPTY(This.cTrail), "", ", ") + WONTOP()
		IF EMPTY(This.cSaved)
			IF !(UPPER(WONTOP()) == UPPER(This.cDesigner))
				This.nTries = This.nTries + 1
				IF This.nTries < 5
					TRY
						ACTIVATE WINDOW (This.cDesigner)
					CATCH TO loErr
					ENDTRY
					RETURN
				ENDIF
				This.cSaved = "not saved: the designer did not stay in front (" + This.cTrail + ")"
			ELSE
				TRY
					=SYS(1500, "_MFI_SAVE", "_MFILE")
					lcAfter = This.oScope.Stamp(This.cFile)
					This.cSaved = IIF(This.cBefore == lcAfter, "saved, nothing to write", "saved")
				CATCH TO loErr
					This.cSaved = "not saved: " + TRANSFORM(loErr.ErrorNo) + " " + loErr.Message
				ENDTRY
			ENDIF
			This.Back()
			RETURN
		ENDIF
		IF UPPER(WONTOP()) == UPPER(This.cWas) OR EMPTY(This.cWas) OR This.nBack >= 5
			This.Finish()
			RETURN
		ENDIF
		This.Back()
	ENDPROC

	PROTECTED PROCEDURE Back
		LOCAL loErr
		This.nBack = This.nBack + 1
		TRY
			IF !EMPTY(This.cWas)
				ACTIVATE WINDOW (This.cWas)
			ENDIF
		CATCH TO loErr
		ENDTRY
	ENDPROC

	PROTECTED PROCEDURE Finish
		LOCAL loP, loL
		This.Enabled = .F.
		This.cResult = This.cSaved + "; in front again: " + WONTOP()
		*-- El agente no lee foxdock.log: lo que pasó viaja en la respuesta de la
		*-- siguiente llamada a ide_designer_list o ide_designer_save.
		IF VARTYPE(_screen.oFoxDock) == "O"
			loP = _screen.oFoxDock.PluginById("designer")
			IF !ISNULL(loP)
				loL = CREATEOBJECT("Empty")
				ADDPROPERTY(loL, "cFile", This.cFile)
				ADDPROPERTY(loL, "lWritten", This.cSaved == "saved")
				ADDPROPERTY(loL, "nAttempts", This.nTries + 1)
				ADDPROPERTY(loL, "cWhen", TTOC(DATETIME(), 3))
				ADDPROPERTY(loL, "cResult", This.cResult)
				loP.oLastDeferred = loL
			ENDIF
		ENDIF
		IF VARTYPE(_screen.oFoxDock) == "O"
			_screen.oFoxDock.AgentDid(This.cSaved + " " + JUSTFNAME(This.cFile) + " (deferred; in front again: " + WONTOP() + ")")
		ENDIF
	ENDPROC
ENDDEFINE
