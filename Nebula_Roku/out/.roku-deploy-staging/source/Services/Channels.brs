function urlChannelsLastWatched(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 + "/Channels/LastWatched"
end function

function urlChannels(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Channels"
end function