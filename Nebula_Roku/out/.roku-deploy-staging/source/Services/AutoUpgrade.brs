function urlAutoUpgradeValidate()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/AutoUpgrade/Validate"
end function
