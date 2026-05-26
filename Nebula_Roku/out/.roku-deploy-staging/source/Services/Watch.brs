function urlWatchValidate(watchSessionId, key, id)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Watch/Validate?ws=" + watchSessionId.toStr() + "&key=" + key + "&id=" + id.toStr()
end function

function urlWatchKill()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Watch/Kill"
end function

function urlWatchAll()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Watch/All"
end function

function urlWatchKiller(profileId, deviceId)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Watch/Killer?p=" + profileId.ToStr() + "&d="+ deviceId.ToStr()
end function

function urlWatchEnd()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Watch/End"
end function

function urlWatchKeepAlive()
    baseUrl = getBeaconBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V1 +"/Watch/KeepAlive"
end function

function urlUpdateWatchSession(key, id)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V1 +"/Watch/Update?key=" + key + "&id=" + id.toStr()
end function