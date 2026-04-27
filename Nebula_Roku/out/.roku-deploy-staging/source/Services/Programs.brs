function urlProgramAction(key, id)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "/Actions"
end function

function urlProgramSummary( key, id, mainImageTypeId, imagesTypes)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "/Summary?mit=" + mainImageTypeId.toStr() + "&bit=" + imagesTypes.toStr()
end function

function urlProgramById(key, id, mainImageTypeId, imagesTypes)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "?mit=" + mainImageTypeId.toStr() + "&bit=" + imagesTypes.toStr()
end function

function urlProgramRelated(key, id)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V2 +"/Programs/" + key + "/" + id.toStr() + "/Related"
end function

function urlProgramRelatedFromNews( key, id)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Programs/" + key + "/" + id.toStr() + "/Related"
end function

function urlErrorPage()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Programs/ErrorPage"
end function

function urlSearch()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Programs/Search"
end function

function urlSearchById(carouselId)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Programs/Search/" + carouselId.toStr()
end function

function urlEpisodes(key, id)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Programs/" + key.toStr() + "/" + id.toStr() + "/Episodes"
end function