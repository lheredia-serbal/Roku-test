function urlPlatformsVariables(appCode, versionCode, signed = true)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Platforms/Variables?c=" + appCode + "&v=" + versionCode.ToStr() + "&gp=" + signed.ToStr()
end function