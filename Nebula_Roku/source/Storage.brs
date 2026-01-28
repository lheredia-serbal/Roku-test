' Devuelve un objeto device con la info del dispositivo.
function getDevice(deviceInfo, scaleInfo, appVersion, appVersionCode, appCode, appLanguage = invalid) as object
    OSVersion = deviceInfo.GetOSVersion()
    modelDetails = deviceInfo.GetModelDetails()

    versionDevice = OSVersion.major + "." + OSVersion.minor + "." + OSVersion.revision
    build = OSVersion.build
    
    return {
        id: getDeviceId(),
        token: getDeviceToken(),
        registerCode: invalid, ' Se obtiene de la API si aplica
        description: getDeviceDescription(),
        type: getDeviceType(),
        browserName: invalid, ' Roku no tiene navegador
        userAgent: invalid, ' No hay userAgent disponible en Roku
        serialNumber: deviceInfo.GetChannelClientId(),
        brand: modelDetails.VendorName,
        model: deviceInfo.getmodelDisplayName(),
        fingerprint: modelDetails.Manufacturer + "-" + modelDetails.ModelNumber + "-" + versionDevice + "-" + build, ' Roku no tiene fingerprint
        hardware: deviceInfo.GetModel(),
        manufacturer: modelDetails.Manufacturer,
        cpuAbi: invalid, ' No expuesto en Roku
        cpuAbi2: invalid, ' No expuesto en Roku
        scaleInfo: scaleInfo,
        width: scaleInfo.w,
        height: scaleInfo.h,
        operatingSystem: {
            name: "Roku OS",
            version: versionDevice,
            versionIncremental: build,
            sdk: OSVersion.major
        },
        ipAddress: invalid,
        macWireless: invalid,
        macEthernet: "00:00:00:00:00:00",
        appVersion: appVersion,
        appCode: appCode,
        linkedToUser: false, ' Debe definirse con lógica adicional
        product: invalid,
        signedByGooglePlay: true, ' Roku no tiene un concepto directo de "App Store Signing"
        appVersionCode: appVersionCode,
        guid: getDeviceGUID(),
        alias: getDeviceAlias(),
        deviceLanguage: deviceInfo.GetCurrentLocale(),
        appLanguage: appLanguage
    }
end function

' Actualiza la info del dispositivo guardada de forma permanente
Sub SetDevice(device)
    if device.id <> invalid and device.id <> 0 then setDeviceId(device.id)
    if device.token <> invalid and device.token <> "" then setDeviceToken(device.token)
    if device.description <> invalid and device.description <> "" then setDeviceDescription(device.description)
    if device.alias <> invalid and device.alias <> "" then setDeviceAlias(device.alias)
    if device.guid <> invalid and device.guid <> "" then setDeviceGUID(device.guid)
    if device.type <> invalid then setDeviceType(device.type)
end Sub

' Guarda los tokens del dispositivo.
sub saveTokens(resp)
    if resp.expiresIn <> invalid and resp.expiresIn >= 0 then 
        dateTime = CreateObject("roDateTime")
        dateTime.ToLocalTime()
        time = dateTime.asSeconds() + resp.expiresIn
        if  (resp.expiresIn - 30) > 0 then  time = dateTime.asSeconds() + (resp.expiresIn - 30)
        setAccessTokenExpirationDate(time.toStr())
    end if
    if resp.accessToken <> invalid and resp.accessToken <> "" then setAccessToken(resp.accessToken)
    if resp.refreshToken <> invalid and resp.refreshToken <> "" then setRefreshToken(resp.refreshToken)
    if resp.reAuthenticationToken <> invalid and resp.reAuthenticationToken <> "" then setReAuthenticateToken(resp.reAuthenticationToken)
end sub

function getDeviceId()
    deviceId = __RegRead("DeviceId", "SessionData")
    if deviceId <> invalid and deviceId <> "" then
        return Val(deviceId)
    end if
    return invalid
end function

Sub setDeviceId(value)
    if value <> invalid then __RegWrite("DeviceId", value.toStr(), "SessionData")
end Sub

function getDeviceDescription()
    return __RegRead("DeviceDescription", "SessionData", "")
end function

Sub setDeviceDescription(value)
    if value <> invalid then __RegWrite("DeviceDescription", value, "SessionData")
end Sub

function getDeviceGUID()
    return __RegRead("DeviceGUID", "SessionData")
end function

Sub setDeviceGUID(value)
    if value <> invalid then __RegWrite("DeviceGUID", value, "SessionData")
end Sub

function getDeviceAlias()
    return __RegRead("DeviceAlias", "SessionData")
end function

function getNextUpdateVariables()
    return __RegRead("NextUpdateVariables", "SessionData")
end function

function getNextAutoUpgradeCheck()
    return __RegRead("NextAutoUpgradeCheck", "SessionData")
end function

Sub setDeviceAlias(value)
    if value <> invalid then __RegWrite("DeviceAlias", value, "SessionData")
end Sub

Sub setNextAutoUpgradeCheck(value)
    if value <> invalid then __RegWrite("NextAutoUpgradeCheck", value, "SessionData")
end Sub

sub saveNextUpdateVariables()
    nowDate = CreateObject("roDateTime")
    nowDate.ToLocalTime()
    
    expiredIn = getConfigVariable(m.global.configVariablesKeys.VARIABLES_UPDATE_TIME)
    
    if (expiredIn = invalid) or (expiredIn <> invalid and expiredIn <= 0) then expiredIn = 14400 ' Si no viene se ponen 4Hs por defecto

    __setNextUpdateVariables((nowDate.asSeconds() + expiredIn).ToStr())
end sub

function getDeviceType() as object
    id = __RegRead("DeviceTypeId", "SessionData")
    if id <> invalid and id <> "" then id = Val(id)
    deviceType = {
        id: id,
        name: __RegRead("DeviceTypeName", "SessionData", ""),
        code: "app_roku"
    }
    return deviceType
end function

Sub setDeviceType(deviceType as object)
    if deviceType.id <> invalid and deviceType.id <> 0 then __RegWrite("DeviceTypeId", deviceType.id.toStr(), "SessionData")
    if deviceType.name <> invalid then __RegWrite("DeviceTypeName", deviceType.name, "SessionData")
end Sub

Function getDeviceToken() As String
    token = __RegRead("Token", "SessionData")
    if token = invalid then token = ""
    return token
End Function

Sub setDeviceToken(token As String)
    __RegWrite("Token", token, "SessionData")
End Sub

Sub setBeaconToken(beaconToken As string)
    __RegWrite("BeaconToken", beaconToken, "SessionData")
End Sub

Function getBeaconToken() As String
    token = __RegRead("BeaconToken", "SessionData")
    if token = invalid then token = ""
    return token
End Function

Function getWatchSessionId() As integer
    watchSessionId = __RegRead("watchSessionId", "SessionData")
    if watchSessionId <> invalid and watchSessionId <> "" then
        return Val(watchSessionId)
    end if
    return 0
End Function

Sub setWatchSessionId(watchSessionId As integer)
    if watchSessionId = invalid then watchSessionId = 0
    __RegWrite("watchSessionId", watchSessionId.toStr(), "SessionData")
End Sub

Sub setWatchToken(watchToken As string)
    __RegWrite("watchToken", watchToken, "Authentication")
End Sub

Function getWatchToken() As String
    watchToken = __RegRead("watchToken", "Authentication")
    if watchToken = invalid then watchToken = ""
    return watchToken
End Function

Function getAccessToken() As String
    token = __RegRead("AccessToken", "Authentication")
    if token = invalid then token = ""
    return token
End Function

Function isLoginUser() as boolean
    token = __RegRead("AccessToken", "Authentication")
    if token <> invalid and token <> "" then 
        return true
    end if
    return false 
End Function

Function getRefreshToken() As String
    token = __RegRead("RefreshToken", "Authentication")
    if token = invalid then token = ""
    return token
End Function

Function getReAuthenticateToken() As String
    token = __RegRead("ReAuthenticateToken", "Authentication")
    if token = invalid then token = ""
    return token
End Function

Sub setAccessToken(token As String)
    __RegWrite("AccessToken", token, "Authentication")
End Sub

Sub setRefreshToken(token As String)
    __RegWrite("RefreshToken", token, "Authentication")
End Sub

Sub setReAuthenticateToken(token As String)
    __RegWrite("ReAuthenticateToken", token, "Authentication")
End Sub

function getAccessTokenExpirationDate()
    time = __RegRead("AccessTokenExpirationDate", "Authentication")
    if time = invalid then time = ""
    return time
End function

Sub setAccessTokenExpirationDate(time As String)
    __RegWrite("AccessTokenExpirationDate", time, "Authentication")
End Sub

Sub deleteTokens()
    TokensToDelete = ["RefreshToken", "AccessToken", "ReAuthenticateToken", "AccessTokenExpirationDate", "watchToken"]
    sec = CreateObject("roRegistrySection", "Authentication")
    for each item in TokensToDelete 
        sec.Delete(item)
    end for
    sec.Flush()
End Sub

Sub deleteSessionData()
    TokensToDelete = ["watchSessionId"]
    sec = CreateObject("roRegistrySection", "SessionData")
    for each item in TokensToDelete 
        sec.Delete(item)
    end for
    sec.Flush()
End Sub

Sub __setNextUpdateVariables(value)
    if value <> invalid then __RegWrite("NextUpdateVariables", value, "SessionData")
end Sub

' Metodo privado. Lee y devuelve la informacion guardada en el Storage.
' Busca a traves de paramentro key, el paramentro section define a que conjuto pertenece el paramentro a buscar (por defecto se devine invalid), 
' el defaultValue es un valor que devolvera en caso de no encotnrarse la informacion (por defecto se devine invalid)
Function __RegRead(key, section = invalid, defaultValue = invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return defaultValue
End Function

' Metodo privado. Guarda informacion guardada en el Storage.
' Busca a traves de paramentro key, el paramentro section define a que conjuto pertenece el paramentro a buscar (por defecto se devine invalid)
Sub __RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
End Sub

' Metodo privado. Borra informacion guardada en el Storage.
' Busca a traves de paramentro key, el paramentro section define a que conjuto pertenece el paramentro a buscar (por defecto se devine invalid)
Sub __RegDelete(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
End Sub



' sub clearDeviceData()
'     sec = CreateObject("roRegistrySection", "SessionData")
'     for each item in  ["DeviceId", "Token", "DeviceDescription", "DeviceTypeId", "DeviceGUID", "DeviceAlias"] 
'         sec.Delete(item)
'     end for
'     sec.Flush()
' end sub
