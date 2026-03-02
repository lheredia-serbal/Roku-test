' ErrorManager service
function parseError(error as Object, apiTypeParam as Dynamic) as String
    ' Retorna el mensaje de error según el status HTTP.
    statusText = ""
    uiError = UiErrorCodeManager()

    if error <> invalid and error.status <> invalid then
        if error.status = 495 then
            statusText = uiError.NW_SSL_CERTIFICATE_ERROR(apiTypeParam)
        else if error.status = 408 then
            statusText = uiError.NW_REQUEST_TIMEOUT(apiTypeParam)
        else if error.status = 502 then
            statusText = uiError.NW_BAD_GATEWAY(apiTypeParam)
        else if error.status = 503 then
            statusText = uiError.NW_SERVICE_UNAVAILABLE(apiTypeParam)
        else if error.status = 521 then
            statusText = uiError.NW_CONNECTION_REFUSED(apiTypeParam)
        else if error.status = 523 then
            statusText = uiError.NW_DOMAIN_UNAVAILABLE(apiTypeParam)
        else if error.status = 404 then
            statusText = uiError.NW_NOT_FOUND(apiTypeParam)
        else if error.status = 100 then
            statusText = uiError.PR_PARSE_JSON_ERROR(apiTypeParam)
        else if error.status = 101 then
            statusText = uiError.PR_MISSING_REQUIRED_DATA_ERROR(apiTypeParam)
        else if error.status = 9000 then
            statusText = uiError.NW_INITIAL_CONFIG_ERROR(apiTypeParam)
        else
            statusText = uiError.NW_BACKEND_UNAVAILABLE(apiTypeParam)
        end if
    else
        statusText = uiError.NW_BACKEND_UNAVAILABLE(apiTypeParam)
    end if

    return statusText
end function

function isValidJson(str as String) as Boolean
    ' Valida que el formato JSON sea correcto.
    if str = invalid or str = "" then return false
    parsed = ParseJson(str)
    return parsed <> invalid
end function