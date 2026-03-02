

function urlEpgCarouselGuide(apiUrl, channelId)
    return apiUrl + "/" + m.global.apiVersions.V2 + "/Epg/CarouselGuide?c=" + channelId.ToStr()
end function

