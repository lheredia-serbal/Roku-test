
function urlAuthRegenerateSession()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/Auth/RegenerateSession"
end function

function urlAuthCredentialsLogin()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 + "/Auth/CredentialsLogin"
end function

function urlAuthProfile(profileId)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 + "/Auth/Profile/" + profileId.ToStr()
end function

function urlRegisterCode()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/Auth/RegisterCodeLogin"
end function
