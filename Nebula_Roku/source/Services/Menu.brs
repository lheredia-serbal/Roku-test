function urlMenu(productCode)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Menu?pr=" + productCode
end function