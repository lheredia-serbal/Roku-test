' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.top.finished = false
  deviceInfo = CreateObject("roDeviceInfo")

  scaleInfo = getScaleInfo(deviceInfo)
  device = getDevice(deviceInfo, scaleInfo, getVersion(), getVersionCode(), getAppCode(), m.global.language)

  addAndSetFields(m.global, {
    configVariablesKeys: getAppConfigVariable(),
    apiVersions: getApiVersion(),
    device: device,
    scaleInfo: scaleInfo,
    colors: mergeAssociativeArrays(getBasicColors(), getSpecialColors()),
    appCode: getAppCode(),
    beaconTokenExpiresIn: 0,
  })

  'find Nodes
  m.versionLabel = m.top.findNode("versionLabel")
  m.copyrightLabel = m.top.findNode("copyrightLabel")
  m.splashBackground = m.top.findNode("splashBackground")
  m.domainManagerTimer = m.top.findNode("domainManagerTimer")
  m.domainManagerTimer.observeField("fire", "onDomainManagerTimerFire")
  m.simulateCdnFirstFailure = getSimulateCdnFirstFailure()
  m.cdnFirstFailureTriggered = false

  if m.splashBackground <> invalid then
    m.splashBackground.width = scaleInfo.width
    m.splashBackground.height = scaleInfo.height
    m.splashBackground.loadWidth = scaleInfo.width
    m.splashBackground.loadHeight = scaleInfo.height
    m.splashBackground.translation = [0, 0]
    if scaleInfo.width >= 1920 then
      m.splashBackground.uri = "pkg:/images/client/splash-screen_fhd.jpg"
    else if scaleInfo.width >= 1280 then
      m.splashBackground.uri = "pkg:/images/client/splash-screen_hd.jpg"
    else
      m.splashBackground.uri = "pkg:/images/client/splash-screen_sd.jpg"
    end if
  end if

  m.versionLabel.color = m.global.colors.PRIMARY
  m.versionLabel.width = scaleInfo.width
  m.versionLabel.translation = [0, (scaleInfo.height - scaleValue(70, scaleInfo))]

  m.copyrightLabel.color = m.global.colors.LIGHT_GRAY
  m.copyrightLabel.width = scaleInfo.width
  m.copyrightLabel.translation = [0, (m.versionLabel.translation[1] + scaleValue(20, scaleInfo))]
  
  __startCdnInitialization()
end sub

sub __startCdnInitialization(keepDialogVisible = false)
  if not getFetchInitialConfig() then
    __showCdnErrorDialog()
    return
  end if
  
  if not keepDialogVisible then
    __hideCdnErrorDialog()
  end if
  m.cdnUrls = getCdnConfigUrls()

  if m.simulateCdnFirstFailure and not m.cdnFirstFailureTriggered then
    m.cdnFirstFailureTriggered = true
    m.cdnUrls[0] = m.cdnUrls[0] + "1"
    m.cdnUrls[1] = m.cdnUrls[1]
  end if

  m.cdnIndex = 0

  setConfigUrls(m.cdnUrls[0], m.cdnUrls[1])
  getInitialConfiguration("Primary")
  __startDomainManagerPolling()
end sub

function startCdnInitialization(keepDialogVisible = false)
  __startCdnInitialization(keepDialogVisible)
end function

sub __startDomainManagerPolling()
  if m.domainManagerTimer = invalid then return
  m.domainManagerTimer.control = "start"
end sub

sub onDomainManagerTimerFire()
  status = getInitialConfigStatus()
  if status = "pending" or status = "idle" then return
  m.domainManagerTimer.control = "stop"
  if status = "success" then
    __handleInitialConfigSuccess()
  else
    __showCdnErrorDialog()
  end if
end sub

sub __handleInitialConfigSuccess()
  resource = getResourceByName("ClientsApiUrl")
  if resource = invalid or resource.primary = invalid or resource.secondary = invalid then
    __showCdnErrorDialog()
    return
  end if

  m.clientsApiCandidates = [resource.primary, resource.secondary]
  m.clientsApiIndex = 0
  __requestClientsApiHealth()
end sub


sub __requestClientsApiHealth()
  if m.clientsApiCandidates = invalid or m.clientsApiIndex >= m.clientsApiCandidates.count() then
    __showCdnErrorDialog()
    return
  end if

  url = urlClientsHealth(m.clientsApiCandidates[m.clientsApiIndex])
  m.clientsHealthRequestManager = sendApiRequest(m.clientsHealthRequestManager, url, "GET", "onClientsApiHealthResponse", invalid, invalid, invalid, true)
end sub

sub onClientsApiHealthResponse()
  if validateStatusCode(m.clientsHealthRequestManager.statusCode) then
    baseUrl = m.clientsApiCandidates[m.clientsApiIndex]
    addAndSetFields(m.global, {activeApiUrl: baseUrl})
    m.apiUrl = baseUrl
    m.clientsHealthRequestManager = clearApiRequest(m.clientsHealthRequestManager)
    __hideCdnErrorDialog()
    __valdiateInternetConnection()
  else
    printError("ClientsApiUrl health: ", m.clientsHealthRequestManager.errorResponse)
    m.clientsHealthRequestManager = clearApiRequest(m.clientsHealthRequestManager)
    m.clientsApiIndex = m.clientsApiIndex + 1
    __requestClientsApiHealth()
  end if
end sub

sub __showCdnErrorDialog()
  showCdnErrorDialog()
end sub

sub __hideCdnErrorDialog()
  hideCdnErrorDialog()
end sub

sub onCdnErrorRetry()
  if m.cdnErrorDialog = invalid then return
  if not m.cdnErrorDialog.retry then return
  m.cdnErrorDialog.retry = false
  m.cdnErrorDialog.showSpinner = true
  m.cdnErrorDialog.buttonDisabled = true
  __startCdnInitialization(true)
end sub

' Procesa la respuesta al validar la conexion contra las APIs
sub onValdiateConnectionResponse()
  m.versionLabel.text = "v " + getVersion()
  m.copyrightLabel.text = i18n_t(m.global.i18n, "launcherScreen.copyright").Replace("{{year}}",getCurrentYear())
  
  if validateStatusCode(m.apiRequestManager.statusCode) then
    apiUrl = getActiveApiUrl()
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlPlatformsVariables(apiUrl, m.global.appCode, getVersionCode()), "GET", "onPlatformResponse", invalid, invalid, invalid, true)
  else 
    printError("Launcher Connection: " , m.apiRequestManager.errorResponse)
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosed", [i18n_t(m.global.i18n, "button.retry"), i18n_t(m.global.i18n, "button.exit")])
  end if
end sub

' Procesa la respuesta al obtener las variables de la plataforma
sub onPlatformResponse() ' invoked when EpisodesScreen content is changed
  if validateStatusCode(m.apiRequestManager.statusCode) then    
    addAndSetFields(m.global, {variables: ParseJson(m.apiRequestManager.response).data} )
    m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
    
    if isLoginUser() then
      if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlAuthRegenerateSession(m.apiUrl), "POST", "onRegenerateSession", invalid, FormatJson({device: m.global.device}))
    else
      __validateAutoUpgrade(true)
    end if
  else 
    printError("Launcher variables: " , m.apiRequestManager.errorResponse)
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosed", [i18n_t(m.global.i18n, "button.retry"), i18n_t(m.global.i18n, "button.exit")])
  end if
end sub

' Dispara la regeneracion de la infromacion del usuario logueado
sub onRegenerateSession()
  statusCode = m.apiRequestManager.statusCode
  if validateStatusCode(statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager) 

    addAndSetFields(m.global, {variables: resp.variables, device: resp.device, organization: resp.organization, contact: resp.contact} )
    saveNextUpdateVariables()
    __validateAutoUpgrade(false)
  else if validateLogout(statusCode) then 
    deleteTokens()
    deleteSessionData()
    removeFields(m.global, ["contact", "organization", "PrivateVariables"])
    __validateAutoUpgrade(true)
  else 
    printError("Launcher RegenerateSession: " , m.apiRequestManager.errorResponse)
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosed", [i18n_t(m.global.i18n, "button.retry"), i18n_t(m.global.i18n, "button.exit")])
  end if
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

' Dispara la validacion de upgrade
sub __validateAutoUpgrade(isPublicApi)
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  m.utoUpgradeIsPublicApi = isPublicApi
  body = {
    appCode: m.global.appCode,
    versionCode: getVersionCode(),
    signedByGooglePlay: true,
    startUp: true
  }
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlAutoUpgradeValidate(m.apiUrl), "POST", "onAutoUpgradeResponse", invalid, FormatJson(body), invalid, isPublicApi)
end sub

' Procesa la respuesta del AutoUpgrade y continua con el flujo actual
sub onAutoUpgradeResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    data = resp
    if resp <> invalid and resp.data <> invalid then data = resp.data

    if data <> invalid and data.checkTime <> invalid and data.checkTime > 0 then
      nowDate = CreateObject("roDateTime")
      nowDate.ToLocalTime()
      setNextAutoUpgradeCheck((nowDate.asSeconds() + data.checkTime).ToStr())
    end if

    upgrade = false
    if data <> invalid and data.upgrade <> invalid then
      upgrade = data.upgrade
    end if

    mandatory = false
    if data <> invalid and data.mandatory <> invalid then
      mandatory = data.mandatory
    end if

    if upgrade then
      m.autoUpgradeMandatory = mandatory
      messageKey = "autoUpgrade.message"
      buttons = [i18n_t(m.global.i18n, "autoUpgrade.remindLater"), i18n_t(m.global.i18n, "button.exit")]
      if mandatory then
        messageKey = "autoUpgrade.mandatoryMessage"
        buttons = [i18n_t(m.global.i18n, "button.exit")]
      end if
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "autoUpgrade.title"), i18n_t(m.global.i18n, messageKey), "onAutoUpgradeAvailableDialogClosed", buttons)
    else
      m.top.finished = true
    end if
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  else 
    printError("AutoUpgrade: ", m.apiRequestManager.errorResponse)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onAutoUpgradeDialogClosed", [i18n_t(m.global.i18n, "button.retry"), "Exit"])
  end if
end sub

' Procesa el evento de cierre del dialogo de AutoUpgrade
sub onAutoUpgradeDialogClosed(_event)
  option = m.dialog.buttonSelected

  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid

  if option = 0 then
    __validateAutoUpgrade(m.utoUpgradeIsPublicApi)
  else
    m.top.forceExit = true
  end if
end sub

' Procesa el evento de cierre del modal de upgrade disponible
sub onAutoUpgradeAvailableDialogClosed(_event)
  option = m.dialog.buttonSelected

  m.dialog.visible = false
  m.dialog.unobserveField("buttonSelected")
  m.top.removeChild(m.dialog)
  m.dialog = invalid

  if m.autoUpgradeMandatory = true then
    m.top.forceExit = true
    return
  end if

  if option = 0 then
    m.top.finished = true
    return
  else
    m.top.forceExit = true
    return
  end if
end sub

' Realiza la peticion para validar la conexion a internet
sub __valdiateInternetConnection()
  apiUrl = getActiveApiUrl()
  if apiUrl = invalid then
    __showCdnErrorDialog()
    return
  end if
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlHealth(apiUrl), "GET", "onValdiateConnectionResponse", invalid, invalid, invalid, true)
end sub
