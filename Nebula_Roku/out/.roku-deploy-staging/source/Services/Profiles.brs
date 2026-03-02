function urlProfilesbyId(apiUrl, profileid)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Profiles/" + profileid.ToStr()
end function

function urlProfiles(apiUrl)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/Profiles"
end function