function urlTokensUpdate(authUrl)
    return authUrl + "/" + m.global.apiVersions.V1 + "/Tokens/Update"
end function


function urlTokensReAuthenticate(authUrl)
    return authUrl + "/" + m.global.apiVersions.V1 + "/Tokens/ReAuthenticate"
end function

