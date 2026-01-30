' RetryService service state
function __getRetryServiceState() as Object
    ' Inicializa y retorna el estado del RetryService si aún no existe.
    if m.retryServiceState = invalid then
        m.retryServiceState = {
            failedActions: []
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

function __hasPending() as Boolean
    ' Valida que exista aunque sea una función pendiente de ejecutar.
    state = __getRetryServiceState()
    return state.failedActions <> invalid and state.failedActions.count() > 0
end function

sub clear()
    ' Limpia las funciones de la cola.
    state = __getRetryServiceState()
    state.failedActions = []
    state.errorVisibleSubject = false
end sub

function tryRetryFromResponse(action as Object, apiRequestManager as Object, searchUrl as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean) as Boolean

    if action = invalid then return false

    if __validateCurrentApiHealth() then
        result = __runRetryAction(action)
        return result.success
    end if

    state = __getRetryServiceState()
    wasEmpty = state.failedActions = invalid or state.failedActions.count() = 0
    __register(action)

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

sub __register(action as Object)
    ' Guarda las funciones en cola cuando fallan las peticiones por API.
    if action = invalid then return
    state = __getRetryServiceState()
    exists = false
    for each item in state.failedActions
        if item = action then
            exists = true
            exit for
        end if
    end for
    if not exists then
        state.failedActions.push(action)
        state.errorVisibleSubject = true
    end if

    __syncRetryState(state)
end sub

sub retryAll()
    ' Intenta todas las funciones que quedaron pendientes.
    state = __getRetryServiceState()
    remaining = []
    for each action in state.failedActions
        if action <> invalid then
            success = true
            if action.run <> invalid then
                result = action.run()
                if result = invalid then success = false
            else
                success = false
            end if

            if not success then remaining.push(action)
        end if
    end for
    state.failedActions = remaining
end sub

function executeWithRetry(httpRequest as Object, searchUrl as Object, apiTypeParam as Dynamic, executeFailover = true as Boolean) as Object
    ' Ejecuta llamadas HTTP con failover y reconfiguración si es necesario.
    state = __getRetryServiceState()
    searchUrl.run()
    result = __runRetryAction(httpRequest)
    if result.success then return result

    error = result.error

    if not existSecondary() then
        error = setErrorApi(error, apiTypeParam)
        return { success: false, error: error }
    end if

    if searchUrl <> invalid and searchUrl.run <> invalid then searchUrl.run()

    finalResult = __runRetryAction(httpRequest)
    if finalResult.success then return finalResult

    finalError = finalResult.error
    if validateErrorDNS(finalError.status, finalError.statusText) and getFetchInitialConfig() and executeFailover then
        if state._reconfigInProgress = invalid then
            state._reconfigInProgress = true
            getInitialConfiguration("Primary")
            state._reconfigInProgress = invalid
        end if

        if searchUrl <> invalid and searchUrl.run <> invalid then searchUrl.run()
        return executeWithRetry(httpRequest, searchUrl, apiTypeParam, false)
    end if

    finalError = setErrorApi(finalError, apiTypeParam)
    return { success: false, error: finalError }
end function
function executePendingActions() as Boolean
    ' Ejecuta las funciones pendientes en orden y mantiene las que fallan.
    state = __getRetryServiceState()
    remaining = []
    allSuccessful = true
    for each action in state.failedActions
        if action <> invalid then
            result = __runRetryAction(action)
            if not result.success then
                remaining.push(action)
                allSuccessful = false
            end if
        end if
    end for
    state.failedActions = remaining
    state.errorVisibleSubject = remaining.count() > 0
    __syncRetryState(state)
    return allSuccessful
end function

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