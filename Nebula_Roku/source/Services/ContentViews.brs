function urlContentViewsCarousels(apiUrl, contentViewId)
    baseUrl = apiUrl
    return baseUrl + "/" + m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function

function urlViewAllCarousels(apiUrl, contentViewId, carouselId)
    baseUrl = apiUrl
    return baseUrl + "/" + m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels/" + carouselId.toStr()
end function