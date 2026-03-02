
function urlAuthRegenerateSession(apiUrl)
    return apiUrl + "/" + m.global.apiVersions.V2 + "/Auth/RegenerateSession"
end function

function urlAuthCredentialsLogin(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Auth/CredentialsLogin"
end function

function urlAuthProfile(apiUrl, profileId)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Auth/Profile/" + profileId.ToStr()
end function

