function urlContentViewsCrousels(apiUrl, contentViewId)
    baseUrl = apiUrl
    return "1" + baseUrl + "/" + m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function