' DomainManager service state
' Mode: "Primary" | "Secondary"
' IqvResource interface structure:
' {
'   name: string
'   primary: string
'   secondary?: string
'   health_check?: {
'     type: EqvAppConfigType
'     target: {
'       primary: string
'       secondary?: string
'     }
'   }
'   on_failure?: {
'     actions: [ {
'       when: EqvAppConfigWhen
'       action: EqvAppConfigAction
'     } ]
'   }
' }
'

function __getDomainManagerState() as Object
    ' Inicializa y retorna el estado del DomainManager si aún no existe.

    if m.global <> invalid and m.global.domainManagerState <> invalid then
        m.domainManagerState = m.global.domainManagerState
        return m.domainManagerState
    end if

    if m.domainManagerState = invalid then
        m.domainManagerState = {
            initialConfigPrimaryUrl: ""
            initialConfigSecondaryUrl: ""
            _code: ""
            _refresh: 0
            _enableLogs: false
            _enableBeaconLogs: false
            _resources: []
            _HTTP_ERRORS: [
                { status: 0, message: "ERR_NAME_NOT_RESOLVED" }
                { status: 0, message: "ERR_CONNECTION_REFUSED" }
                { status: 0, message: "ERR_CONNECTION_TIMED_OUT" }
                { status: 0, message: "Unknown Error" }
                { status: 0, message: "net::ERR_CERT_*" }
                { status: 0, message: "DNS" }
                { status: 0, message: "timeout" }
                { status: 0, message: "connection refused" }
                { status: 404, message: "Not found" }
                { status: 408, message: "Timeout" }
                { status: 495, message: "SSL Certificate Error" }
                { status: 502, message: "Bad Gateway" }
                { status: 503, message: "Service Unavailable" }
                { status: 504, message: "Gateway Timeout" }
                { status: 521, message: "Web Server Is Down" }
                { status: 523, message: "Origin Is Unreachable" }
            ]
            _initialConfigRequestManager: invalid
            _initialConfigSuccess: false
            _mode: "Primary"
            _jsonMode: "Primary"
            _primaryDns: ""
            _secondaryDns: ""
            _currentConfig: "Primary"
            _fetchInitialConfig: true
            _existSecondary: false
            _currentInitialConfig: "Primary"
            _initialConfigStatus: "idle"
            _initialConfigCallback: invalid
        }
    end if

    return m.domainManagerState
end function

sub __syncDomainManagerState(state as Object)
    ' Sincroniza el estado actual con el global para mantener los valores persistentes.
    if m.global <> invalid then 
        addAndSetFields(m.global, { domainManagerState: state })
    end if
end sub

' API pública (funciones sin prefijo "__").
sub setConfigUrls(initialConfigUrl as String, secondaryConfigUrl as String)
    ' Guarda las URLs iniciales de configuración (primary/secondary) en el estado.
    state = __getDomainManagerState()
    state.initialConfigPrimaryUrl = initialConfigUrl
    state.initialConfigSecondaryUrl = secondaryConfigUrl
    __syncDomainManagerState(state)
end sub

function getConfig(cdnRequestManager as Object, url as String, responseHandler as String) as Object
    ' Llama al servicio para obtener el config desde el servidor (JSON) usando el request manager.
    return sendApiRequest(cdnRequestManager, url, "GET", responseHandler, invalid, invalid, true)
end function

function getInitialConfiguration(mode as String, responseHandler = invalid as Dynamic) as Object
    ' Obtiene el JSON inicial desde CDN (Primary/Secondary) y prepara el estado.
    state = __getDomainManagerState()
    state._mode = mode
    state._initialConfigStatus = "pending"
    state._fetchInitialConfig = false
    state._initialConfigCallback = responseHandler
    if m.global <> invalid then
        'addAndSetFields(m.global, { domainManagerInitStatus: "pending" })
    end if
    state._initialConfigRequestManager = getConfig(state._initialConfigRequestManager, state.initialConfigPrimaryUrl, "onInitialConfigPrimaryResponse")
    __syncDomainManagerState(state)
    return state._initialConfigRequestManager
end function

sub getNeedRefresh()
    ' Valida si es necesario refrescar el config inicial según el tiempo de refresh.
    state = __getDomainManagerState()
    now = CreateObject("roDateTime")
    now.Mark()
    if (now.AsSeconds() * 1000) >= state._refresh and state._fetchInitialConfig then
        getInitialConfiguration(state._mode)
    end if
end sub

function changeMode() as Boolean
    ' Cambiar de Primario a Secundario solo cuando el error sea de DNS.
    state = __getDomainManagerState()

    if state._mode = "Primary" then
        if __attemptHealthAndRetry("Secondary") then return true
    end if

    state = __getDomainManagerState()
    if state._mode = "Secondary" then
        if state._jsonMode = "Primary" then
            state._jsonMode = "Secondary"
            __syncDomainManagerState(state)

            if __attemptHealthAndRetry("Primary") then return true
            if __attemptHealthAndRetry("Secondary") then return true
        end if
    end if

    state = __getDomainManagerState()
    if state._mode = "Secondary" and state._jsonMode = "Secondary" then
        state._jsonMode = "Primary"
        state._mode = "Primary"
        state._currentConfig = "Primary"
        __syncDomainManagerState(state)

        if __refreshConfigFromCdns() then
            if __attemptHealthAndRetry("Primary") then return true
            if __attemptHealthAndRetry("Secondary") then return true
        end if
    end if

    return false
end function

function __attemptHealthAndRetry(mode as String) as Boolean
    state = __getDomainManagerState()
    state._mode = mode
    state._currentConfig = mode
    __syncDomainManagerState(state)

    if __validateHealthForMode(mode) then
        return executePendingActions()
    end if

    return false
end function

function __getApiUrlForMode(mode as String) as String
    resource = getResourceByName("ClientsApiUrl")
    if resource = invalid then return ""
    if mode = "Primary" then return resource.primary
    if mode = "Secondary" then return resource.secondary
    return ""
end function

sub __updateActiveApiUrl(baseUrl as String)
    if baseUrl = invalid or baseUrl = "" then return
    if m.global <> invalid then
        previousApiUrl = m.global.activeApiUrl
        addAndSetFields(m.global, { activeApiUrl: baseUrl })
        updatePendingActionsApiUrl(previousApiUrl, baseUrl)
    end if
end sub

function __validateHealthForMode(mode as String) as Boolean
    baseUrl = __getApiUrlForMode(mode)
    if baseUrl = invalid or baseUrl = "" then return false
    healthUrl = urlClientsHealth(baseUrl)
    success = performHealthCheck(healthUrl)
    if success then __updateActiveApiUrl(baseUrl)
    return success
end function

function performHealthCheck(url as String, timeoutMS = 20000 as Integer) as Boolean
    if url = invalid or url = "" then return false
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    if transfer = invalid or port = invalid then return false
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetPort(port)
    transfer.RetainBodyOnError(true)
    transfer.AddHeader("Content-Type", "application/json")
    lang = getAppLanguage()
    if lang <> invalid and lang <> "" then
        transfer.AddHeader("Accept-Language", lang)
    end if
    transfer.SetURL(url)

    if transfer.AsyncGetToString() then
        event = wait(timeoutMS, port)
        if event <> invalid and type(event) = "roUrlEvent" then
            statusCode = event.GetResponseCode()
            return validateStatusCode(statusCode)
        end if
    end if

    return false
end function

function __fetchConfigFromUrl(url as String, timeoutMS = 20000 as Integer) as Object
    response = { success: false, data: invalid }
    if url = invalid or url = "" then return response

    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    if transfer = invalid or port = invalid then return response
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.SetPort(port)
    transfer.RetainBodyOnError(true)
    transfer.AddHeader("Content-Type", "application/json")
    transfer.SetURL(url)

    if transfer.AsyncGetToString() then
        event = wait(timeoutMS, port)
        if event <> invalid and type(event) = "roUrlEvent" then
            statusCode = event.GetResponseCode()
            if validateStatusCode(statusCode) then
                payload = event.GetString()
                if payload <> invalid then
                    response.data = ParseJson(payload)
                    response.success = response.data <> invalid
                end if
            end if
        end if
    end if

    return response
end function

function __refreshConfigFromCdns() as Boolean
    state = __getDomainManagerState()
    primaryResponse = __fetchConfigFromUrl(state.initialConfigPrimaryUrl)
    if primaryResponse.success then
        setConfigResponse(primaryResponse.data, "Primary")
        state = __getDomainManagerState()
        state._jsonMode = "Primary"
        state._currentInitialConfig = "Primary"
        __syncDomainManagerState(state)
        return true
    end if

    secondaryResponse = __fetchConfigFromUrl(state.initialConfigSecondaryUrl)
    if secondaryResponse.success then
        setConfigResponse(secondaryResponse.data, "Primary")
        state = __getDomainManagerState()
        state._jsonMode = "Secondary"
        state._currentInitialConfig = "Secondary"
        state._fetchInitialConfig = false
        __syncDomainManagerState(state)
        return true
    end if

    return false
end function

sub enableFetchConfigJson()
    ' Esta función se ejecuta cuando algún DNS dio OK, limpia las banderas.
    state = __getDomainManagerState()
    state._fetchInitialConfig = true
    __syncDomainManagerState(state)
end sub

sub restartConfiguration()
    ' Indica que se tiene que volver a buscar el JSON y volver a setear el modo en Primario.
    state = __getDomainManagerState()
    state._mode = "Primary"
    state._fetchInitialConfig = true
    state._initialConfigStatus = "idle"
    __syncDomainManagerState(state)
end sub

function getEnableBeaconLogs() as Boolean
    ' Retorna si están habilitados los logs beacon.
    state = __getDomainManagerState()
    return state._enableBeaconLogs
end function

function getEnableLogs() as Boolean
    ' Retorna si están habilitados los logs.
    state = __getDomainManagerState()
    return state._enableLogs
end function

function getFetchInitialConfig() as Dynamic
    ' Devuelve si tiene que refrescar el archivo JSON.
    state = __getDomainManagerState()
    return state._fetchInitialConfig
end function

function existSecondary() as Boolean
    ' Pregunta si alguna variable tiene valor secundario.
    state = __getDomainManagerState()
    return state._existSecondary
end function

function getVariable(key as String) as String
    ' Obtener las URLs de las APIs a partir de los resources.
    state = __getDomainManagerState()
    if state._resources <> invalid then
        for each item in state._resources
            if item <> invalid and item.name = key then
                if state._mode = "Primary" or item.secondary = invalid then
                    return item.primary
                else
                    return item.secondary
                end if
            end if
        end for
    end if

    return ""
end function

function getResourceByName(name as String) as Object
    ' Obtiene el resource desde el listado usando el nombre.
    state = __getDomainManagerState()
    if state._resources = invalid then return invalid
    for each item in state._resources
        if item <> invalid and item.name = name then return item
    end for
    return invalid
end function

function getInitialConfigStatus() as String
    ' Retorna el estado del último intento de configuración inicial.
    state = __getDomainManagerState()
    return state._initialConfigStatus
end function

sub __notifyInitialConfigResult(success as Boolean)
    state = __getDomainManagerState()
    if state._initialConfigCallback <> invalid then
        m.top.callFunc(state._initialConfigCallback, { success: success })
        state._initialConfigCallback = invalid
    end if
    __syncDomainManagerState(state)
end sub

function validateErrorDNS(status as Integer, message as String) as Boolean
    ' Valida si el error corresponde a un problema de DNS comparando el catálogo HTTP.
    state = __getDomainManagerState()
    if message = invalid then return false
    normalized = LCase(message)
    if state._HTTP_ERRORS = invalid then return false
    for each item in state._HTTP_ERRORS
        if item <> invalid and item.status = status then
            if InStr(1, normalized, LCase(item.message)) > 0 then return true
        end if
    end for
    return false
end function

sub onInitialConfigPrimaryResponse()
    ' Procesa la respuesta del CDN primario y en caso de error intenta el secundario.
    state = __getDomainManagerState()
    if validateStatusCode(state._initialConfigRequestManager.statusCode) then
        response = ParseJson(state._initialConfigRequestManager.response)
        state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
        if response <> invalid then
            setConfigResponse(response, state._mode)
            __notifyInitialConfigResult(true)
            return
        end if
    end if

    state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
    state._initialConfigRequestManager = getConfig(state._initialConfigRequestManager, state.initialConfigSecondaryUrl, "onInitialConfigSecondaryResponse")
end sub

sub onInitialConfigSecondaryResponse()
    ' Procesa la respuesta del CDN secundario si el primario falla.
    state = __getDomainManagerState()
    if validateStatusCode(state._initialConfigRequestManager.statusCode) then
        response = ParseJson(state._initialConfigRequestManager.response)
        state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
        if response <> invalid then
            state._jsonMode = "Secondary"
            setConfigResponse(response, state._mode)
            state._fetchInitialConfig = false
            state._currentInitialConfig = "Secondary"
            state._initialConfigSuccess = true
            state._initialConfigStatus = "success"
            __notifyInitialConfigResult(true)
            __syncDomainManagerState(state)
            return
        end if
    end if

    state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
    state._initialConfigSuccess = false
    state._initialConfigStatus = "failed"
    __notifyInitialConfigResult(false)
    __syncDomainManagerState(state)
end sub

sub setConfigResponse(response as Object, mode as String)
    ' Setea la respuesta del config en el estado y actualiza el modo actual.
    state = __getDomainManagerState()
    state._currentConfig = mode
    state._jsonMode = "Primary"
    state._fetchInitialConfig = false
    state._currentInitialConfig = "Primary"
    state._initialConfigSuccess = true
    state._initialConfigStatus = "success"

    refreshSeconds = 14400
    if response <> invalid and response.config <> invalid and response.config.refresh_interval_seconds <> invalid then
        refreshSeconds = response.config.refresh_interval_seconds
    end if

    now = CreateObject("roDateTime")
    now.Mark()

    state._code = response.code
    state._refresh = (now.AsSeconds() * 1000) + (refreshSeconds * 1000)

    if response <> invalid and response.config <> invalid and response.config.enable_action_log <> invalid then
        state._enableLogs = response.config.enable_action_log
    else
        state._enableLogs = true
    end if

    if response <> invalid and response.config <> invalid and response.config.enable_beacon <> invalid then
        state._enableBeaconLogs = response.config.enable_beacon
    else
        state._enableBeaconLogs = state._enableLogs
    end if

    if response <> invalid and response.resources <> invalid then
        state._resources = response.resources
    else
        state._resources = []
    end if

    state._existSecondary = false
    if state._resources <> invalid then
        for each item in state._resources
            if item <> invalid and item.secondary <> invalid then
                state._existSecondary = true
                exit for
            end if
        end for
    end if

    __syncDomainManagerState(state)
end sub

function getErrorCodeDemo() As String
    ' Retorna un código de error de ejemplo para diálogos/placeholder.
    return "SR1-U400-5933"
end function

function getCurrentInitalConfig() As String
    ' Retorna el indicador de configuración actual según el JSON activo.
    state = __getDomainManagerState()
    if state._currentInitialConfig = "Primary" then return "P"
    if state._currentInitialConfig = "Secondary" then return "S"
    return ""
end function

function getCode() As String
    ' Retorna el código actual basado en el modo JSON y el modo activo.
    state = __getDomainManagerState()
    jsonPrefix = "P"
    if state._jsonMode = "Secondary" then jsonPrefix = "S"
    modeSuffix = "P"
    if state._mode = "Secondary" then modeSuffix = "S"
    return jsonPrefix + "/" + state._code + modeSuffix
end function