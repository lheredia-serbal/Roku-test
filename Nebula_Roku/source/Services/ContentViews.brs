function urlContentViewsCrousels(apiUrl, contentViewId)
    return apiUrl + "/"+ m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function