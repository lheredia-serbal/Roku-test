function urlProfilesbyId(profileid)
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Profiles/" + profileid.ToStr()
end function

function urlProfiles()
    baseUrl = getServiceBaseUrl()
    return baseUrl + "/"+ m.global.apiVersions.V3 +"/Profiles"
end function