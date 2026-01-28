function urlHealth(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Health"
end function

function urlClientsHealth(apiUrl)
    return apiUrl + "/v1/health"
end function