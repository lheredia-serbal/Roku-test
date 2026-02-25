function urlParentalControlPin(apiUrl, pin)
    return apiUrl + "/"+ m.global.apiVersions.V2 +"/ParentalControlPin/Validate/" + pin
end function