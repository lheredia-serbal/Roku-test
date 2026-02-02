function urlContentViewsCrousels(apiUrl, contentViewId)
    baseUrl = apiUrl
    if m.global <> invalid and m.global.domainManagerState <> invalid then
        if m.global.domainManagerState._mode = "Primary" then
            baseUrl = "1" + apiUrl
        end if
    end if
    return baseUrl + "/"+ m.global.apiVersions.V2 + "/ContentViews/" + contentViewId.toStr() + "/Carousels"
end function