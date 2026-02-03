' Inicialización del componente (parte del ciclo de vida de Roku)
sub Init()
    m.top.functionName = "GetContent"
    m.top.ObserveField("state", "onchangeStateTask")
end sub

' Obtiene el contexto de la llamada seteando internamente todos lso paramentros para realizarla.
' Es el metodo inicial de la llamada. 
sub GetContent()
    'Obtengo los datos de la llamada
    method = m.top.method
    body = m.top.body
    publicApi = m.top.publicApi

    if method = invalid then method = "GET"
    if body = invalid then body = ""
    
    if publicApi then
        __emitResponse(__apiRequest(m.top.url, method, body, invalid))
    else if m.top.token <> invalid and m.top.token <> ""
        __emitResponse(__apiRequest(m.top.url, method, body, m.top.token))
    else
        accToken = getAccessToken()
        expirationTimeToken = Val(getAccessTokenExpirationDate())
        
        now = CreateObject("roDateTime")
        now.ToLocalTime()

        if now.asSeconds() < expirationTimeToken then
            resp = __apiRequest(m.top.url, method, body, accToken)
            
            if validateStatusCode(resp.statusCode) then
                __emitResponse(resp)
            else
                if resp.statusCode <> 401 then
                    __emitResponse(resp)
                else 
                    newToken = __updateToken(accToken)

                    if validateStatusCode(newToken.statusCode) then
                        tokenResponse = ParseJson(newToken.response)
                        
                        __emitResponse(__apiRequest(m.top.url, method, body, tokenResponse.accessToken))
                    else
                        __emitResponse({resposne:invalid, errorResponse:invalid, statusCode: resp.statusCode})
                    end if
                end if
            end if
        else
            newToken = __updateToken(accToken)

            if validateStatusCode(newToken.statusCode) then
                tokenResponse = ParseJson(newToken.response)

                __emitResponse(__apiRequest(m.top.url, method, body, tokenResponse.accessToken))
            else
                __emitResponse({resposne:invalid, errorResponse:invalid, statusCode: newToken.statusCode})
            end if
        end if 
    end if
end sub

' Defide si la tarea de la llamada debe cancelarse y por consiguiente cancelar la llamada.
sub onchangeStateTask()
    ' Si se cancela la Tarea entocnes cancelo la transferencia
    if m.top.state = "stop" or m.top.state = "done" then
        if m.transfer <> invalid then 
            m.transfer.AsyncCancel()
            m.transfer = invalid
        end if
        m.top.unobserveField("state")
    end if
end sub

' Retorna la respuesta.
sub __emitResponse(response)
    if m.transfer <> invalid then 
        m.transfer.AsyncCancel()
        m.transfer = invalid
    end if

    m.top.response = response.response
    m.top.errorResponse = response.errorResponse
    m.top.statusCode = response.statusCode
end sub

' Realiza una llamada HTTP
function __apiRequest(url, method, body, token)
    response = invalid
    errorResponse = invalid
    statusCode = 0
    serverError = false
    
    ' Crea el objeto roUrlTransfer
    m.transfer = CreateObject("roURLTransfer")
    port = createObject("roMessagePort")

     ' Idioma dinámico según el televisor / lógica de i18n
    lang = "en"
    appLang = getAppLanguage()  ' usa roDeviceInfo internamente
    if appLang <> invalid and appLang <> "" then
        lang = appLang
    end if
    
    m.transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    m.transfer.setPort(port)
    m.transfer.RetainBodyOnError(true)
    m.transfer.AddHeader("Content-Type", "application/json")
    m.transfer.AddHeader("Accept-Language", lang)
    m.transfer.SetURL(url)
    timeoutMS = 20000

    if token <> invalid and token <> "" then m.transfer.AddHeader("Authorization", "Bearer " + token)

    ' Realiza la llamada según el método
    if method = "GET" or method = "DELETE"  then
        m.transfer.SetRequest(method)

        if m.transfer.AsyncGetToString() then
            event = wait(timeoutMS, port)

            If event <> invalid Then
                if type(event) = "roUrlEvent" then                
                    statusCode = event.GetResponseCode()

                    if validateStatusCode(statusCode) then
                        response = event.GetString()
                        errorResponse = invalid
                    else if __validateServerError(event) then
                        printError("SERVER (" + method + "): - " + statusCode.toStr() + " " + url, event.GetFailureReason())
                        errorResponse = event.GetString()
                        serverError = true
                        response = invalid
                    else  
                        printError("API (" + method + "): - " + statusCode.toStr() + " " + url, event.GetFailureReason())
                        errorResponse = event.GetString()
                        response = invalid
                    end if 
                end if 

                return { response: response, errorResponse: errorResponse, statusCode: statusCode, serverError: serverError }
            else
                return { response: invalid, errorResponse: "Error: timed out", statusCode: 408 } 
            end if
        end if
    elseif method = "POST" or method = "PUT" or method = "PATCH" then
        m.transfer.SetRequest(method)

        if m.transfer.AsyncPostFromString(body) then
            event = wait(timeoutMS, port)

            If event <> invalid Then
                if type(event) = "roUrlEvent" then
                    statusCode = event.GetResponseCode()
                    
                    if validateStatusCode(statusCode) then
                        response = event.GetString()
                        errorResponse = invalid
                    else if __validateServerError(event) then
                        printError("SERVER (" + method + "): - " + statusCode.toStr() + " " + url, event.GetFailureReason())
                        errorResponse = event.GetString()
                        response = invalid
                    else 
                        printError("API (" + method + "): - " + statusCode.toStr() + " " + url, event.GetFailureReason())
                        errorResponse = event.GetString()
                        response = invalid
                    end if 

                    return { response: response, errorResponse: errorResponse, statusCode: statusCode, serverError: serverError }
                end if
            else
                return { response: invalid, errorResponse: "Error: timed out", statusCode: 408 } 
            end if
        end if
    else
        printError("HTTP method not supported:", method)
        STOP
    end if
end function

' Se encarga de actualziar el Token de acceso
function __updateToken(accToken) as object
    refToken = getRefreshToken()

    authUrl = getConfigVariable(m.global.configVariablesKeys.AUTH_API_URL)
    tokenBody = FormatJson({accessToken: accToken})
    
    newAuxToken = __apiRequest(urlTokensUpdate(authUrl), "POST", tokenBody, refToken)

    
    if validateStatusCode(newAuxToken.statusCode) then
        respToken = ParseJson(newAuxToken.response)
        saveTokens(respToken)

       return newAuxToken 
    else
        if newAuxToken.statusCode = 401 then 
            return __reAuthenticate(authUrl, accToken, refToken)
        else 
            return { statusCode: newAuxToken.statusCode }
        end if
    end if
end function

' Trata de reloguear al usuario a traves del token de reautenticacion- 
function __reAuthenticate(authUrl, accToken, refToken) as object
    reAuthToken = getReAuthenticateToken()
    device = m.global.device

    tokenBody = FormatJson({
        accessToken: accToken,
        refreshToken: refToken,
        serialNumber: device.serialNumber,
        macEthernet: device.macEthernet,
        macWireless: device.macWireless
    })
    
    newAuxToken = __apiRequest(urlTokensReAuthenticate(authUrl), "POST", tokenBody, reAuthToken)

    
    if validateStatusCode(newAuxToken.statusCode) then
        respToken = ParseJson(newAuxToken.response)
        saveTokens(respToken)

       return newAuxToken 
    else
        if newAuxToken.statusCode = 401 then deleteTokens()

        return { statusCode: newAuxToken.statusCode }
    end if
end function

'Valida si el error fue por error de conexión con el servidor
function __validateServerError(event as object) as boolean

    headers = event.GetResponseHeaders()

    if (__getHeaderValue(headers, "x-service-id")) then
        'El error no fue por no poderse conectar con el servidor, ya que el servidor devuelve en el header el atributo "x-service-id" en sus response
        return false
    else 
        'No se pudo conectar con el servidor
        return true
    end if
end function

' Función que valida que exista el atributo x-service-id en el header
function __getHeaderValue(headers as Object, key as String) as boolean
    if headers = invalid or Type(headers) <> "roAssociativeArray" then return false

    if headers.Count() = 0 then return false

    if not headers.doesexist("x-service-id") then return false

    return true
end function