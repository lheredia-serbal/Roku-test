function urlContentViewsCrousels(apiUrl, contentViewId)
    return "1" + apiUrl + "/"+ m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function