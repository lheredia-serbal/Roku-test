' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  ' referencias a Labels
  m.nameLabel     = m.top.findNode("nameLabel")
  m.emailLabel    = m.top.findNode("emailLabel")
  m.serialLabel   = m.top.findNode("serialLabel")
  m.deviceIdLabel = m.top.findNode("deviceIdLabel")
  m.versionLabel  = m.top.findNode("versionLabel")
  m.orgNameLabel  = m.top.findNode("orgNameLabel")
  m.titleLabel  = m.top.findNode("titleLabel")
end sub


' Inicializa el foco del componente seteando los valores necesarios
sub initFocus()
  if m.top.onFocus then 
    m.titleLabel.text = i18n_t(m.global.i18n, "configPage.title")
    
    m.device  = m.global.device
    m.contact = m.global.contact 
  
    ' relleno texto
    m.nameLabel.text = i18n_t(m.global.i18n, "configPage.titleName") +  m.contact.name
    m.emailLabel.text = i18n_t(m.global.i18n, "configPage.titleEmail") + m.contact.email
  
    m.serialLabel.text = i18n_t(m.global.i18n, "configPage.titleSerialNumber") + m.device.serialNumber
    m.deviceIdLabel.text = i18n_t(m.global.i18n, "configPage.titleDiveId") + m.device.id.ToStr()
  
    m.versionLabel.text = i18n_t(m.global.i18n, "configPage.titleVersion") + m.device.appVersion + " " + getCurrentInitalConfig() + "/" + getCode()
    m.orgNameLabel.text = i18n_t(m.global.i18n, "configPage.orgName")

    if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
    if m.beaconUrl = invalid then m.beaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 
    actionLog = getActionLog({ actionCode: ActionLogCode().OPEN_PAGE, pageUrl: "Config" })
    __saveActionLog(actionLog)
  end if
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogsToken(m.apiUrl), "GET", "onActionLogTokenResponse", invalid, invalid, false, FormatJson(actionLog))
  else
      __sendActionLog(actionLog)
  end if
end sub

' Obtener el beacon token
sub onActionLogTokenResponse() 

  resp = ParseJson(m.apiLogRequestManager.response)
  actionLog = ParseJson(m.apiLogRequestManager.dataAux)

  setBeaconToken(resp.actionsLogToken)

  now = CreateObject("roDateTime")
  now.ToLocalTime()
  m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager) 
  __sendActionLog(actionLog)
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogs(m.beaconUrl), "POST", "onActionLogResponse", FormatJson(actionLog), beaconToken, false)
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub