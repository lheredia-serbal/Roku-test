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