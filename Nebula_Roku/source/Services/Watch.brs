function urlWatchValidate(apiUrl, watchSessionId, key, id)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Watch/Validate?ws=" + watchSessionId.toStr() + "&key=" + key + "&id=" + id.toStr()
end function

function urlWatchKill(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Watch/Kill"
end function

function urlWatchAll(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Watch/All"
end function

function urlWatchKiller(apiUrl, profileId, deviceId)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Watch/Killer?p=" + profileId.ToStr() + "&d="+ deviceId.ToStr()
end function

function urlWatchEnd(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Watch/End"
end function

function urlWatchKeepAlive(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V1 +"/Watch/KeepAlive"
end function