

' Máximo de acciones pendientes en memoria para evitar crecimiento indefinido.
function __maxPendingActions() as Integer
    return 15
end function

' Obtener todas las actions las peticiones http
function __getPendingActions(status = "all") as Object
    actions = []

    if m.pendingActions = invalid then
        m.pendingActions = []
    end if
    actions = m.pendingActions

    errorActions = []
    for each item in actions
        if item <> invalid and item.action <> invalid and (item.action.status = status or status = "all")  then
            errorActions.push(item)
        end if
    end for

    return errorActions
end function

' Setear las actions que fallaron las peticiones http por problemas del servidor
sub __setPendingActions(actions as Object)
    if actions = invalid then actions = []
    m.pendingActions = __normalizePendingActions(actions)
end sub

' Limpia entradas inválidas y limita el tamaño del historial en memoria.
function __normalizePendingActions(actions as Object) as Object
    if actions = invalid then return []

    sanitized = []
    for each item in actions
        if item <> invalid and item.action <> invalid and item.action.run <> invalid then
            sanitized.push(item)
        end if
    end for

    maxActions = __maxPendingActions()
    count = sanitized.count()
    if count <= maxActions then return sanitized

    trimmed = []
    ' Al exceder el límite, conserva las más recientes y descarta las más viejas.
    startIndex = count - maxActions
    for i = startIndex to count - 1
        trimmed.push(sanitized[i])
    end for

    return trimmed
end function

' Obtiene el valor de un header de http response
function __getHeaderValue(headers as Object, key as String) as Dynamic
    ' Obtiene un header desde un objeto compatible (map o con método get).
    if headers = invalid then return invalid
    if headers.get <> invalid then return headers.get(key)
    if headers.DoesExist(key) then return headers[key]
    return invalid
end function

' Registra todas las acciones que se vayan ejecutando en un historial
sub __registerPendingAction(requestId, action as Object)
    if action = invalid or action.run = invalid then return
    actions = __getPendingActions()
    ' Validar que la misma acción no este registrada
    newActions = []
    for each item in actions
        if item <> invalid and item.action <> invalid and item.action.responseMethod <> action.responseMethod and item.action.run <> invalid then 
            newActions.push(item)
        end if
    end for    
    ' Registrar la nueva acción
    newActions.push({ id: requestId, action: action })
    __setPendingActions(newActions)
end sub

' Remover las acciones que quedaron pendientes por request id
sub removePendingAction(requestId as String)
    if requestId = invalid or requestId = "" then return
    remaining = []
    for each item in __getPendingActions()
        if item <> invalid and item.id <> requestId then
            remaining.push(item)
        end if
    end for
    m.pendingActions = remaining
end sub

' Cambiar el estado de una acción pendiente
sub changeStatusAction(requestId as String, status as String)
    if requestId = invalid or requestId = "" then return
    pendingActions = __getPendingActions()
    remaining = []
    for each item in pendingActions
        if item <> invalid and item.id = requestId then
            item.action.status = status
        end if
    end for
    __setPendingActions(pendingActions)
end sub


' Ejecuta una acción y espera un resultado con { success, error }.
function __runAction(action as Object) as Object
    result = { success: false, error: invalid }
    if action = invalid or action.run = invalid then return result
    
    response = action.run()
    if response <> invalid then
        if response.success <> invalid then result.success = response.success
        if response.error <> invalid then result.error = response.error
    end if
    return result
end function

sub setCdnErrorCodeFromStatus(statusCode as Integer, apiTypeParam as Dynamic, category = "NW" as string )
    ' Traduce un statusCode de red/CDN a un código de error visible en el diálogo CDN.
    ' Usa el apiTypeParam para inyectar el identificador [A] en el código (p.ej. NW[A]-408).
    ' Este método solo actualiza el diálogo global si está disponible.
    if m.global = invalid or m.global.cdnErrorDialog = invalid then return
    uiError = UiErrorCodeManager()
    if statusCode = 408 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_REQUEST_TIMEOUT(apiTypeParam)
    else if statusCode = 495 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_SSL_CERTIFICATE_ERROR(apiTypeParam)
    else if statusCode = 502 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_BAD_GATEWAY(apiTypeParam)
    else if statusCode = 503 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_SERVICE_UNAVAILABLE(apiTypeParam)
    else if statusCode = 521 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_CONNECTION_REFUSED(apiTypeParam)
    else if statusCode = 523 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_DOMAIN_UNAVAILABLE(apiTypeParam)
    else if statusCode = 9000 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_INITIAL_CONFIG_ERROR(apiTypeParam)
    else if statusCode = 9001 then
        m.global.cdnErrorDialog.errorCode = uiError.NW_BACKEND_UNAVAILABLE(apiTypeParam)
    else if statusCode = 100 then
        m.global.cdnErrorDialog.errorCode = uiError.PR_PARSE_JSON_ERROR(apiTypeParam)
    else if statusCode = 101 then
        m.global.cdnErrorDialog.errorCode = uiError.PR_MISSING_REQUIRED_DATA_ERROR(apiTypeParam)
    else if statusCode = 404 then
        if (category = "NW") then
            m.global.cdnErrorDialog.errorCode = uiError.NW_NOT_FOUND(apiTypeParam)
        else if category = "CL"
            m.global.cdnErrorDialog.errorCode = uiError.CL_NOT_FOUND(apiTypeParam)
        end if
    else 
        m.global.cdnErrorDialog.errorCode = uiError.NW_NOT_FOUND(apiTypeParam)
    end if
end sub

' Traduce errores al obtener módulos del cliente (CL) a códigos visibles en el diálogo CDN.
' Soporta 404/521/523 para diferenciar módulo no encontrado, conexión rechazada y no disponible.
' Usa el apiTypeParam para definir el identificador [A] del servicio.
sub setClientModuleErrorCodeFromStatus(statusCode as Integer, apiTypeParam as Dynamic)
    if m.global = invalid or m.global.cdnErrorDialog = invalid then return
    uiError = UiErrorCodeManager()
    if statusCode = 404 then
        m.global.cdnErrorDialog.errorCode = uiError.CL_MODULE_ERROR_NOT_FOUND(apiTypeParam)
    else if statusCode = 521 then
        m.global.cdnErrorDialog.errorCode = uiError.CL_MODULE_ERROR_CONNECTION_REFUSED(apiTypeParam)
    else if statusCode = 523 then
        m.global.cdnErrorDialog.errorCode = uiError.CL_MODULE_ERROR_UNAVAILABLE(apiTypeParam)
    end if
end sub

' Limpia todas las solicitudes http que se haya realizado
sub clear()
    ' Limpia las funciones de la cola.
    __setPendingActions([])
end sub

' Intenta todas las funciones que quedaron pendientes con el status error
sub retryAll()

    addAndSetFields(m.global, { fakeRequest: false })
    actions = __getPendingActions("error")

    wasEmpty = actions = invalid or actions.count() = 0
    if not wasEmpty then
        response = changeMode()
        if response then
            for each item in actions
                if item <> invalid and item.action <> invalid then
                    result = __runAction(item.action)
                    if result.success = true then
                        item.action.status = "success"
                    else
                        item.action.status = "error"
                    end if
                end if
            end for
        else 
            showCdnErrorDialog()
        end if

        ' Mantener solo errores pendientes para liberar memoria de acciones resueltas.
        __setPendingActions(__getPendingActions("error"))
    end if
end sub

' Ejecuta llamadas HTTP con failover y reconfiguración si es necesario.
sub runAction(requestId, httpRequest as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean)
    ' Ejecuta llamadas HTTP con failover y reconfiguración si es necesario.
    httpRequest.status = "running"
    __registerPendingAction(requestId, httpRequest)
    result = __runAction(httpRequest)
end sub

sub updatePendingActionsApiUrl(previousApiUrl as Dynamic, nextApiUrl as Dynamic)
    if previousApiUrl = invalid or previousApiUrl = "" then return
    if nextApiUrl = invalid or nextApiUrl = "" then return
    if previousApiUrl = nextApiUrl then return
    actions = __getPendingActions()
    if actions = invalid then return
    for each item in actions
        if item <> invalid and item.action <> invalid then
            __updateActionUrl(item.action, previousApiUrl, nextApiUrl)
        end if
    end for

    __setPendingActions(actions)
end sub

sub __updateActionUrl(action as Object, previousApiUrl as String, nextApiUrl as String)
    if action = invalid then return
    if action.url <> invalid and InStr(1, action.url, previousApiUrl) > 0 then
        action.url = action.url.Replace(previousApiUrl, nextApiUrl).Replace("https", "https")
    end if
end sub