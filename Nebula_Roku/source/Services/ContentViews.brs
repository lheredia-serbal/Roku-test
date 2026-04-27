function urlContentViewsCarousels(contentViewId)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function

function urlViewAllCarousels(contentViewId, carouselId)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/ContentViews/" + contentViewId.toStr() + "/Carousels/" + carouselId.toStr()
end function