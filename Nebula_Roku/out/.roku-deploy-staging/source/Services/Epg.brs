

function urlEpgCarouselGuide(channelId)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/Epg/CarouselGuide?c=" + channelId.ToStr()
end function

