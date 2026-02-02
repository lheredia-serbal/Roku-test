' RetryService service state
function __getRetryServiceState() as Object
    ' Inicializa y retorna el estado del RetryService si aún no existe.
    if m.retryServiceState = invalid then
        m.retryServiceState = {
            pendingActions: []
            errorVisibleSubject: false
            _reconfigInProgress: invalid
            _changeModeInProgress: false
        }
    end if

    return m.retryServiceState
end function

function __getHeaderValue(headers as Object, key as String) as Dynamic
    ' Obtiene un header desde un objeto compatible (map o con método get).
    if headers = invalid then return invalid
    if headers.get <> invalid then return headers.get(key)
    if headers.DoesExist(key) then return headers[key]
    return invalid
end function

function __ensureRequestId(action as Object) as String
    if action = invalid then return ""
    if action.requestId = invalid or action.requestId = "" then
        now = CreateObject("roDateTime")
        action.requestId = now.AsSeconds().toStr() + "-" + now.GetMilliseconds().toStr()
    end if
    return action.requestId
end function

function __registerPendingAction(action as Object) as String
    if action = invalid then return ""
    state = __getRetryServiceState()
    requestId = __ensureRequestId(action)
    if requestId = "" then return ""
    for each item in state.pendingActions
        if item <> invalid and item.id = requestId then return requestId
    end for
    state.pendingActions.push({ id: requestId, action: action })
    __syncRetryState(state)
    return requestId
end function

sub __removePendingAction(requestId as String)
    if requestId = invalid or requestId = "" then return
    state = __getRetryServiceState()
    remaining = []
    for each item in state.pendingActions
        if item <> invalid and item.id <> requestId then
            remaining.push(item)
        end if
    end for
    state.pendingActions = remaining
    __syncRetryState(state)
end sub

function __getActionStatusCode(action as Object, error as Object) as Integer
    statusCode = invalid
    if action <> invalid and action.apiRequestManager <> invalid then
        statusCode = action.apiRequestManager.statusCode
    end if
    if statusCode = invalid or statusCode = 0 then
        if error <> invalid and error.status <> invalid then
            statusCode = error.status
        else if error <> invalid and error.error <> invalid and error.error.code <> invalid then
            statusCode = error.error.code
        end if
    end if
    if statusCode = invalid then statusCode = 0
    return statusCode
end function

sub __maybeRemovePendingAction(action as Object, error as Object)
    if action = invalid then return
    requestId = action.requestId
    if requestId = invalid or requestId = "" then return
    statusCode = __getActionStatusCode(action, error)
    if statusCode <> 9000 then
        __removePendingAction(requestId)
    end if
end sub

function __runRetryAction(action as Object) as Object
    ' Ejecuta una acción y espera un resultado con { success, error }.
    result = { success: false, error: invalid }
    if action = invalid then return result
    if action.run <> invalid then
        response = action.run()
        if response <> invalid then
            if response.success <> invalid then result.success = response.success
            if response.error <> invalid then result.error = response.error
        end if
    end if
        if result.success and result.error = invalid and action.apiRequestManager <> invalid then
        statusCode = action.apiRequestManager.statusCode
        errorResponse = action.apiRequestManager.errorResponse
        if statusCode = 0 and errorResponse = invalid then
            statusCode = __waitForStatusCode(action.apiRequestManager)
            errorResponse = action.apiRequestManager.errorResponse
        end if
        if (statusCode <> invalid and statusCode <> 0 and not validateStatusCode(statusCode)) or (errorResponse <> invalid and errorResponse <> "") then
            result.success = false
            statusText = ""
            if errorResponse <> invalid then statusText = errorResponse
            result.error = { status: statusCode, statusText: statusText }
        end if
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

    serviceId = __getHeaderValue(error.headers, "X-Service-Id")
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

sub clear()
    ' Limpia las funciones de la cola.
    state = __getRetryServiceState()
    state.pendingActions = []
    state.errorVisibleSubject = false
end sub

function tryRetryFromResponse(action as Object, apiRequestManager as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean) as Boolean

    if action = invalid then return false

    state = __getRetryServiceState()
    wasEmpty = state.pendingActions = invalid or state.pendingActions.count() = 0
    __registerPendingAction(action)

    if wasEmpty and not state._changeModeInProgress then
        state._changeModeInProgress = true
        __syncRetryState(state)
        changeModeResult = changeMode()
        state = __getRetryServiceState()
        state._changeModeInProgress = false
        __syncRetryState(state)
        return changeModeResult
    end if

    return true
end function

sub retryAll()
    ' Intenta todas las funciones que quedaron pendientes.
    state = __getRetryServiceState()
    actions = state.pendingActions
    for each item in actions
        if item <> invalid and item.action <> invalid then
            result = __runRetryAction(item.action)
            __maybeRemovePendingAction(item.action, result.error)
        end if
    end for
end sub

function executeWithRetry(httpRequest as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean) as Object
    ' Ejecuta llamadas HTTP con failover y reconfiguración si es necesario.
    state = __getRetryServiceState()
    __registerPendingAction(httpRequest)
    result = __runRetryAction(httpRequest)
    __maybeRemovePendingAction(httpRequest, result.error)
    if result.success then return result

    error = result.error

    if not existSecondary() then
        error = setErrorApi(error, apiTypeParam)
        return { success: false, error: error }
    end if

    finalResult = __runRetryAction(httpRequest)
    __maybeRemovePendingAction(httpRequest, finalResult.error)
    if finalResult.success then return finalResult

    finalError = finalResult.error
    if validateErrorDNS(finalError.status, finalError.statusText) and getFetchInitialConfig() and executeFailover then
        if state._reconfigInProgress = invalid then
            state._reconfigInProgress = true
            getInitialConfiguration("Primary")
            state._reconfigInProgress = invalid
        end if

        return executeWithRetry(httpRequest, apiTypeParam, false)
    end if

    finalError = setErrorApi(finalError, apiTypeParam)
    return { success: false, error: finalError }
end function

function executePendingActions() as Boolean
    ' Ejecuta las funciones pendientes en orden y mantiene las que fallan.
    state = __getRetryServiceState()
    allSuccessful = true
    actions = state.pendingActions
    for each item in actions
        if item <> invalid and item.action <> invalid then
            result = __runRetryAction(item.action)
            __maybeRemovePendingAction(item.action, result.error)
            if not result.success then
                statusCode = __getActionStatusCode(item.action, result.error)
                if statusCode = 9000 then allSuccessful = false
            end if
        end if
    end for
    state = __getRetryServiceState()
    state.errorVisibleSubject = state.pendingActions.count() > 0
    __syncRetryState(state)
    return allSuccessful
end function

sub updatePendingActionsApiUrl(previousApiUrl as Dynamic, nextApiUrl as Dynamic)
    if previousApiUrl = invalid or previousApiUrl = "" then return
    if nextApiUrl = invalid or nextApiUrl = "" then return
    if previousApiUrl = nextApiUrl then return
    state = __getRetryServiceState()
    if state.pendingActions = invalid then return
    for each item in state.pendingActions
        if item <> invalid and item.action <> invalid then
            __updateActionUrl(item.action, previousApiUrl, nextApiUrl)
        end if
    end for
    __syncRetryState(state)
end sub

sub __updateActionUrl(action as Object, previousApiUrl as String, nextApiUrl as String)
    if action = invalid then return
    if action.url <> invalid and InStr(1, action.url, previousApiUrl) > 0 then
        action.url = action.url.Replace(previousApiUrl, nextApiUrl).Replace("1https", "https")
    end if
end sub

function __validateCurrentApiHealth() as Boolean
    apiUrl = getActiveApiUrl()
    if apiUrl = invalid or apiUrl = "" then return false
    healthUrl = urlClientsHealth(apiUrl)
    return performHealthCheck(healthUrl)
end function

sub __syncRetryState(state as Object)
    ' Sincroniza el estado actual con el global para mantener los valores persistentes.
    if m.global <> invalid then 
        addAndSetFields(m.global, { retryServiceState: state })
    end if
end sub