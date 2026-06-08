function urlContentViewsCarousels(contentViewId)
    contentViewIdParam = 1
    if contentViewId <> invalid and contentViewId > 0 then contentViewIdParam = contentViewId
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/ContentViews/" + contentViewIdParam.toStr() + "/Carousels"
end function

function urlViewAllCarousels(contentViewId, carouselId)
    contentViewIdParam = -1
    ''if contentViewId <> invalid and contentViewId > 0 then contentViewIdParam = contentViewId
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/" + m.global.apiVersions.V3 + "/ContentViews/" + contentViewIdParam.toStr() + "/Carousels/" + carouselId.toStr()
end function