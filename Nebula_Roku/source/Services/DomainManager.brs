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
            _mode: ConfigMode().PRIMARY
            _primaryDns: ""
            _secondaryDns: ""
            _currentConfig: ConfigMode().PRIMARY
            _fetchInitialConfig: true
            _existSecondary: false
            _currentInitialConfig: ConfigMode().PRIMARY
            _initialConfigStatus: "idle"
            _initialConfigCallback: invalid
            _changeModeStatus: "idle"
            _changeModeCallback: invalid
            _changeModeHealthRequestManager: invalid
            _changeModeDidRefreshConfig: false
        }
    end if

    return m.domainManagerState
end function

sub __finishChangeMode(success as Boolean)
    state = __getDomainManagerState()
    callback = state._changeModeCallback
    state._changeModeStatus = "idle"
    state._changeModeCallback = invalid
    state._changeModeHealthRequestManager = clearApiRequest(state._changeModeHealthRequestManager)
    state._changeModeDidRefreshConfig = false
    __syncDomainManagerState(state)

    if callback <> invalid then
        if callback = "onRetryChangeModeResponse" then
            onRetryChangeModeResponse(success)
        else if m.top <> invalid then
            m.top.callFunc(callback, success)
        end if
    end if
end sub

' Obtiene la base URL de API para servicios.
' Si no viene, usa activeApiUrl y como fallback usa la URL del modo actual.
function getServiceBaseUrl() as String
    state = __getDomainManagerState()
    baseUrl = __getApiUrlForMode(state._mode)
    if baseUrl = invalid then return ""
    return baseUrl
end function

' Obtiene la base URL de API para servicios.
function getBeaconBaseUrl() as String
    state = __getDomainManagerState()
    baseUrl = __getBeaconUrlForMode(state._mode)
    if baseUrl = invalid then return ""
    return baseUrl
end function

' Obtiene la base URL de API para servicios.
function getAuthBaseUrl() as String
    state = __getDomainManagerState()
    baseUrl = __getAuthUrlForMode(state._mode)
    if baseUrl = invalid then return ""
    return baseUrl
end function

sub __requestChangeModeHealth(mode as String, responseHandler as String)
    state = __getDomainManagerState()
    baseUrl = __getApiUrlForMode(mode)
    if baseUrl = invalid or baseUrl = "" then return
    healthUrl = urlHealth(baseUrl)
    state._changeModeHealthRequestManager = sendApiRequest(state._changeModeHealthRequestManager, healthUrl, "GET", responseHandler, invalid, invalid, invalid, true)
    __syncDomainManagerState(state)
end sub

sub __setChangeModeSuccess(mode as String)
    baseUrl = __getApiUrlForMode(mode)
    if baseUrl = invalid or baseUrl = "" then
        __finishChangeMode(false)
        return
    end if

    state = __getDomainManagerState()
    state._mode = mode
    state._currentConfig = mode
    __updateActiveApiUrl(baseUrl)
    __syncDomainManagerState(state)
    __finishChangeMode(true)
end sub

' Sincroniza el estado actual con el global para mantener los valores persistentes.
sub __syncDomainManagerState(state as Object)
    if m.global <> invalid then 
        addAndSetFields(m.global, { domainManagerState: state })
    end if
end sub

' API pública.
sub setConfigUrls(initialConfigUrl as String, secondaryConfigUrl as String)
    addAndSetFields(m.global, { fakeRequest: true })
    ' Guarda las URLs iniciales de configuración (primary/secondary) en el estado.
    state = __getDomainManagerState()
    state.initialConfigPrimaryUrl = initialConfigUrl
    state.initialConfigSecondaryUrl = secondaryConfigUrl
    __syncDomainManagerState(state)
end sub

' Validar si la api funciona llamando al servicio Health y luego reintentar
function __attemptHealthAndRetry(mode as String) as Boolean
    state = __getDomainManagerState()
    state._mode = mode
    state._currentConfig = mode
    __syncDomainManagerState(state)

    if __validateHealthForMode(mode) then
        return true
    end if

    return false
end function

' Obtener la API primaria y secundaria
function __getApiUrlForMode(mode as String) as String
    resource = getResourceByName("ClientsApiUrl")
    if resource = invalid then return ""
    if mode = ConfigMode().PRIMARY then return resource.primary
    if mode = ConfigMode().SECONDARY then return resource.secondary
    return ""
end function

' Obtener la Beacon Url primaria y secundaria
function __getBeaconUrlForMode(mode as String) as String
    resource = getResourceByName("LogsApiUrl")
    if resource = invalid then return ""
    if mode = ConfigMode().PRIMARY then return resource.primary
    if mode = ConfigMode().SECONDARY then return resource.secondary
    return ""
end function

' Obtener la Auth Url primaria y secundaria
function __getAuthUrlForMode(mode as String) as String
    resource = getResourceByName("AuthApiUrl")
    if resource = invalid then return ""
    if mode = ConfigMode().PRIMARY then return resource.primary
    if mode = ConfigMode().SECONDARY then return resource.secondary
    return ""
end function

' Actualizar la API
sub __updateActiveApiUrl(baseUrl as String)
    if baseUrl = invalid or baseUrl = "" then return
    if m.global <> invalid then
        previousApiUrl = m.global.activeApiUrl
        addAndSetFields(m.global, { activeApiUrl: baseUrl })
        updatePendingActionsApiUrl(previousApiUrl, baseUrl)
    end if
end sub

' Validar la API contra el servicio Health
function __validateHealthForMode(mode as String) as Boolean
    baseUrl = __getApiUrlForMode(mode)
    if baseUrl = invalid or baseUrl = "" then return false
    healthUrl = urlHealth(baseUrl)
    success = performHealthCheck(healthUrl)
    if success then __updateActiveApiUrl(baseUrl)
    return success
end function

' Obtener el archivo de configuración Json
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

' Intenta obtener lo archivos de configuración los 2 cdns
function __refreshConfigFromCdns() as Boolean
    state = __getDomainManagerState()
    primaryResponse = __fetchConfigFromUrl(state.initialConfigPrimaryUrl)
    if primaryResponse.success then
        setConfigResponse(primaryResponse.data, ConfigMode().PRIMARY, ConfigMode().PRIMARY)
        state = __getDomainManagerState()
        state._currentInitialConfig = ConfigMode().PRIMARY
        state._fetchInitialConfig = false
        __syncDomainManagerState(state)
        return true
    end if

    secondaryResponse = __fetchConfigFromUrl(state.initialConfigSecondaryUrl)
    if secondaryResponse.success then
        setConfigResponse(secondaryResponse.data, ConfigMode().PRIMARY, ConfigMode().SECONDARY)
        state = __getDomainManagerState()
        state._currentInitialConfig = ConfigMode().SECONDARY
        state._fetchInitialConfig = false
        __syncDomainManagerState(state)
        return true
    end if

    return false
end function

' Notifcar la respuesta de cuando fue a obtener los archivos de configuración
sub __notifyInitialConfigResult(success as Boolean)
    state = __getDomainManagerState()
    if state._initialConfigCallback <> invalid then
        m.top.callFunc(state._initialConfigCallback, { success: success })
        state._initialConfigCallback = invalid
        state._initialConfigStatus = "idle"
    end if

    retryAll()
    __syncDomainManagerState(state)
end sub


' Llama al servicio para obtener el config desde el servidor (JSON) usando el request manager.
function getConfig(cdnRequestManager as Object, url as String, responseHandler as String) as Object
    return sendApiRequest(cdnRequestManager, url, "GET", responseHandler, invalid, invalid, invalid, true)
end function

' Obtiene el JSON inicial desde CDN (Primary/Secondary) y prepara el estado.
function getInitialConfiguration(mode as String, responseHandler = invalid as Dynamic) as Object
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

' Valida si es necesario refrescar el config inicial según el tiempo de refresh.
sub getNeedRefresh()
    state = __getDomainManagerState()
    now = CreateObject("roDateTime")
    now.Mark()
    if now.AsSeconds() >= state._refresh and state._fetchInitialConfig then
        getInitialConfiguration(state._mode)
    end if
end sub

' Esta función se ejecuta cuando alguna api dió error de conexión con el servidor.
' Ahora trabaja de forma asíncrona y notifica resultado en callback.
function changeMode(responseHandler = invalid as Dynamic) as Boolean
    state = __getDomainManagerState()
    'if state._changeModeStatus = "pending" then return false
    state._changeModeStatus = "pending"
    state._changeModeCallback = responseHandler
    state._changeModeDidRefreshConfig = false
    __syncDomainManagerState(state)

    __requestChangeModeHealth(ConfigMode().PRIMARY, "onChangeModeInitialPrimaryHealthResponse")
end function

sub onChangeModeInitialPrimaryHealthResponse()
    state = __getDomainManagerState()
    if state._changeModeHealthRequestManager = invalid then return 
    success = validateStatusCode(state._changeModeHealthRequestManager.statusCode)
    state._changeModeHealthRequestManager = clearApiRequest(state._changeModeHealthRequestManager)
    __syncDomainManagerState(state)

    if success then
        __setChangeModeSuccess(ConfigMode().PRIMARY)
        return
    end if

    __requestChangeModeHealth(ConfigMode().SECONDARY, "onChangeModeInitialSecondaryHealthResponse")
end sub

sub onChangeModeInitialSecondaryHealthResponse()
    state = __getDomainManagerState()
    success = validateStatusCode(state._changeModeHealthRequestManager.statusCode)
    state._changeModeHealthRequestManager = clearApiRequest(state._changeModeHealthRequestManager)
    __syncDomainManagerState(state)

    if success then
        __setChangeModeSuccess(ConfigMode().SECONDARY)
        return
    end if

    'if state._changeModeDidRefreshConfig then
        showCdnErrorDialog()
        '__finishChangeMode(false)
        'return
    'end if

    state._changeModeDidRefreshConfig = true
    __syncDomainManagerState(state)
    getInitialConfiguration(ConfigMode().PRIMARY, "onChangeModeRefreshConfigResponse")
end sub

sub onChangeModeRefreshConfigResponse(result as Object)
    if result = invalid or result.success <> true then
        __finishChangeMode(false)
        return
    end if

    __requestChangeModeHealth(ConfigMode().PRIMARY, "onChangeModeInitialPrimaryHealthResponse")
end sub

sub onChangeModeRefreshPrimaryHealthResponse()
    state = __getDomainManagerState()
    success = validateStatusCode(state._changeModeHealthRequestManager.statusCode)
    state._changeModeHealthRequestManager = clearApiRequest(state._changeModeHealthRequestManager)
    __syncDomainManagerState(state)

    if success then
        __setChangeModeSuccess(ConfigMode().PRIMARY)
        return
    end if

    if not __requestChangeModeHealth(ConfigMode().SECONDARY, "onChangeModeRefreshSecondaryHealthResponse") then
        __finishChangeMode(false)
    end if
end sub

sub onChangeModeRefreshSecondaryHealthResponse()
    state = __getDomainManagerState()
    success = validateStatusCode(state._changeModeHealthRequestManager.statusCode)
    state._changeModeHealthRequestManager = clearApiRequest(state._changeModeHealthRequestManager)
    __syncDomainManagerState(state)

    if success then
        __setChangeModeSuccess(ConfigMode().SECONDARY)
        return
    end if

    __finishChangeMode(false)
end sub

' Llamar a la solicitud http Health
function performHealthCheck(url as String, timeoutMS = 20000 as Integer) as boolean
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
            if validateStatusCode(statusCode) then
                return true
            else 
                setCdnErrorCodeFromStatus(9001, ApiType().CLIENTS_API_URL)
            end if
        end if
    end if

    return false
end function

' Habilita la busqueda de archivos de configuración
sub enableFetchConfigJson()
    ' Esta función se ejecuta cuando algún DNS dio OK, limpia las banderas.
    state = __getDomainManagerState()
    state._fetchInitialConfig = true
    addAndSetFields(m.global, { fakeRequest: true })
    __syncDomainManagerState(state)
end sub

' Obtiene si tiene que guardar los logs de beacon
function getEnableBeaconLogs() as Boolean
    ' Retorna si están habilitados los logs beacon.
    state = __getDomainManagerState()
    return state._enableBeaconLogs
end function

' Obtiene si tiene que guardar los logs
function getEnableLogs() as Boolean
    ' Retorna si están habilitados los logs.
    state = __getDomainManagerState()
    return state._enableLogs
end function

' Obtiene si tiene que buscar los archivos de configuración
function getFetchInitialConfig() as Dynamic
    ' Devuelve si tiene que refrescar el archivo JSON.
    state = __getDomainManagerState()
    return state._fetchInitialConfig
end function

' Obtiene si existe
function existSecondary() as Boolean
    ' Pregunta si alguna variable tiene valor secundario.
    state = __getDomainManagerState()
    return state._existSecondary
end function

' Obtiene el resource desde el listado usando el nombre.
function getResourceByName(name as String) as Object
    state = __getDomainManagerState()
    if state._resources = invalid then return invalid
    for each item in state._resources
        if item <> invalid and item.name = name then return item
    end for
    return invalid
end function

' Retorna el estado del último intento de configuración inicial.
function getInitialConfigStatus() as String
    state = __getDomainManagerState()
    return state._initialConfigStatus
end function

' Procesa la respuesta del CDN primario y en caso de error intenta el secundario.
sub onInitialConfigPrimaryResponse()
    state = __getDomainManagerState()
    if validateStatusCode(state._initialConfigRequestManager.statusCode) then
        response = ParseJson(state._initialConfigRequestManager.response)
        state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
        if response = invalid then
            ' JSON inválido: mapear a PR-100 para CDN (parse error).
            setCdnErrorCodeFromStatus(100, ApiType().CONFIGURATION_URL, "CL")
        else if response.config = invalid or response.resources = invalid then
            ' JSON válido pero sin campos requeridos: mapear a PR-101.
            setCdnErrorCodeFromStatus(101, ApiType().CONFIGURATION_URL, "CL")
        else
            ' JSON correcto: guardar configuración y notificar éxito al terminar de aplicarla.
            setConfigResponse(response, state._mode, ConfigMode().PRIMARY)
            return
        end if
    else
        state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
        state._initialConfigRequestManager = getConfig(state._initialConfigRequestManager, state.initialConfigSecondaryUrl, "onInitialConfigSecondaryResponse")
    end if

    __syncDomainManagerState(state)
end sub

' Procesa la respuesta del CDN secundario si el primario falla.
sub onInitialConfigSecondaryResponse()
    state = __getDomainManagerState()
    if validateStatusCode(state._initialConfigRequestManager.statusCode) then
        response = ParseJson(state._initialConfigRequestManager.response)
        state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
        if response = invalid then
            ' JSON inválido en CDN secundario: mapear a PR-100.
            setCdnErrorCodeFromStatus(100, ApiType().CONFIGURATION_URL, "CL")
            state._initialConfigSuccess = false
            state._initialConfigStatus = "failed"
            __notifyInitialConfigResult(false)
        else if response.config = invalid or response.resources = invalid then
            ' JSON sin campos requeridos en CDN secundario: mapear a PR-101.
            setCdnErrorCodeFromStatus(101, ApiType().CONFIGURATION_URL, "CL")
            state._initialConfigSuccess = false
            state._initialConfigStatus = "failed"
            __notifyInitialConfigResult(false)
        else
            ' JSON correcto en CDN secundario: aplicar modo Secondary y notificar éxito al terminar.
            setConfigResponse(response, state._mode, ConfigMode().SECONDARY)
            return
        end if
    else
        ' Error de status HTTP en CDN secundario: mapear error de red al diálogo CDN.
        setCdnErrorCodeFromStatus(state._initialConfigRequestManager.statusCode, ApiType().CONFIGURATION_URL, "CL")
        state._initialConfigSuccess = false
        state._initialConfigStatus = "failed"
        __notifyInitialConfigResult(false)
    end if

    state._initialConfigRequestManager = clearApiRequest(state._initialConfigRequestManager)
    
    __syncDomainManagerState(state)
end sub

' Setea la respuesta del config en el estado y actualiza el modo actual.
sub setConfigResponse(response as Object, mode as String, configDomain as String)
    state = __getDomainManagerState()
    state._currentConfig = mode
    state._mode = mode
    state._fetchInitialConfig = false
    state._currentInitialConfig = configDomain
    state._initialConfigSuccess = false
    m.setConfigResponseShouldNotifyInitialResult = false
    if state._initialConfigStatus = "pending" then m.setConfigResponseShouldNotifyInitialResult = true

    refreshSeconds = 14400
    if response <> invalid and response.config <> invalid and response.config.refresh_interval_seconds <> invalid then
        refreshSeconds = response.config.refresh_interval_seconds
    end if

    now = CreateObject("roDateTime")
    now.Mark()

    state._code = response.code
    state._refresh = now.AsSeconds() + refreshSeconds * 1000

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
    ' Cancelar una validación anterior y crear la cola para la nueva configuración.
    __clearHiddenImageValidation()
    m.hiddenImageValidationItem = invalid
    checks = []
    m.hiddenImageValidationQueue = []
    for each item in state._resources
        if shouldValidateImageUrl(item) then
            checks.push(item)
        end if
    end for

    for each item in checks
        if item <> invalid and hasUseHttpAction(item) then
            if item.primary <> invalid and getHealthCheckPrimary(item) <> "" then
                __createImageValidation(item, item.primary, getHealthCheckPrimary(item), LCase(ConfigMode().PRIMARY))
            end if

            if item.secondary <> invalid and getHealthCheckSecondary(item) <> "" then
                __createImageValidation(item, item.secondary, getHealthCheckSecondary(item), LCase(ConfigMode().SECONDARY))
            end if
        end if
    end for

    __processNextImageValidation()
end sub

' Marca la configuración como lista únicamente cuando terminó toda validación asíncrona.
sub __finishSetConfigResponse()
    state = __getDomainManagerState()
    state._initialConfigSuccess = true
    state._initialConfigStatus = "success"
    __syncDomainManagerState(state)

    shouldNotifyInitialResult = false
    if m.setConfigResponseShouldNotifyInitialResult = true then shouldNotifyInitialResult = true
    m.setConfigResponseShouldNotifyInitialResult = false
    if shouldNotifyInitialResult then __notifyInitialConfigResult(true)
end sub

sub __createImageValidation(item, resourceUrl as String, imageValidationUri as String, mode as String)
    if item = invalid or resourceUrl = "" or imageValidationUri = "" then return

    if m.hiddenImageValidationQueue = invalid then
        m.hiddenImageValidationQueue = []
    end if

    validationItem = {
        item: item
        resourceUrl: resourceUrl
        imageValidationUri: imageValidationUri,
        mode: mode
    }

    m.hiddenImageValidationQueue.push(validationItem)
end sub

sub __processNextImageValidation()
    if m.hiddenImageValidation <> invalid then return
    if m.hiddenImageValidationQueue = invalid then
        __finishSetConfigResponse()
        return
    end if
    if m.hiddenImageValidationQueue.Count() = 0 then
        __finishSetConfigResponse()
        return
    end if

    validationItem = m.hiddenImageValidationQueue.Shift()
    if validationItem = invalid then
        __processNextImageValidation()
        return
    end if

    m.hiddenImageValidation = CreateObject("roSGNode", "Poster")
    if m.hiddenImageValidation = invalid then
        __processNextImageValidation()
        return
    end if

    m.hiddenImageValidation.visible = false
    m.hiddenImageValidation.opacity = 0.0
    m.hiddenImageValidation.width = 1
    m.hiddenImageValidation.height = 1

    m.hiddenImageValidationItem = validationItem

    m.hiddenImageValidation.observeField("loadStatus", "onHiddenImageValidationLoadStatus")
    m.top.appendChild(m.hiddenImageValidation)
    m.hiddenImageValidation.uri = validationItem.imageValidationUri
end sub

sub __clearHiddenImageValidation()
    if m.hiddenImageValidation <> invalid then
        m.hiddenImageValidation.unobserveField("loadStatus")
        if m.hiddenImageValidation.getParent() <> invalid then
            m.hiddenImageValidation.getParent().removeChild(m.hiddenImageValidation)
        end if
        m.hiddenImageValidation = invalid
    end if
end sub

' Observa el resultado de carga de la imagen del poster lógico.
sub onHiddenImageValidationLoadStatus()
    if m.hiddenImageValidation = invalid then return

    status = m.hiddenImageValidation.loadStatus
    if status <> "ready" and status <> "failed" then return

    validationItem = m.hiddenImageValidationItem

    ' Valida únicamente las fallas para decidir el cambio global de protocolo.
    if status = "failed" and validationItem <> invalid then
        item = validationItem.item ' Recupera el item asociado a la imagen validada.
        if item <> invalid and item.on_failure <> invalid and item.on_failure.actions <> invalid then ' Verifica que existan acciones configuradas.
            for each actionInfo in item.on_failure.actions ' Recorre las acciones declaradas para la falla actual.
                if actionInfo <> invalid and actionInfo.action <> invalid and LCase(actionInfo.action) = "use_http" then ' Busca la acción use_http solicitada.
                    imageProtocolOverride = getOppositeImageProtocol(m.hiddenImageValidation.uri) ' Calcula el protocolo opuesto según la URL actual.
                    if imageProtocolOverride <> invalid then setImageProtocolOverride(item.name, validationItem.resourceUrl, imageProtocolOverride, validationItem.mode) ' Persiste el protocolo a nivel global para futuras imágenes.
                    exit for ' Detiene el recorrido al encontrar la primera acción válida.
                end if
            end for
        end if
    end if

    __clearHiddenImageValidation()
    m.hiddenImageValidationItem = invalid
    __processNextImageValidation()
end sub

' Validar si es una imágen
function shouldValidateImageUrl(item as Object) as Boolean
    if item = invalid then return false

    hasToCheck = false
    if getHealthCheckPrimary(item) <> "" or getHealthCheckSecondary(item) <> "" then
        hasToCheck = true
    end if

    ' Validar que tenga acciones
    if hasToCheck = false then return false
    if item.on_failure = invalid then return false
    if item.on_failure.actions = invalid then return false
    if item.on_failure.actions.Count() = 0 then return false

    ' Validarq ue las acciones sean de http y https
    for each actionInfo in item.on_failure.actions
        if LCase(actionInfo.when) = "tls_error" and LCase(actionInfo.action) = "use_http" then
            return true
        end if
    end for

    return false
end function

' Validar si usa http
function hasUseHttpAction(item as Object) as Boolean
    if item = invalid then return false
    if item.on_failure = invalid then return false
    if item.on_failure.actions = invalid then return false

    for each actionInfo in item.on_failure.actions
        if LCase(actionInfo.action) = "use_http" then
            return true
        end if
    end for

    return false
end function

' Persiste el protocolo de imágenes en el global node.
sub setImageProtocolOverride(variableKey as String, url as String, protocol as Dynamic, mode as String)

    finalUrl = applyImageProtocolOverride(url, protocol)

    setConfigVariable(variableKey, finalUrl, mode)
end sub

' Obtiene el protocolo opuesto para el fallback global de imágenes.
function getOppositeImageProtocol(url as Dynamic) as Dynamic
    if url = invalid then return invalid
    ' Si la URL actual usa HTTPS, cambia el override a HTTP.
    if Left(LCase(url), 8) = "https://" then return "http"
    ' Si la URL actual usa HTTP, cambia el override a HTTPS.
    if Left(LCase(url), 7) = "http://" then return "https"
    return invalid
end function

' Validar si el recurso tiene validación Primaria
function getHealthCheckPrimary(item as Object) as String
    if item = invalid then return ""
    if item.health_check = invalid then return ""
    if type(item.health_check) <> "roAssociativeArray" then return ""
    if item.health_check.target = invalid then return ""
    if item.health_check.target.primary = invalid then return ""
    return item.health_check.target.primary
end function

' Validar si el recurso tiene validación Secundaria
function getHealthCheckSecondary(item as Object) as String
    if item = invalid then return ""
    if item.health_check = invalid then return ""
    if type(item.health_check) <> "roAssociativeArray" then return ""
    if item.health_check.target = invalid then return ""
    if item.health_check.target.secondary = invalid then return ""
    return item.health_check.target.secondary
end function

' Retorna el indicador de configuración actual según el JSON activo.
function getCurrentInitalConfig() As String
    state = __getDomainManagerState()
    if state._currentInitialConfig = ConfigMode().PRIMARY then return "P"
    if state._currentInitialConfig = ConfigMode().SECONDARY then return "S"
    return ""
end function

' Retorna el código actual basado en el modo JSON y el modo activo.
function getCode() As String
    state = __getDomainManagerState()
    modeSuffix = "P"
    if state._mode = ConfigMode().SECONDARY then modeSuffix = "S"
    return state._code + modeSuffix
end function