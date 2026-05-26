function urlChannelsLastWatched()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 + "/Channels/LastWatched"
end function

function urlChannels()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Channels"
end function