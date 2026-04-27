function urlHealth(apiUrl = invalid)
    if (apiUrl = invalid) then
        apiUrl = getServiceBaseUrl()
    end if
    return apiUrl + "/"+ m.global.apiVersions.V3 +"/Health"
end function

function urlClientsHealth(baseUrl)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/v1/health"
end function