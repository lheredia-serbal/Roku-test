
' Función para obtener la versión de la aplicación
function getVersion() as string
    appInfo = CreateObject("roAppInfo")
    return appInfo.GetVersion() ' Obtiene la versión definida en el manifest
end function

' Función para obtener la versión de la aplicación
function getVersionCode() as float
    version = GetVersion().split(".")
    versionCode = Val(version[0]) * 1000 + Val(version[1]) * 10 + Val(version[2])
    return versionCode
end function

' Se encarga de añadir objetos al entorno global. Si la propiedad existe la pisa con el nuevo valor. 
' Si la propiedad no existe entocnes la agrega.  
sub addAndSetFields(node, asosiativeArray)
    addFields = {}
    setFields = {}
    for each field in asosiativeArray
      if node.hasField( field )
        setFields[ field ] = asosiativeArray[ field ]
      else
        addFields[ field ] = asosiativeArray[ field ]
      end if
    end for
    
    node.setFields( setFields )
    node.addFields( addFields )
end sub

' Borra del entorno global todos los objetos de las claves que estén en la lista enviada por parametro.
' Si se incluye la plalabra espacial "PrivateVariables" entre las Key, entonces elimina las Variables privadas en el arreglo de varaibles. 
sub removeFields(node, keysToRemove)
    for each key in keysToRemove
        if key = "PrivateVariables" then
            ' Si existe el campo variables y es un Array
            if node.hasField("variables") and node.variables <> invalid  and node.variables.count() > 0 then
                vars = node.variables
                filteredVars = []
                ' Recorremos cada elemento del arreglo
                for each item in vars
                    ' Sólo añadimos los que NO sean de scope "Private"
                    if item.scope <> invalid and item.scope <> "Private" then
                        filteredVars.push(item)
                    end if
                end for
                ' Sobrescribimos el arreglo completo con los no-privados
                node.setFields({ variables: filteredVars })
            end if
        else if node.hasField(key) then
            ' Eliminamos el campo por completo
            node.removeField(key)
        end if
    end for
end sub

' Funcion encargada de validar si una peticion HTTP respondio notificacondo que pudo completar la accion.
' Valida que el Status Code este entre el resultado 2XX 
function valdiateStatusCode(statusCode as integer) as boolean
    return statusCode >= 200 and statusCode < 300
end function

' Obtiene las variables de configuracion del global
function getConfigVariable(variable as String) as Dynamic
    __setInitialValues()
    if m.global.variables <> invalid
        for each item in m.global.variables
            if item["variable"] = variable then
                return item["value"]
            end if
        next
    else 
        printError("Error: The parameter 'array' is not a valid array.")
        return invalid
    end if

    ' Si no se encuentra, devolver invalid
    return invalid
end function

' Obtiene y retorna en formato numerico el valor especifico de una la variable de configuracion del las
' configuraciones obtenidas desde el back, si no la encuentra retorna el valor por defecto.
' variable Clave a buscar en las variables de configuracion (EqvAppConfigVariable)
' defaultValue Valor por defecto en caso de no encontrarla.
function getIntValueConfigVariable(key as string, defaultValue as integer) as integer

    value = getConfigVariable(key)

    if value <> invalid
        return Int(value)
    else 
        return defaultValue
    end if  
end function

' Genera la url de la imagen
function getImageUrl(image, defautlValue = invalid) as Dynamic
    if image = invalid then return defautlValue
    __setInitialValues()

    if image <> invalid and image.rootVariable <> invalid and getConfigVariable(image.rootVariable) <> invalid then
        return getConfigVariable(image.rootVariable) + image.relativePath
    else if image.relativePath <> invalid and image.rootVariable = invalid
        return image.relativePath
    else 
        return defautlValue
    end if
end function

' Metodo encargado de cancelar la peticion y limpiar el escuchador de la respuesta
' apiRequestManager: Variable donde esta guardado el Task de la llamada.
function clearApiRequest(apiRequestManager)
    if apiRequestManager <> invalid then
        apiRequestManager.unobserveField("statusCode")
        apiRequestManager.control = "STOP"
        apiRequestManager = invalid
    end if
    return apiRequestManager
end function

' Metodo encargado de disparar el Task que maneja las peticiones HTTP. Recibe por parametro:
' apiRequestManager: Variable donde se guardara el Task.
' url: Direcion a donde realizara la llamada.
' method: Metodo a realizar (GET / POST / PUT / DELETE / PATCH).
' responseMethod: Funcion a llamar al terminar la peticion.
' body: Cuerpo a enviar en la peticion. Debe enviarse como un string. Por defecto es vacio.
' token: Token a enviar, si se setea entocnes anula el Token de la aplicacion. Por defecto es vacio.
' publicApi: Si la llamada debe realizarse con Token, si se setea en False entonces valida que el token de la aplciaicon sea valido antes de llamar. Por defecto es False
' dataAux: Informacion adicional que necestio que el objeto concerve para cuando vuelva la respuesta 
function sendApiRequest(apiRequestManager, url, method, responseMethod, body = invalid, token = invalid, publicApi = false, dataAux = invalid)
  apiRequestManager = clearApiRequest(apiRequestManager)
  apiRequestManager = CreateObject("roSGNode", "APIRequestManager")
  apiRequestManager.setField("url", url)
  apiRequestManager.setField("method", method)
  if publicApi then apiRequestManager.setField("publicApi", true)
  if body <> invalid and body <> "" then  apiRequestManager.setField("body", body) 
  if token <> invalid and token <> "" then  apiRequestManager.setField("token", token) 
  if dataAux <> invalid and dataAux <> "" then  apiRequestManager.setField("dataAux", dataAux) 
  apiRequestManager.ObserveField("statusCode", responseMethod)
  apiRequestManager.control = "RUN"
  return apiRequestManager
end function

' Metodo encargado de unir dos AssociativeArrays, pisando las propiedades del basico con las del particular siempre que estas se llamen igual.
' Si el AssociativeArrays basico no tiene una propiedad que el particular si posee entonces esta se ignarora al generar el AssociativeArrays resultante de la union
function mergeAssociativeArrays(basic as Object, special as Object)
    general = {} ' Objeto resultado
    for each key in basic
        general[key] = basic[key]
    end for

    for each key in special
        general[key] = special[key]
    end for

    return general
end function

' Imprime en consola el error ocurrido con el siguiente formato "{{Date: log}} Error: {{message}} {{error}}". 
' Por defecto el paramentro error se concidera "" si no se define 
sub printError(message, error = "")
    print __dateByLog(); " Error: "; message; " "; error
end sub

' Imprime en consola mensajes de logueo con el siguiente formato "{{Date: log}} LOG: {{message}}". 
' Por defecto el paramentro error se concidera "" si no se define 
sub printLog(message)
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    print __dateByLog(); " LOG: "; message
end sub

' Crea un modal generico moestrnado la info enviada por parametro. Por defecto se crea solo con el boton "OK" 
function createAndShowDialog(screen, title as String, message as String, method as string, buttons = ["OK"])
  dialog = createObject("roSGNode", "StandardMessageDialog")
  dialog.palette = createPaletteDialog()
  dialog.title = title
  dialog.message = [message]
  dialog.buttons = buttons ' Asegúrate de agregar al menos un botón
  dialog.observeField("buttonSelected", method)

  ' Agregar el diálogo a la escena
  screen.appendChild(dialog)

  ' Mostrar el diálogo
  dialog.setFocus(true)
  dialog.visible = true
  return dialog
end function

' Crea el modal para el control parental
function createAndShowPINDialog(screen, title as string,  method, buttons = [])
  pinDialog = createObject("roSGNode", "StandardPinPadDialog")
  pinDialog.palette = createPaletteDialog()
  pinDialog.title = title
  pinDialog.buttons =buttons
  pinDialog.observeField("buttonSelected", method)

  ' Agregar el diálogo a la escena
  screen.appendChild(pinDialog)

  ' Mostrar el diálogo
  pinDialog.setFocus(true)
  pinDialog.visible = true

  return pinDialog
end function

' Limipia las variables del modal y retornan la respuesta. Se debe asignar la variable del modal con invalid 
' para que sea limpiado por el garbage collection 
function clearDialogAndGetOption(screen, dialog)
  option = dialog.buttonSelected

  dialog.visible = false
  dialog.unobserveField("buttonSelected")
  screen.removeChild(dialog)
  
  return option
end function

' Limipia las variables del modal de Control parental y retornan la respuesta. Se debe asignar la variable del 
' modal con invalid para que sea limpiado por el garbage collection 
function clearPINDialogAndGetOption(screen, dialog)
    option = dialog.buttonSelected
    pin = dialog.pin

    dialog.visible = false
    dialog.unobserveField("buttonSelected")
    screen.removeChild(m.dialog)

  return {option: option, pin: pin}
end function

' Valida si el error debe disparar un logout, de ser asi dispara el Logout en la pantalla si es que este tiene la propeidad
function validateLogout(statusCode, screen = invalid)
  if statusCode = 401 then
    if screen <> invalid and screen.logout <> invalid then screen.logout = true
    return true
  end if

  return false 
end function

function beaconTokenExpired() as boolean

    now = CreateObject("roDateTime")
    now.ToLocalTime()

    if m.global.beaconTokenExpiresIn <> invalid and now.asSeconds() < m.global.beaconTokenExpiresIn then
        return false
    else 
        return true
    end if

end function

function getActionLog(actionLog as object) as object

    ' Equivalente a: actionLog.InitialConfigCode = this.domainManager.getCode();

    actionLog.InitialConfigCode =  "P"' m.domainManager.getCode()

    if actionLog.actionCode = "Debug" then
        ' Rama DEBUG (comentada en tu TypeScript)
        ' Podés dejarla vacía si aún no la usás.
        ' Ejemplo de cómo podrías usarla más adelante:
        ' if message <> invalid then
        '     actionLog.message = message
        ' end if
        ' if contact <> invalid then
        '     actionLog.contact = contact
        ' end if
        ' if device <> invalid then
        '     actionLog.device = device
        ' end if
        ' ' etc...
    else
        ' Rama ERROR / NORMAL (curso normal)

        'const session = this.sqvConfigVariableService.session ...
        session = {
            contact: m.global.contact,
            device: m.global.device,
            organization: m.global.organization
        }

        if session = invalid then
            return invalid
        end if

        if session.contact <> invalid then
            actionLog.contact = session.contact
        else
            actionLog.contact = invalid
        end if

        if session.device <> invalid then
            actionLog.device = session.device
        else
            actionLog.device = invalid
        end if
    end if

    return actionLog
end function

function saveActionLogError(actionLog as object)  as object
    actionLog.actionCode = "Error"

    if actionLog.error <> invalid and actionLog.error.location = invalid and actionLog.pageUrl <> invalid  then
        actionLog.error.location = actionLog.pageUrl
    end if

    if actionLog.error <> invalid and actionLog.error.title = invalid and actionLog.error.message <> invalid then
        actionLog.error.title = actionLog.error.message
    end if

    return actionLog

end function

' Crea un ActionLog a partir de un log existente + datos opcionales
' Equivalente a createLogError de TypeScript
function CreateLogError(errorMessage as string, pageUrl as string, errorServer = invalid as object, key = invalid as string, id = invalid as integer, actionLog = invalid as object, program = invalid as object) as object

    ' Si viene un actionLog, partimos de él. Si no, creamos uno vacío.
    log = actionLog
    if log = invalid then
        log = {}
    end if

    ' La lógica del TS con { campo, ...actionLogAux }
    ' hace que NUNCA se pisen campos ya existentes.
    ' Así que solo seteamos si el campo NO existe todavía.

    ' objectDescription <- errorMessage
    if errorMessage <> invalid and errorMessage <> "" then
        if not log.doesExist("objectDescription") then
            log.objectDescription = errorMessage
        end if
    end if

    ' pageUrl
    if pageUrl <> invalid and pageUrl <> "" then
        if not log.doesExist("pageUrl") then
            log.pageUrl = pageUrl
        end if
    end if

    ' error (errorServer)
    if errorServer <> invalid then
        if not log.doesExist("error") then
            log.error = errorServer
        end if
    end if

    ' objectKey (key)
    if key <> invalid and key <> "" then
        if not log.doesExist("objectKey") then
            log.objectKey = key
        end if
    end if

    ' objectId (id)
    ' En TS usan "if (!!id)", así que si id = 0 lo toman como falso.
    if id <> invalid and id <> 0 then
        if not log.doesExist("objectId") then
            log.objectId = id
        end if
    end if

    ' program
    if program <> invalid then
        if not log.doesExist("program") then
            log.program = program
        end if
    end if

    return log
end function

' Genera la descripción del lugar donde ocurrió el error.
function GenerateErrorPageUrl(method as dynamic, activity as dynamic) as dynamic
    pageUrlAux = invalid

    if activity <> invalid and activity <> "" then
        pageUrlAux = activity
    end if

    if pageUrlAux <> invalid and method <> invalid and method <> "" then
        pageUrlAux = pageUrlAux + " - " + method
    else
        pageUrlAux = method
    end if

    return pageUrlAux
end function

' Genera la descripción del error anexando información extra.
function GenerateErrorDescription(errorResponse as dynamic, description = invalid as dynamic) as dynamic
    descriptionAux = invalid

    if errorResponse <> invalid then
        ' Tiene campo error (APIError)
        if errorResponse.error <> invalid then
            err = errorResponse.error

            ' status
            if err.status <> invalid and err.status <> 0 then
                descriptionAux = StrI(err.status)
                descriptionAux = StrI(descriptionAux).trim()
            end if

            ' code
            if descriptionAux <> invalid and err.code <> invalid and err.code <> 0 then
                codeStr = StrI(err.code).trim()
                descriptionAux = descriptionAux + " - " + codeStr
            else if err.code <> invalid and err.code <> 0 then
                descriptionAux = StrI(err.code).trim()
            end if

            ' message o title
            if err.message <> invalid and err.message <> "" then
                if descriptionAux <> invalid then
                    descriptionAux = descriptionAux + " " + err.message
                else
                    descriptionAux = err.message
                end if
            else if err.title <> invalid and err.title <> "" then
                if descriptionAux <> invalid then
                    descriptionAux = descriptionAux + " " + err.title
                else
                    descriptionAux = err.title
                end if
            end if

            ' descripción extra
            if description <> invalid and description <> "" then
                if descriptionAux <> invalid then
                    descriptionAux = descriptionAux + " " + description
                else
                    descriptionAux = description
                end if
            end if

        ' NO tiene campo error: usar status, message, statusText
        else
            if errorResponse.status <> invalid and errorResponse.status <> 0 then
                descriptionAux = StrI(errorResponse.status).trim()
            end if

            if errorResponse.message <> invalid and errorResponse.message <> "" then
                if descriptionAux <> invalid then
                    descriptionAux = descriptionAux + " " + errorResponse.message
                else
                    descriptionAux = errorResponse.message
                end if
            else if errorResponse.statusText <> invalid and errorResponse.statusText <> "" then
                if descriptionAux <> invalid then
                    descriptionAux = descriptionAux + " " + errorResponse.statusText
                else
                    descriptionAux = errorResponse.statusText
                end if
            end if

            ' descripción extra
            if description <> invalid and description <> "" then
                if descriptionAux <> invalid then
                    descriptionAux = descriptionAux + " " + description
                else
                    descriptionAux = description
                end if
            end if
        end if

    ' errorResponse null/invalid → usar solo description
    else
        descriptionAux = description
    end if

    return descriptionAux
end function


' Genera la pila de errores (APIError) a partir de un CqvHttpErrorResponse.
function GetServerErrorStack(errorResponse as dynamic) as dynamic
    if errorResponse <> invalid and errorResponse.error <> invalid then
        ' let apiError = { detail: JSON.stringify(errorResponse), ...errorResponse.error }
        ' En TS, el spread final puede pisar detail; acá preservamos detail si ya existe.
        apiError = errorResponse.error

        if not apiError.doesExist("detail") then
            apiError.detail = FormatJson(errorResponse)
        end if

        return apiError

    else if errorResponse <> invalid and errorResponse.error = invalid then
        ' Construir APIError desde campos sueltos
        apiError = {}

        if errorResponse.status <> invalid and errorResponse.status <> 0 then
            apiError.status = errorResponse.status
        end if

        if errorResponse.message <> invalid and errorResponse.message <> "" then
            apiError.message = errorResponse.message
        end if

        if errorResponse.statusText <> invalid and errorResponse.statusText <> "" then
            apiError.title = errorResponse.statusText
        end if

        apiError.detail = FormatJson(errorResponse)

        return apiError
    end if

    return invalid
end function

' Detiene y limpia el Timer pasado por parametro.
sub clearTimer(timer)
    if timer <> invalid then
        timer.control = "stop"
        timer.unobserveField("fire")
    end if
end sub

' Se encarga de entregar la imagen de error. La priemra vez que se llama crea el arreglo, guarda en una variable global el arreglo 
' y cual es la imagen que devolvio para actualizarla en posteriores usos
function getImageError()
    __setInitialValues()
    if m.global.drawableIds <> invalid and m.global.drawableIds.count() > 0 then
        randomIndex = m.global.drawableIdsPosition + 1
        if randomIndex = m.global.drawableIds.count() then randomIndex = 0
        m.global.drawableIdsPosition = randomIndex
        return m.global.drawableIds[m.global.drawableIdsPosition]
    else
        drawableIds = [
            "pkg:/images/shared/show_image_empty_1.jpg", 
            "pkg:/images/shared/show_image_empty_2.jpg", 
            "pkg:/images/shared/show_image_empty_3.jpg", 
            "pkg:/images/shared/show_image_empty_4.jpg"
        ]
            
        addAndSetFields(m.global, {drawableIdsPosition: 0, drawableIds: drawableIds} )
        
        return drawableIds[0]
    end if
end function

' Función para generar el array de targetRects dinámicamente
function createTargetRects(numItems as integer, inicial as integer, spacing as integer, width as integer, height as integer, moveIn = "InX") as Object
    if moveIn = "InX" then 
        return __createTargetRectsInX(numItems, inicial, spacing, width, height)
    else if moveIn = "InY"
        return __createTargetRectsInY(numItems, inicial, spacing, width, height)
    end if 
end function

' Define la paleta de colores para los Dialog para que todos se vean esteticamente igual. 
function createPaletteDialog()
    palette = createObject("roSGNode", "RSGPalette")
    palette.colors = { 
        DialogBackgroundColor:    "0x2C2C2CFF",   ' gris oscuro
        DialogFocusItemColor:     "0x2C2C2CFF",   ' gris oscuro
        DialogTextColor:          "0xFFFFFFFF",   ' blanco
        DialogFocusColor:         "0xFFFFFFFF",   ' blanco
        DialogSecondaryItemColor: "0xFFFFFFFF"    ' blanco
    }
    return palette
end function

' Función para generar el array de targetRects dinámicamente para desplazamiento en Y
function __createTargetRectsInY(numItems as integer, yInicial as integer, spacing as integer, width as integer, height as integer) as Object
    rects = []
    for i = 0 to numItems
        rect = { x: 0, y: yInicial + i * spacing, width: width, height: height }
        rects.push(rect)
    end for
    return rects
end function

' Función para generar el array de targetRects dinámicamente para desplazamiento en X
function __createTargetRectsInX(numItems as integer, xInicial as integer, spacing as integer, width as integer, height as integer) as Object
  rects = []

  for i = 0 to numItems
    rect = { x: xInicial + i * spacing, y: 0, width: width, height: height }
    rects.push(rect)
  end for
  return rects
end function

' Metodo privado. Genera el global ya que fuera de los componentes es necesario crearlo para usarlo. es un auxiliar.
sub __setInitialValues()
    if m.global = invalid then
        screen = CreateObject("roSGScreen") 
        m.port = CreateObject("roMessagePort")  
        screen.setMessagePort(m.port) 
        m.global = screen.getGlobalNode()  
        m.global.id = "GlobalNode"
    end if
end sub

function __dateByLog() 
    now = CreateObject("roDateTime")
    now.ToLocalTime()

    month = now.GetMonth()
    days = now.GetDayOfMonth()
    hours = now.GetHours()
    minutes = now.GetMinutes()
    seconds = now.GetSeconds()
    milliseconds = now.GetMilliseconds()

    return  __compValue(month) + "-" + __compValue(days) + " " + __compValue(hours) + ":" + __compValue(minutes) + ":" + __compValue(seconds) + "." + __compValue(milliseconds, 3)
end function 

' Metodo privado. Completa el numero para que tenga el formato XX, 
' y lo devuelve en formato string 
function __compValue(value, numberOfDigits = 2) as string
    if (value = invalid) then value = 0

    strValue = value.toStr()
    digitsToPad = numberOfDigits - len(strValue)

    if digitsToPad > 0 then
        padding = string(digitsToPad, "0")
        return padding + strValue
    else
        return strValue
    end if
end function