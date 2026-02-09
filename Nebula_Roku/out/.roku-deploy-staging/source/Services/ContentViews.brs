function urlContentViewsCrousels(apiUrl, contentViewId)
    baseUrl = apiUrl
    return baseUrl + "/" + m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function