function urlProgramAction(apiUrl, key, id)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "/Actions"
end function

function urlProgramSummary(apiUrl, key, id, mainImageTypeId, imagesTypes)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "/Summary?mit=" + mainImageTypeId.toStr() + "&bit=" + imagesTypes.toStr()
end function

function urlProgramById(apiUrl, key, id, mainImageTypeId, imagesTypes)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "?mit=" + mainImageTypeId.toStr() + "&bit=" + imagesTypes.toStr()
end function

function urlProgramRelated(apiUrl, key, id)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "/Related"
end function

function urlErrorPage(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V3 +"/Programs/ErrorPage"
end function

function urlSearch(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V3 +"/Programs/Search"
end function

function urlSearchById(apiUrl, carouselId)
    return apiUrl + "/"+ m.global.apiVersions.V3 +"/Programs/Search/" + carouselId.toStr()
end function

function urlEpisodes(apiUrl, epgId)
    return apiUrl + "/"+ m.global.apiVersions.V3 +"/Programs/EpgId/" + epgId.toStr() + "/Episodes"
end function