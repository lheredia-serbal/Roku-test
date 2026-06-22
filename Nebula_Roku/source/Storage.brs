' Normaliza el guardado de informacion en estorage por problemas de que el roRegistrySection se comparte por DeveloperId.
' Retorna True al finalizar.
function migrateRegistrySectionToPrefixed() as boolean
    prefix = getRegistryPrefix()
    
     if (prefix = invalid or prefix = "") then
        return false
    end if

    if (__RegRead(__REG_KEY_STORAGE_MIGRATION_TO_PREFIX_DONE(), __REG_SECTION_SESSION_DATA(), "") = "1") then 
        return true
    end if

    copiedSession = __MigrateRegistrySectionValues(__REG_SECTION_SESSION_DATA(false), __REG_SECTION_SESSION_DATA(), false)

    if copiedSession < 0 then
        return false
    end if

    copiedAuth = __MigrateRegistrySectionValues(__REG_SECTION_AUTHENTICATION(false), __REG_SECTION_AUTHENTICATION(), false)
   
    if copiedAuth < 0 then
        return false
    end if

    ' Recién al final marcamos la migracion como completada.
    __RegWrite(__REG_KEY_STORAGE_MIGRATION_TO_PREFIX_DONE(), "1", __REG_SECTION_SESSION_DATA())

    return true
end function

Function getRegistryPrefix() As String
    globalAA = GetGlobalAA()

    if (globalAA.__REGISTRY_PREFIX = invalid) then
        appInfo = CreateObject("roAppInfo")
        prefix = appInfo.GetValue("registry_prefix")

        if prefix = invalid then prefix = ""
        prefix = prefix.Trim()

        if prefix = "" then
            print "********************************************************************"
            print "                 ERROR - registry_prefix not exist.                 "
            print "********************************************************************"
        end if

        globalAA.__REGISTRY_PREFIX = prefix
    end if

    return globalAA.__REGISTRY_PREFIX
End Function

' Devuelve un objeto device con la info del dispositivo.
function getDevice(deviceInfo, scaleInfo, appVersion, appVersionCode, appCode, appLanguage = invalid) as object
    OSVersion = deviceInfo.GetOSVersion()
    modelDetails = deviceInfo.GetModelDetails()

    versionDevice = OSVersion.major + "." + OSVersion.minor + "." + OSVersion.revision
    build = OSVersion.build
    
    return {
        id: __getDeviceId(),
        token: __getDeviceToken(),
        registerCode: invalid, ' Se obtiene de la API si aplica
        description: __getDeviceDescription(),
        type: __getDeviceType(),
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
        guid: __getDeviceGUID(),
        alias: __getDeviceAlias(),
        deviceLanguage: deviceInfo.GetCurrentLocale(),
        appLanguage: appLanguage
    }
end function

' Actualiza la info del dispositivo guardada de forma permanente
Sub SetDevice(device)
    if (device = invalid) then return
    valuesDevice = CreateObject("roAssociativeArray")
    keys = __RegKeys()

    if (device.id <> invalid and device.id <> 0) then valuesDevice.AddReplace(keys.DEVICE_ID, device.id.toStr())
    if (device.token <> invalid and device.token <> "") then valuesDevice.AddReplace(keys.DEVICE_TOKEN, device.token)
    if (device.description <> invalid and device.description <> "") then valuesDevice.AddReplace(keys.DEVICE_DESCRIPTION, device.description)
    if (device.alias <> invalid and device.alias <> "") then valuesDevice.AddReplace(keys.DEVICE_ALIAS, device.alias)
    if (device.guid <> invalid and device.guid <> "") then valuesDevice.AddReplace(keys.DEVICE_GUID, device.guid)
    if (device.type <> invalid) then
        if (device.type.id <> invalid and device.type.id <> 0) then valuesDevice.AddReplace(keys.DEVICE_TYPE_ID, device.type.id.toStr())
        if (device.type.name <> invalid) then valuesDevice.AddReplace(keys.DEVICE_TYPE_NAME, device.type.name)
    end if

    if (valuesDevice.Count() > 0) then __RegWriteMulti(valuesDevice, __REG_SECTION_SESSION_DATA())
    
    valuesDevice = invalid 
end Sub

' Guarda los tokens del dispositivo.
sub saveTokens(resp)
    valuesTokens = CreateObject("roAssociativeArray")
    keys = __RegKeys()
    
    if (resp.expiresIn <> invalid and resp.expiresIn >= 0) then 
        dateTime = CreateObject("roDateTime")
        dateTime.ToLocalTime()
        time = dateTime.asSeconds() + resp.expiresIn
        if  ((resp.expiresIn - 30) > 0) then time = dateTime.asSeconds() + (resp.expiresIn - 30)
        valuesTokens.AddReplace(keys.ACCESS_TOKEN_EXPIRATION_DATE, time.toStr())
    end if

    if (resp.accessToken <> invalid and resp.accessToken <> "") then valuesTokens.AddReplace(keys.ACCESS_TOKEN, resp.accessToken)
    if (resp.refreshToken <> invalid and resp.refreshToken <> "") then valuesTokens.AddReplace(keys.REFRESH_TOKEN, resp.refreshToken)
    if (resp.reAuthenticationToken <> invalid and resp.reAuthenticationToken <> "") then valuesTokens.AddReplace(keys.RE_AUTHENTICATE_TOKEN, resp.reAuthenticationToken)

    if (valuesTokens.Count() > 0) then __RegWriteMulti(valuesTokens, __REG_SECTION_AUTHENTICATION())
    valuesTokens = invalid
end sub

function getNextUpdateVariables()
    return __RegRead(__RegKeys().NEXT_UPDATE_VARIABLES, __REG_SECTION_SESSION_DATA())
end function

function getNextAutoUpgradeCheck()
    return __RegRead(__RegKeys().NEXT_AUTO_UPGRADE_CHECK, __REG_SECTION_SESSION_DATA())
end function

Sub setNextAutoUpgradeCheck(value as string)
    if value <> invalid then __RegWrite(__RegKeys().NEXT_AUTO_UPGRADE_CHECK, value, __REG_SECTION_SESSION_DATA())
end Sub

sub saveNextUpdateVariables()
    nowDate = CreateObject("roDateTime")
    nowDate.ToLocalTime()
    
    expiredIn = getConfigVariable(m.global.configVariablesKeys.VARIABLES_UPDATE_TIME)
    
    if ((expiredIn = invalid) or (expiredIn <> invalid and expiredIn <= 0)) then expiredIn = 14400 ' Si no viene se ponen 4Hs por defecto

    __setNextUpdateVariables((nowDate.asSeconds() + expiredIn).ToStr())
end sub

Sub setDeviceToken(token As String)
    __RegWrite(__RegKeys().DEVICE_TOKEN, token, __REG_SECTION_SESSION_DATA())
End Sub

Sub setBeaconToken(beaconToken As string)
    __RegWrite(__RegKeys().BEACON_TOKEN, beaconToken, __REG_SECTION_SESSION_DATA())
End Sub

Function getBeaconToken() As String
    token = __RegRead(__RegKeys().BEACON_TOKEN, __REG_SECTION_SESSION_DATA())
    if (token = invalid) then token = ""
    return token
End Function

Function getWatchSessionId() As integer
    watchSessionId = __RegRead(__RegKeys().WATCH_SESSION_ID, __REG_SECTION_SESSION_DATA())
    if (watchSessionId <> invalid and watchSessionId <> "") then
        return Val(watchSessionId)
    end if
    return 0
End Function

Sub setWatchSession(watchSession as object)
    if (watchSession <> invalid) then 
        id = watchSession.watchSessionId

        if (id = invalid) then id = 0
        
        __RegWrite(__RegKeys().WATCH_SESSION_ID, id.toStr(), __REG_SECTION_SESSION_DATA())
        if (watchSession.watchToken <> invalid) __RegWrite(__RegKeys().WATCH_TOKEN, watchSession.watchToken, __REG_SECTION_AUTHENTICATION())
    end if
End Sub

Function getWatchToken() As String
    watchToken = __RegRead(__RegKeys().WATCH_TOKEN, __REG_SECTION_AUTHENTICATION())
    if (watchToken = invalid) then watchToken = ""
    return watchToken
End Function

Function getAccessToken() As String
    token = __RegRead(__RegKeys().ACCESS_TOKEN, __REG_SECTION_AUTHENTICATION())
    if token = invalid then token = ""
    return token
End Function

Function isLoginUser() as boolean
    token = __RegRead(__RegKeys().ACCESS_TOKEN, __REG_SECTION_AUTHENTICATION())
    if (token <> invalid) and token <> "" then 
        return true
    end if
    return false 
End Function

Function getRefreshToken() As String
    token = __RegRead(__RegKeys().REFRESH_TOKEN, __REG_SECTION_AUTHENTICATION())
    if (token = invalid) then token = ""
    return token
End Function

Function getReAuthenticateToken() As String
    token = __RegRead(__RegKeys().RE_AUTHENTICATE_TOKEN, __REG_SECTION_AUTHENTICATION())
    if (token = invalid) then token = ""
    return token
End Function

function getAccessTokenExpirationDate()
    time = __RegRead(__RegKeys().ACCESS_TOKEN_EXPIRATION_DATE, __REG_SECTION_AUTHENTICATION())
    if (time = invalid) then time = ""
    return time
End function

Sub deleteTokens()
    keys = __RegKeys()

    TokensToDelete = [keys.REFRESH_TOKEN, keys.ACCESS_TOKEN, keys.RE_AUTHENTICATE_TOKEN, keys.ACCESS_TOKEN_EXPIRATION_DATE, keys.WATCH_TOKEN]
    sec = CreateObject("roRegistrySection", __REG_SECTION_AUTHENTICATION())
    for each item in TokensToDelete 
        sec.Delete(item)
    end for
    sec.Flush()
    
    sec = invalid
End Sub

Sub deleteSessionData()
    __RegDelete(__RegKeys().WATCH_SESSION_ID, __REG_SECTION_SESSION_DATA())
End Sub

function __getDeviceType() as object
    id = __RegRead(__RegKeys().DEVICE_TYPE_ID, __REG_SECTION_SESSION_DATA())
    if (id <> invalid and id <> "") then id = Val(id)
    deviceType = {
        id: id,
        name: __RegRead(__RegKeys().DEVICE_TYPE_NAME, __REG_SECTION_SESSION_DATA(), ""),
        code: "app_roku"
    }
    return deviceType
end function

Function __getDeviceToken() As String
    token = __RegRead(__RegKeys().DEVICE_TOKEN, __REG_SECTION_SESSION_DATA())
    if (token = invalid) then token = ""
    return token
End Function

function __getDeviceId()
    deviceId = __RegRead(__RegKeys().DEVICE_ID, __REG_SECTION_SESSION_DATA())
    if (deviceId <> invalid and deviceId <> "") then
        return Val(deviceId)
    end if
    return invalid
end function

function __getDeviceDescription()
    return __RegRead(__RegKeys().DEVICE_DESCRIPTION, __REG_SECTION_SESSION_DATA(), "")
end function

function __getDeviceGUID()
    return __RegRead(__RegKeys().DEVICE_GUID, __REG_SECTION_SESSION_DATA())
end function

function __getDeviceAlias()
    return __RegRead(__RegKeys().DEVICE_ALIAS, __REG_SECTION_SESSION_DATA())
end function


Sub __setNextUpdateVariables(value as String)
    if (value <> invalid) then __RegWrite(__RegKeys().NEXT_UPDATE_VARIABLES, value, __REG_SECTION_SESSION_DATA())
end Sub

' Metodo privado. Lee y devuelve la informacion guardada en el Storage.
' Busca a traves de paramentro key, el paramentro section define a que conjuto pertenece el paramentro a buscar (por defecto se devine invalid), 
' el defaultValue es un valor que devolvera en caso de no encotnrarse la informacion (por defecto se devine invalid)
Function __RegRead(key As String, section = invalid As Dynamic, defaultValue = invalid As Dynamic) As Dynamic
    if (section = invalid) then section = __REG_SECTION_DEFAULT()
    sec = CreateObject("roRegistrySection", Box(section).ToStr())
    
    result = defaultValue
    if (sec.Exists(key)) then result = sec.Read(key)
    
    sec = invalid
    return result
End Function

' Metodo privado. Guarda informacion guardada en el Storage.
' Busca a traves de paramentro key, el paramentro section define a que conjuto pertenece el paramentro a buscar (por defecto se devine invalid)
Sub __RegWrite(key As String, val As String, section = invalid As Dynamic)
    if (section = invalid) then section = __REG_SECTION_DEFAULT()
    sec = CreateObject("roRegistrySection", Box(section).ToStr())
    sec.Write(key, val)
    sec.Flush() 
    
    sec = invalid
End Sub

' Metodo privado. Borra informacion guardada en el Storage.
' Busca a traves de paramentro key, el paramentro section define a que conjuto pertenece el paramentro a buscar (por defecto se devine invalid)
Sub __RegDelete(key As String, section = invalid)
    if (section = invalid) then section = __REG_SECTION_DEFAULT()
    sec = CreateObject("roRegistrySection", Box(section).ToStr())
    sec.Delete(key)
    sec.Flush()

    sec = invalid
End Sub

' Metodo privado. Guarda varios valores en una misma seccion del Registry
Sub __RegWriteMulti(values As Object, section = invalid As Dynamic)
    if (values = invalid) then return
    if (section = invalid) then section = __REG_SECTION_DEFAULT()

    sec = CreateObject("roRegistrySection", Box(section).ToStr())

    okWrite = sec.WriteMulti(values)
    okFlush = sec.Flush()

    if (okWrite = false) then print "Write failed writing section"
    if (okFlush = false) then print "Write failed flushing section"

    sec = invalid
End Sub

Function __RegKeys() As Object
    globalAA = GetGlobalAA()

    if (globalAA.__REG_KEYS = invalid) then
        globalAA.__REG_KEYS = {
            DEVICE_ID: "DeviceId"
            DEVICE_TOKEN: "Token"
            DEVICE_DESCRIPTION: "DeviceDescription"
            DEVICE_ALIAS: "DeviceAlias"
            DEVICE_GUID: "DeviceGUID"
            DEVICE_TYPE_ID: "DeviceTypeId"
            DEVICE_TYPE_NAME: "DeviceTypeName"

            BEACON_TOKEN: "BeaconToken"

            WATCH_SESSION_ID: "watchSessionId"
            WATCH_TOKEN: "watchToken"

            ACCESS_TOKEN: "AccessToken"
            REFRESH_TOKEN: "RefreshToken"
            RE_AUTHENTICATE_TOKEN: "ReAuthenticateToken"
            ACCESS_TOKEN_EXPIRATION_DATE: "AccessTokenExpirationDate"

            NEXT_UPDATE_VARIABLES: "NextUpdateVariables"
            NEXT_AUTO_UPGRADE_CHECK: "NextAutoUpgradeCheck"
        }
    end if

    return globalAA.__REG_KEYS
End Function

Function __REG_SECTION_DEFAULT(addPrefix = true As Boolean) As String
    sectionName = "Default"

    if addPrefix then
        return getRegistryPrefix() + "_" + sectionName
    end if

    return sectionName
End Function

Function __REG_SECTION_SESSION_DATA(addPrefix = true As Boolean) As String
    sectionName = "SessionData"

    if addPrefix then
        return getRegistryPrefix() + "_" + sectionName
    end if

    return sectionName
End Function

Function __REG_SECTION_AUTHENTICATION(addPrefix = true As Boolean) As String
    sectionName = "Authentication"

    if addPrefix then
        return getRegistryPrefix() + "_" + sectionName
    end if

    return sectionName
End Function

Function __REG_KEY_STORAGE_MIGRATION_TO_PREFIX_DONE() As String
    return "StorageMigrationToPrefixed_v1"
End Function

' Funcion destinada a la migracion de un storage viejo a uno nuevo.
Function __MigrateRegistrySectionValues(oldSection As String, newSection As String, overwriteExisting = false As Boolean) As Integer
    if (oldSection = invalid or oldSection = "") then return -1
    if (newSection = invalid or newSection = "") then return -1

    oldSec = CreateObject("roRegistrySection", oldSection)
    newSec = CreateObject("roRegistrySection", newSection)

    keys = oldSec.GetKeyList()

    if (keys = invalid) then
        oldSec = invalid
        newSec = invalid
        return 0
    end if

    valuesToWrite = CreateObject("roAssociativeArray")

    for each key in keys
        keyName = Box(key).ToStr()

        if (keyName <> "") then
            shouldCopy = true

            if (overwriteExisting <> true) then
                if newSec.Exists(keyName) then shouldCopy = false
            end if

            if shouldCopy then
                value = oldSec.Read(keyName)

                if (value <> invalid) then valuesToWrite.AddReplace(keyName, value)
            end if
        end if
    end for

    copiedCount = valuesToWrite.Count()

    if (copiedCount > 0) then
        okWrite = newSec.WriteMulti(valuesToWrite)
        okFlush = newSec.Flush()

        if (okWrite = false or okFlush = false) then
            oldSec = invalid
            newSec = invalid
            valuesToWrite = invalid

            return -1
        end if
    end if

    oldSec = invalid
    newSec = invalid
    valuesToWrite = invalid

    return copiedCount
End Function



' Devuelve todo el contenido del Registry en formato JSON.
' Incluye todas las secciones, todas las keys y sus valores.
'Function __RegDumpAllAsJson() As String
'    reg = CreateObject("roRegistry")
'    sections = reg.GetSectionList()
'
'    result = CreateObject("roAssociativeArray")
'
'    if sections <> invalid then
'        for each section in sections
'            sectionName = Box(section).ToStr()
'
'            sec = CreateObject("roRegistrySection", sectionName)
'            keys = sec.GetKeyList()
'
'            sectionValues = CreateObject("roAssociativeArray")
'
'            if keys <> invalid then
'                for each key in keys
'                    keyName = Box(key).ToStr()
'                    value = sec.Read(keyName)
'
'                    if value = invalid then value = ""
'
'                    sectionValues.AddReplace(keyName, value)
'                end for
'            end if
'
'            result.AddReplace(sectionName, sectionValues)
'
'            sec = invalid
'            sectionValues = invalid
'        end for
'    end if
'
'    reg = invalid
'
'    return FormatJson(result)
'End Function

' Elimina absolutamente todas las secciones del Registry.
'Sub __RegDeleteAllSections()
'    reg = CreateObject("roRegistry")
'    sections = reg.GetSectionList()
'
'    if sections <> invalid then
'        for each section in sections
'            sectionName = Box(section).ToStr()
'            reg.Delete(sectionName)
'        end for
'    end if
'
'    reg.Flush()
'    reg = invalid
'End Sub