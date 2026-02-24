function urlPlatformsVariables(apiUrl, appCode, versionCode, signed = true)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Platforms/Variables?c=" + appCode + "&v=" + versionCode.ToStr() + "&gp=" + signed.ToStr()
end function