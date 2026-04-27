function urlActionLogs()
    baseUrl = getBeaconBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V1 + "/ActionsLog"
end function

function urlActionLogsToken()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 + "/ActionsLog"
end function