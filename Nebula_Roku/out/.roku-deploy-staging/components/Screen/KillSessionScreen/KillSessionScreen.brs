' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.sessionsContainer = m.top.findNode("sessionsContainer")
  m.sessionsList = m.top.findNode("sessionsList")
  m.titleManySessions = m.top.findNode("titleManySessions")
  
  m.killedMeContainer = m.top.findNode("killedMeContainer")
  m.titleKilledMe = m.top.findNode("titleKilledMe")
  m.backToHomeButton = m.top.findNode("backToHomeButton")
  m.goToHomeTimer = m.top.findNode("goToHomeTimer")

  m.scaleInfo = m.global.scaleInfo

  m.widthContainer = 0
  m.redirectKey = invalid
  m.redirectId = 0
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as string, press as boolean) as boolean
  if m.top.loading.visible <> false and key <> KeyButtons().BACK then 
    return true
  end if

  handled = false

  if m.sessionsContainer.visible then 
    ' Contol de navegacion sobre la pantalla de quitar sesiones
    if key = KeyButtons().UP
      if press and m.sessionsList <> invalid and m.sessionsList.isInFocusChain() and m.sessionsList.focusedChild <> invalid and m.sessionsList.focusedChild.focusUp <> invalid then
        focusItem = m.sessionsList.focusedChild.focusUp.findNode("CloseSession")
        if focusItem <> invalid then 
          focusItem.setFocus(true)
        end if
      end if
      handled = true
    
    else if key = KeyButtons().DOWN
      if press and m.sessionsList <> invalid and m.sessionsList.isInFocusChain() and m.sessionsList.focusedChild <> invalid and m.sessionsList.focusedChild.focusDown <> invalid  then
        focusItem = m.sessionsList.focusedChild.focusDown.findNode("CloseSession")
        if focusItem <> invalid then 
          focusItem.setFocus(true)
        end if
      end if
      handled = true
  
    else if key = KeyButtons().OK
      if press and m.sessionsList <> invalid and m.sessionsList.isInFocusChain() and m.sessionsList.focusedChild <> invalid then
        m.lastFocus = m.sessionsList.focusedChild.findNode("CloseSession")
        __closeSession(m.sessionsList.focusedChild.itemContent.watchSessionId)
      end if
      handled = true
  
    else if key = KeyButtons().RIGHT or key = KeyButtons().LEFT
      handled = true
    end if 

  else if m.killedMeContainer.visible then 
    ' Contol de navegacion sobre la pantalla informa que me quitaron la sesion

    if key = KeyButtons().OK then 
      if press and m.backToHomeButton.isInFocusChain() then onGoToHome()
      handled = true

    else if key <> KeyButtons().BACK then 
      handled = true
    end if
  end if

  return handled
end function 

' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
    m.backToHomeButton.text = i18n_t(m.global.i18n, "button.backToHome")
    m.titleManySessions.text = i18n_t(m.global.i18n, "errorPlanSession.manyPeople")
  if (m.top.data = invalid or m.top.data = "") and m.top.killedMe <> invalid and m.top.killedMe <> "" then
    __initConfigWithKilledMe()

    m.killedMe = ParseJson(m.top.killedMe)
    __getKiller(m.killedMe.profileId, m.killedMe.deviceId)
  else if m.top.data <> invalid and m.top.data <> "" then 
    __initConfigWithManySessions()
    
    data = ParseJson(m.top.data)
    m.redirectKey = data.redirectKey
    m.redirectId = data.redirectId

    __getAllSessions()
  else if not m.top.onFocus then 
    __clearScreen()
  end if
end sub

' Procesa la respuesta de todos los que estan mirando actualemnte con la cuenta del usuario 
sub onAllWhoAreWatchingResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response).data
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    fistItem = invalid
    prevSessionItem = invalid
    for each item in resp
      itemContent = createObject("roSGNode", "SessionItemContentNode")

      itemContent.watchSessionId = item.watchSessionId
      itemContent.deviceTypeDescription = item.deviceTypeDescription
      itemContent.deviceDescription = item.deviceDescription
      itemContent.programDescription = item.programDescription
      itemContent.profileName = item.profileName

      newSessionItem = m.sessionsList.createChild("SessionListItem")
      newSessionItem.widthContainer = (m.scaleInfo.width - 80)
      newSessionItem.itemContent = itemContent

        ' Configura la navegación vertical las sesiones
      if prevSessionItem <> invalid then
        prevSessionItem.focusDown = newSessionItem
        newSessionItem.focusUp = prevSessionItem
      end if
      
      prevSessionItem = newSessionItem

      if fistItem = invalid then fistItem = newSessionItem
  end for

  if fistItem <> invalid and fistItem.findNode("CloseSession") <> invalid then fistItem.findNode("CloseSession").setFocus(true)
    m.top.loading.visible = false
  else 	
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    m.top.loading.visible = false
    printError("AllWhoAreWatching Stastus:", errorResponse)
    
    if validateLogout(statusCode, m.top) then return 
  end if
end sub

' Procesa la respuesta de si el ususario puede ver
sub onWatchValidateResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response).data
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if resp.resultCode = 200 then
      setWatchSessionId(resp.watchSessionId)
      setWatchToken(resp.watchToken)
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.redirectKey, m.redirectId), "GET", "onStreamingsResponse")
    else 
      m.top.loading.visible = false
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      
      __validateError(0, resp.resultCode, invalid)
      printError("WatchValidate ResultCode:", resp.resultCode)
    end if
  else 
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    
    if (statusCode = 408) then
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if

    printError("WatchValidate Stastus:", statusCode.toStr() + " " +  errorResponse)
  end if
end sub

' Procesa la respuesta al obtener la url de lo que se quiere ver
sub onStreamingsResponse() 
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      streaming = resp.data
      streaming.key = m.redirectKey 
      streaming.id = m.redirectId
      streaming.streamingType = getStreamingType().DEFAULT
      m.top.streaming = FormatJson(streaming)
    else 
      m.top.loading.visible = false
      printError("Streamings Emty:", m.apiRequestManager.response)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    end if
  else 
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if (statusCode = 408) then  
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if

    printError("Streamings:", errorResponse)
  end if
end sub

' Hace foco en objeto que lo tenia antes de que se abriera el modal
sub onDialogClosedLastFocus()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid

  if option = 0 then
    if m.lastFocus <> invalid then m.lastFocus.setFocus(true)
  end if
  if m.lastFocus <> invalid then m.lastFocus = invalid 
end sub

' Procesa la respuesta de que se elimino una sesion
sub onkillSessionResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    watchSessionId = getWatchSessionId()
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlWatchValidate(m.apiUrl, watchSessionId, m.redirectKey, m.redirectId), "GET", "onWatchValidateResponse")
  else 
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if (statusCode = 408) then
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", invalid [i18n_t(m.global.i18n, "button.cancel")])
    else 
      __validateError(statusCode, 0, errorResponse)
    end if

    printError("KillSession:", errorResponse)
  end if
end sub

' Procesa la respuesta de quien es que elimino mi sesion
sub onKillerResponse()
  textError = i18n_t(m.global.i18n, "errorPlanSession.killer")
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if resp <> invalid and resp.data <> invalid then 
      clearTimer(m.goToHomeTimer)
      m.InfoKiller = resp.data

      m.titleKilledMe.drawingStyles = {
        "MyBold": { "fontUri": "font:MediumBoldSystemFont" }
        "default": { "fontUri": "font:MediumSystemFont" }
      }
        
      date = CreateObject("roDateTime")
      date.FromISO8601String(m.killedMe.date)
      date.ToLocalTime()

      m.titleKilledMe.text = textError.Replace("{{date}}", dateConverter(date, i18n_t(m.global.i18n, "time.formatDateAndHours")))

      if (m.infoKiller.deviceDescription <> invalid and m.infoKiller.deviceDescription <> "") then 
        m.titleKilledMe.text = m.titleKilledMe.text + " <MyBold>" + m.infoKiller.deviceDescription + "</MyBold>"
      else if (m.infoKiller.deviceTypeDescription <> invalid and m.infoKiller.deviceTypeDescription <> "") then
        m.titleKilledMe.text = m.titleKilledMe.text + " <MyBold>" + m.infoKiller.deviceTypeDescription + "</MyBold>"
      end if
      
      m.titleKilledMe.text = m.titleKilledMe.text + " (" +  m.infoKiller.profileName + ")"

      m.goToHomeTimer.ObserveField("fire","onGoToHome")
      m.goToHomeTimer.control = "start"

      m.backToHomeButton.setFocus(true)
      m.top.loading.visible = false
    end if 
  else 
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    m.top.loading.visible = false

    printError("Killer:", errorResponse)

    if validateLogout(statusCode, m.top) then return 
  end if
end sub

' Dispara el evento de regresar a la home
sub onGoToHome()
  clearTimer(m.goToHomeTimer)
  m.top.goToHome = true
end sub

' Dispara el evento de deslogueo
sub onLogoutChange()
  if m.top.logout then __clearScreen()
end sub

' Carga la configuracion inicial del componente cuando interactua como la pantalla de muchas sesiones concurrentes, 
' escuchando los observable y obteniendo las referencias de compenentes necesarios para su uso
sub __initConfigWithManySessions()
  m.sessionsContainer.visible = true
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  
  width = m.scaleInfo.width
  
  m.widthContainer = width - scaleValue(80, m.scaleInfo)
  m.sessionsContainer.translation = [(width / 2), scaleValue(80, m.scaleInfo)]
  
  m.titleManySessions.width = width - scaleValue(300, m.scaleInfo)
end sub

' Carga la configuracion inicial del componente cuando interactua como la pantalla de que la sesion fue eliminada por otro dipositivo, 
' escuchando los observable y obteniendo las referencias de compenentes necesarios para su uso
sub __initConfigWithKilledMe()
  m.killedMeContainer.visible = true
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  
  width = m.scaleInfo.width
  height = m.scaleInfo.height
  
  m.killedMeContainer.translation = [(width / 2), (height / 2)]
  m.titleKilledMe.width = width - scaleValue(300, m.scaleInfo)
end sub

' Dispara la peticion de cerrrar una sesion
sub __closeSession(watchSessionId)
  m.top.loading.visible = true
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlWatchKill(m.apiUrl), "PUT", "onkillSessionResponse", FormatJson({watchSessionId: watchSessionId}))
end sub

' Limpia la lista de sesiones activas
sub __clearSessionList()
  while m.sessionsList.getChildCount() > 0
    child = m.sessionsList.getChild(0)
    child.itemContent = invalid
    m.sessionsList.removeChild(child)
  end while
end sub

' Dispara la busqueda de todas las sesiones activas
sub __getAllSessions()
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlWatchAll(m.apiUrl), "GET", "onAllWhoAreWatchingResponse")
end sub

' Dispara la busqueda de la informacion de quien cerro mi sesion
sub __getKiller(profileId, deviceId)
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlWatchKiller(m.apiUrl, profileId, deviceId), "GET", "onKillerResponse")
end sub

' Valdia el error obtenido desde la API
sub __validateError(statusCode, resultCode, errorResponse)
  error = invalid
  
  if validateLogout(statusCode, m.top) then return 

  if errorResponse <> invalid and errorResponse <> "" then 
    error = ParseJson(errorResponse) 
  else 
    error = { code: resultCode }
  end if

  if (error <> invalid and error.code <> invalid) then 
    if (error.code = 5931) then
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), (i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHavePlan")).Replace("[ProductName]", m.productName), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5932) then
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), (i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHaveAnyActiveSubscriptions")).Replace("[ProductName]", m.productName), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5939) then
      m.dialog = createAndShowDialog(m.top,i18n_t(m.global.i18n, "shared.errorComponent.weAreSorry"), i18n_t(m.global.i18n, "shared.errorComponent.youCurrentlyDoNotHaveSufficientBalance"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    
    else if (error.code = 5930) then
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      __clearSessionList()
      __getAllSessions()
    end if
  else 
    if (statusCode = 400) or (statusCode = 404) or (statusCode = 500) then 
      m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.unhandled"), i18n_t(m.global.i18n, "shared.errorComponent.extendedMessage"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
    end if
  end if 
end sub

' Metodo encargado de limpiar todas las dependecias, cancelar las peticiones y quitar los escuchadores de la pantalla
sub __clearScreen()
  ' limpiar pantalla 
  clearTimer(m.goToHomeTimer)
  m.redirectKey = invalid
  m.redirectId = 0

  __clearSessionList()  

  m.sessionsContainer.visible = false
  m.killedMeContainer.visible = false

  m.titleKilledMe.text = ""
  m.InfoKiller = invalid
end sub