' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.top.finished = false
  device = getDevice(getVersion(), getVersionCode(), getAppCode())
  scaleInfo = getScaleInfo(device.width, device.height)

  addAndSetFields(m.global, {
    configVariablesKeys: getAppConfigVariable(),
    apiVersions: getApiVersion(),
    device: device,
    width: scaleInfo.width,
    height: scaleInfo.height,
    ratio: device.ratio,
    scaleInfo: scaleInfo,
    colors: mergeAssociativeArrays(getBasicColors(), getSpecialColors()),
    appCode: getAppCode(),
    beaconTokenExpiresIn: 0,
  })

  'find Nodes
  versionLabel = m.top.findNode("versionLabel")
  copyrightLabel = m.top.findNode("copyrightLabel")
  logo = m.top.findNode("logo")

  logoWidth = scaleValue(500, scaleInfo)
  logoHeight = scaleValue(250, scaleInfo)
  logo.width = logoWidth
  logo.height = logoHeight
  logo.loadWidth = logoWidth
  logo.loadHeight = logoHeight
  logo.translation = [((scaleInfo.width - logoWidth) / 2), (scaleInfo.height - logoHeight) / 2]

  versionLabel.color = m.global.colors.PRIMARY
  versionLabel.text = "v " + getVersion()
  versionLabel.width = scaleInfo.width - (scaleInfo.safeZone.x * 2)
  versionLabel.height = scaleValue(35, scaleInfo)
  versionLabel.translation = [scaleInfo.safeZone.x, (scaleInfo.height - scaleInfo.safeZone.y - scaleValue(80, scaleInfo))]

  copyrightLabel.color = m.global.colors.LIGHT_GRAY
  copyrightLabel.text = "@copyright " + getCurrentYear() + " - Qvix Solutions"
  copyrightLabel.width = device.width
  copyrightLabel.translation = [0, (device.height - 50)]

  m.i18n = invalid
  scene = m.top.getScene()
  if scene <> invalid then
      m.i18n = scene.findNode("i18n")
  end if
  
  __valdiateInternetConnection()
end sub

' Procesa la respuesta al validar la conexion contra las APIs
sub onValdiateConnectionResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlPlatformsVariables(getUrl(), m.global.appCode, getVersionCode()), "GET", "onPlatformResponse", invalid, invalid, true)
  else 
    printError("Launcher Connection: " , m.apiRequestManager.errorResponse)
  m.dialog = createAndShowDialog(m.top, i18n_t(m.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosed", [i18n_t(m.i18n, "button.retry"), i18n_t(m.i18n, "button.exit")])
  end if
end sub

' Procesa la respuesta al obtener las variables de la plataforma
sub onPlatformResponse() ' invoked when EpisodesScreen content is changed
  if valdiateStatusCode(m.apiRequestManager.statusCode) then    
    addAndSetFields(m.global, {variables: ParseJson(m.apiRequestManager.response).data} )
    m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
    
    if isLoginUser() then
      if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlAuthRegenerateSession(m.apiUrl), "POST", "onRegenerateSession", FormatJson({device: m.global.device}))
    else
      m.top.finished = true
    end if
  else 
    printError("Launcher variables: " , m.apiRequestManager.errorResponse)
  m.dialog = createAndShowDialog(m.top, i18n_t(m.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosed", [i18n_t(m.i18n, "button.retry"), i18n_t(m.i18n, "button.exit")])
  end if
end sub

' Dispara la regeneracion de la infromacion del usuario logueado
sub onRegenerateSession()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager) 

    addAndSetFields(m.global, {variables: resp.variables, device: resp.device, organization: resp.organization, contact: resp.contact} )
    saveNextUpdateVariables()
  end if
  m.top.finished = true
end sub

'Obtener el año actual.
function getCurrentYear() as String
  dt = CreateObject("roDateTime")
  dt.Mark()
  return dt.GetYear().ToStr()
end function

' Procesa el evento de cierre del dialogo y realiza la accion pertinente
sub onDialogClosed(_event)
  option = m.dialog.buttonSelected

  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid

  if option = 0 then
    ' Disparar Reintentar
    __valdiateInternetConnection()
  else
    ' Disparar Salir
    m.top.forceExit = true
  end if 
end sub

' Realiza la peticion para validar la conexion a internet
sub __valdiateInternetConnection()
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlHealth(getUrl()), "GET", "onValdiateConnectionResponse", invalid, invalid, true)
end sub
