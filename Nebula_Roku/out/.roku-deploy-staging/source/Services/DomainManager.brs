function __getDomainManagerState() as Object
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
            _mode: "Primary"
            _jsonMode: "Primary"
            _primaryDns: ""
            _secondaryDns: ""
            _currentConfig: "Primary"
            _fetchInitialConfig: true
            _existSecondary: false
            _currentInitialConfig: "Primary"
        }
    end if

    return m.domainManagerState
end function

function getErrorCodeDemo() As String
    return "SR1-U400-5933"
end function

function getCurrentInitalConfig() As String
    return "P"
end function

function getCode() As String
    return "S"
end function