function urlTokensUpdate()
    baseUrl = getAuthBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V1 + "/Tokens/Update"
end function

function urlTokensReAuthenticate()
    baseUrl = getAuthBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V1 + "/Tokens/ReAuthenticate"
end function

