' RetryService service state
function __getRetryServiceState() as Object
    ' Inicializa y retorna el estado del RetryService si aún no existe.
    if m.retryServiceState = invalid then
        m.retryServiceState = {
            errorVisibleSubject: false
            _reconfigInProgress: invalid
            _changeModeInProgress: false
        }
    end if

    __getPendingActions()
    return m.retryServiceState
end function

' Obtener todas las actions que fallaron las peticiones http por problemas del servidor
function __getPendingActions(status = "all") as Object
    actions = []

    if m.global <> invalid then
        if m.global.pendingActions = invalid then
            addAndSetFields(m.global, { pendingActions: [] })
        end if
        actions = m.global.pendingActions
    else
        if m.pendingActions = invalid then
            m.pendingActions = []
        end if
        actions = m.pendingActions
    end if

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

    if m.global <> invalid then
        addAndSetFields(m.global, { pendingActions: actions })
    else
        m.pendingActions = actions
    end if
end sub

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
    if action = invalid and action.run <> invalid and action.responseMethod = "onProgramSummaryResponse" then return
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
    state = __getRetryServiceState()
    remaining = []
    for each item in __getPendingActions()
        if item <> invalid and item.id <> requestId and item.action.status = "running" then
            remaining.push(item)
        end if
    end for
    state.pendingActions = remaining
    __syncRetryState(state)
end sub

' Cambiar el estado de una acción pendiente
sub changeStatusAction(requestId as String, status as String)
    if requestId = invalid or requestId = "" then return
    pendingActions = __getPendingActions()
    remaining = []
    for each item in pendingActions
        if item <> invalid and item.id = requestId and item.action.status = "running" then
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

function __waitForStatusCode(apiRequestManager as Object, timeoutMS = 20000 as Integer) as Integer
    if apiRequestManager = invalid then return 0
    port = CreateObject("roMessagePort")
    apiRequestManager.ObserveField("statusCode", port)
    event = wait(timeoutMS, port)
    if event = invalid then return apiRequestManager.statusCode
    return apiRequestManager.statusCode
end function

' API pública (funciones sin prefijo "__").
function setErrorApi(error as Object, apiTypeParam as Dynamic) as Object
    ' Setea el código de error 9000 cuando es un error DNS sin X-Service-Id.
    if error = invalid then return error

    serviceId = __getHeaderValue(error.headers, "x-Service-Id")
    statusText = ""
    if error.statusText <> invalid then statusText = error.statusText

    if serviceId = invalid and validateErrorDNS(error.status, statusText) then
        if error.error <> invalid then
            error.error.code = 9000
            error.error.message = parseError(error, apiTypeParam)
        else
            error.error = {
                code: 9000
                message: parseError(error, apiTypeParam)
            }
        end if
    end if

    return error
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
    end if
end sub

sub setClientModuleErrorCodeFromStatus(statusCode as Integer, apiTypeParam as Dynamic)
    ' Traduce errores al obtener módulos del cliente (CL) a códigos visibles en el diálogo CDN.
    ' Soporta 404/521/523 para diferenciar módulo no encontrado, conexión rechazada y no disponible.
    ' Usa el apiTypeParam para definir el identificador [A] del servicio.
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
sub clear()
    ' Limpia las funciones de la cola.
    __setPendingActions([])
end sub

function tryRetryFromResponse(requestId, action as Object, apiRequestManager as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean) as Boolean

    if action = invalid then return false

    state = __getRetryServiceState()
    pendingActions = __getPendingActions("error")
    wasEmpty = pendingActions = invalid or pendingActions.count() = 0
    __registerPendingAction(requestId, action)

    if wasEmpty and not state._changeModeInProgress then
        state._changeModeInProgress = true
        changeModeResult = changeMode()
        state = __getRetryServiceState()
        state._changeModeInProgress = false
        __syncRetryState(state)
        return changeModeResult
    end if

    return true
end function

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
                end if
            end for
        else 
            showCdnErrorDialog()
        end if
    end if
end sub

' Obtener todas las acciones que dieron error
function __getErrorActions(actions as Object) as Object

    if actions = invalid return []

    actionsError = []

    for each item in actions
        if item <> invalid and item.action <> invalid and item.action.status = "error"
            actionsError.push(item)
        end if
    end for

    return actionsError
end function

sub runAction(requestId, httpRequest as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean)
    ' Ejecuta llamadas HTTP con failover y reconfiguración si es necesario.
    httpRequest.status = "running"
    __registerPendingAction(requestId, httpRequest)
    result = __runAction(httpRequest)
end sub

function executePendingActions() as Boolean
    ' Ejecuta las funciones pendientes en orden y mantiene las que fallan.
    allSuccessful = true
    actions = __getPendingActions()
    for each item in actions
        if item <> invalid and item.action <> invalid then
            result = __runAction(item.action)
            if not result.success then
                statusCode = 0
                if statusCode = 9000 then allSuccessful = false
            end if
        end if
    end for
    return allSuccessful
end function

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

sub __syncRetryState(state as Object)
    ' Sincroniza el estado actual con el global para mantener los valores persistentes.
    if m.global <> invalid then 
        addAndSetFields(m.global, { retryServiceState: state })
    end if
end sub