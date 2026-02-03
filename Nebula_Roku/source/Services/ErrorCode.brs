' ******************************************************************************************************************************************
'    El formato general del código de error será:
'                 CC-XXX
'     CC = (categoría, 2 letras):
'         NW → Network: errores de red o conexión.
'         BE → Backend: errores de backend o API.
'             En caso de que a su vez tenga un codigo de error interno etonces se concatena
'                 BE-[Status]-[ErrorCode]
'         CL → Cliente “aplicación”.
'             Para errores propios de la app: UI, modulos, assets faltantes, errores de inicialización.
'         PR → Parsing/Read: lectura de datos
'             Para errores de lectura/parseo de archivos JSON, CSV, XML, configs, o respuestas de server que no cumplen schema esperado.
'     XXX = número (mínimo 3 dígitos; puede usar 4+ cuando convenga) para representar el Error
'     AUX = (opcional) se añade al final: CC-XXX-AUX (ej: NW-408-CDN1)
' ******************************************************************************************************************************************

' Define los formatos de error a mostrar en pantalla para que sea visible al usuario final.
function UiErrorCategory() as Object
    return {
        NETWORK_CATEGORY: "NW"
        PARSING_READ_CATEGORY: "PR"
        CLIENT_CATEGORY: "CL"
        SERVER_RESPONSE_CATEGORY: "SR"
        UNEXPECTED: "U"
        API_ID: "[ApiId]"
    }
end function

function ApiType() as Object
    return {
        CONFIGURATION_URL: "0"
        CLIENTS_API_URL: "1"
        AUTH_API_URL: "2"
        LOGS_API_URL: "3"
        COMPANION_APP_HUB_URL: "4"
        WEB_API_URL: "5"
        CLIENT_WEB_URL: "6"
    }
end function

function UiErrorCodeManager() as Object
    return {
        NW_SSL_CERTIFICATE_ERROR: NW_SSL_CERTIFICATE_ERROR
        NW_REQUEST_TIMEOUT: NW_REQUEST_TIMEOUT
        NW_BAD_GATEWAY: NW_BAD_GATEWAY
        NW_SERVICE_UNAVAILABLE: NW_SERVICE_UNAVAILABLE
        NW_CONNECTION_REFUSED: NW_CONNECTION_REFUSED
        NW_DOMAIN_UNAVAILABLE: NW_DOMAIN_UNAVAILABLE
        NW_INITIAL_CONFIG_ERROR: NW_INITIAL_CONFIG_ERROR
        NW_BACKEND_UNAVAILABLE: NW_BACKEND_UNAVAILABLE
        NW_NOT_FOUND: NW_NOT_FOUND
        CL_NOT_FOUND: CL_NOT_FOUND
        PR_PARSE_JSON_ERROR: PR_PARSE_JSON_ERROR
        PR_MISSING_REQUIRED_DATA_ERROR: PR_MISSING_REQUIRED_DATA_ERROR
        CL_MODULE_ERROR_NOT_FOUND: CL_MODULE_ERROR_NOT_FOUND
        CL_MODULE_ERROR_CONNECTION_REFUSED: CL_MODULE_ERROR_CONNECTION_REFUSED
        CL_MODULE_ERROR_UNAVAILABLE: CL_MODULE_ERROR_UNAVAILABLE
    }
end function

function __formatUiErrorCode(category as String, apiTypeParam as Dynamic, code as String) as String
    apiId = apiTypeParam
    if apiId = invalid then apiId = ""
    return category + apiId + "-" + code
end function

function NW_SSL_CERTIFICATE_ERROR(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "495")
end function

function NW_REQUEST_TIMEOUT(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "408")
end function

function NW_BAD_GATEWAY(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "502")
end function

function NW_SERVICE_UNAVAILABLE(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "503")
end function

function NW_CONNECTION_REFUSED(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "521")
end function

function NW_DOMAIN_UNAVAILABLE(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "523")
end function

function NW_INITIAL_CONFIG_ERROR(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "9000")
end function

function NW_BACKEND_UNAVAILABLE(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "9001")
end function

function NW_NOT_FOUND(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().NETWORK_CATEGORY, apiTypeParam, "404")
end function

function CL_NOT_FOUND(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().CLIENT_CATEGORY, apiTypeParam, "404")
end function

function PR_PARSE_JSON_ERROR(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().PARSING_READ_CATEGORY, apiTypeParam, "100")
end function

function PR_MISSING_REQUIRED_DATA_ERROR(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().PARSING_READ_CATEGORY, apiTypeParam, "101")
end function

function CL_MODULE_ERROR_NOT_FOUND(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().CLIENT_CATEGORY, apiTypeParam, "404")
end function

function CL_MODULE_ERROR_CONNECTION_REFUSED(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().CLIENT_CATEGORY, apiTypeParam, "521")
end function

function CL_MODULE_ERROR_UNAVAILABLE(apiTypeParam as Dynamic) as String
    return __formatUiErrorCode(UiErrorCategory().CLIENT_CATEGORY, apiTypeParam, "523")
end function