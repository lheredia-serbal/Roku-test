' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.videoPlayer = m.top.findNode("VideoPlayer")
  m.playerControllers = m.top.findNode("playerControllers")
  
  m.backgroundControllers = m.top.findNode("backgroundControllers")
  m.programInfo = m.top.findNode("programInfo")
  m.programSummaryPlayer = m.top.findNode("programSummaryPlayer")
  m.timelineBar = m.top.findNode("timelineBar")
  m.showInfoTimer = m.top.findNode("showInfoTimer")
  m.newProgramTimer = m.top.findNode("newProgramTimer")
  
  m.playPauseImageButton = m.top.findNode("playPauseImageButton")
  m.restartImageButton = m.top.findNode("restartImageButton")
  m.toLiveImageButton = m.top.findNode("toLiveImageButton")
  m.guideImageButton = m.top.findNode("guideImageButton")

  m.channelList = m.top.findNode("channelList")
  m.channelListContainer = m.top.findNode("channelListContainer")
  m.selectedIndicator = m.top.findNode("selectedIndicator")
  
  m.beaconTimer = m.top.findNode("beaconTimer")
  m.retryReconnection = m.top.findNode("retryReconnection")
  m.saveLastWatched = m.top.findNode("saveLastWatched")
  m.channelListTimer = m.top.findNode("channelListTimer")
  
  m.errorChannel = m.top.findNode("errorChannel")
  m.errorChannelImage = m.top.findNode("errorChannelImage")
  m.errorChannelTitle = m.top.findNode("errorChannelTitle")
  m.connectingSignal = m.top.findNode("connectingSignal")
  m.errorChannel = m.top.findNode("errorChannel")
  m.spinner = m.top.findNode("spinner")
  
  m.guide = m.top.findNode("Guide")

  m.inactivityOverlay = m.top.findNode("inactivityOverlay")
  m.inactivityMessage = m.top.findNode("inactivityMessage")
  m.inactivityContinueButton = m.top.findNode("inactivityContinueButton")
  m.inactivityTimer = m.top.findNode("inactivityTimer")
  m.inactivityAutoCloseTimer = m.top.findNode("inactivityAutoCloseTimer") 

  m.inactivityPrompt = invalid

  m.showChannelListAfterUpdate = false
  m.channelSelected = invalid
  m.allowChannelList = true
  m.isLiveContent = false
  m.isLiveRewind = false
  m.streamStartSeconds = invalid
  m.liveRewindDuration = invalid

  m.RETRY_INTERVAL = 1000
  m.TIMER_SAVE_LAST_WATCHED = 1000
  m.timelineSeekStep = 15
  
  m.beaconType = ""
  m.lastErrorTime = invalid
  m.lastKey = invalid
  m.lastId = 0
  m.itemSelected = invalid
  m.repositionChannnelList = false
  m.lastButtonSelect = invalid
  m.sendLastChannelWatched = false
  m.focusplayerByload = false

  m.i18n = invalid
  scene = m.top.getScene()
  if scene <> invalid then
      m.i18n = scene.findNode("i18n")
  end if
  applyTranslations()
end sub

' Aplicar las traducciones en el componente
sub applyTranslations()
  if m.i18n = invalid then
      return
  end if

  m.connectingSignal.text = i18n_t(m.i18n, "player.playerPage.connecting")
  m.playPauseImageButton.tooltip = i18n_t(m.i18n, "player.video.pause")
  m.restartImageButton.tooltip = i18n_t(m.i18n, "player.video.restart")
  m.toLiveImageButton.tooltip = i18n_t(m.i18n, "player.video.goLive")
  m.guideImageButton.tooltip = i18n_t(m.i18n, "player.video.guide")
  m.inactivityMessage.text = i18n_t(m.i18n, "player.playerPage.askHere")
  m.inactivityContinueButton.text = i18n_t(m.i18n, "button.continueSee")
end sub

' Mostrar el modal de inactividad
sub onInactivityTimerFired()
  if m.inactivityOverlay <> invalid then

    if m.inactivityPromptEnabled then
      m.inactivityOverlay.visible = true
      __startInactivityAutoCloseTimer()
      if m.inactivityContinueButton <> invalid then
        m.inactivityContinueButton.setFocus(true)
      end if
    else 
      __reconnectStream()
    end if
  end if
end sub

' Cuando pasa un tiempo mientras se muestra el modal de inactividad sin que el usuario hay presionado una botón, cerrar el player
sub onInactivityAutoCloseTimerFired()
  if m.inactivityOverlay <> invalid and m.inactivityOverlay.visible then
    __closePlayer(true)
  end if
end sub

' Reiniciar el timer de inactividad
sub __resetInactivityTimer()
  clearTimer(m.inactivityTimer)
  m.inactivityTimer.duration = m.inactivityPromptTimeInSeconds
  m.inactivityTimer.repeat = false
  m.inactivityTimer.control = "start"
  m.inactivityTimer.ObserveField("fire","onInactivityTimerFired") 
end sub

' Reiniciar el timer de auto cierre del modal de inactividad
sub __startInactivityAutoCloseTimer()
  
  clearTimer(m.inactivityAutoCloseTimer)
  m.inactivityAutoCloseTimer.duration = m.inactivityPromptDurationInSeconds
  m.inactivityAutoCloseTimer.control = "start"

  m.inactivityAutoCloseTimer.observeField("fire", "onInactivityAutoCloseTimerFired")
end sub

' Detener el timer de auto cierre del modal de inactividad
sub __stopInactivityAutoCloseTimer()
  if m.inactivityAutoCloseTimer = invalid then return

  m.inactivityAutoCloseTimer.control = "stop"
end sub

' Ocultar el modal de inactividad
sub __hideInactivityPrompt()
  __stopInactivityAutoCloseTimer()
  if m.inactivityOverlay <> invalid then
    wasVisible = m.inactivityOverlay.visible
    m.inactivityOverlay.visible = false
    m.inactivityContinueButton.setFocus(false)
    if wasVisible and m.videoPlayer <> invalid then
      m.videoPlayer.setFocus(true)
    end if
  end if
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as String, press as Boolean) as Boolean

  if m.top.loading.visible <> false and key <> KeyButtons().BACK then
    return true
  end if

  handled = false

  if m.videoPlayer.isInFocusChain() and key = KeyButtons().BACK then
    if press then 
      __closePlayer()
      handled = false

      actionLog = getActionLog({ actionCode: ActionLogCode().CLOSE_PLAYER, program: m.program })
      __saveActionLog(actionLog)
    else 
      handled = true
    end if
  
  else if m.playerControllers.isInFocusChain() and key = KeyButtons().BACK then
    if not press then onHidenProgramInfo()
    handled = true
    
  else if m.playerControllers.isInFocusChain() and key = KeyButtons().UP then
    if not press and m.timelineBar <> invalid and m.timelineBar.visible then
      m.timelineBar.setFocus(true)
    end if

  else if m.inactivityContinueButton.isInFocusChain() then

    handled = true
    if key = KeyButtons().OK or key = KeyButtons().BACK
      __hideInactivityPrompt()
      __resetInactivityTimer()

      __reconnectStream()
    end if

  else if m.guideImageButton.isInFocusChain()
    if key = KeyButtons().OK then
      if press then
        if m.showInfoTimer <> invalid then clearTimer(m.showInfoTimer)
        if m.playerControllers.visible then m.playerControllers.visible = false
        m.guide.visible = true
        m.guide.setFocus(true)
        m.guide.positioninChannelId = true

        actionLog = getActionLog({ actionCode: ActionLogCode().OPEN_PAGE, pageUrl: "Epg" })

        __saveActionLog(actionLog)
      end if
    end if

    if key = KeyButtons().UP and m.timelineBar.visible = true then
      if press then
        __restartShowInfoTimer()
        m.timelineBar.setFocus(true)
      end if
    end if

    if key = KeyButtons().LEFT and m.toLiveImageButton.visible = true then
      if press then
        __restartShowInfoTimer()
        m.toLiveImageButton.setFocus(true)
      end if
    end if

    handled = true

  else if m.toLiveImageButton.isInFocusChain() then
    
    if key = KeyButtons().LEFT and m.restartImageButton.visible = true then
      if press then
        __restartShowInfoTimer()
        m.restartImageButton.setFocus(true)
      end if
    end if

    if key = KeyButtons().RIGHT and m.guideImageButton.visible = true then
      if press then
        __restartShowInfoTimer()
        m.guideImageButton.setFocus(true)
      end if
    end if
    handled = true

  else if m.restartImageButton.isInFocusChain() then
    
    if key = KeyButtons().LEFT and m.playPauseImageButton.visible = true then
      if press then
        __restartShowInfoTimer()
        m.playPauseImageButton.setFocus(true)
      end if
    end if

    if key = KeyButtons().RIGHT and m.toLiveImageButton.visible = true then
      if press then
        __restartShowInfoTimer()
        m.toLiveImageButton.setFocus(true)
      end if
    end if
    handled = true

  else if m.playPauseImageButton.isInFocusChain() and press then
    
    __restartShowInfoTimer()
    if key = KeyButtons().RIGHT and m.restartImageButton.visible = true then
        m.restartImageButton.setFocus(true)
    end if

    if key = "OK" then
      __togglePlayPause()
    end if
    handled = true
  
  else if m.videoPlayer.isInFocusChain() and key = KeyButtons().OK then
    if not press and not m.focusplayerByload then 
      __showProgramInfo()
    else 
      m.focusplayerByload = false
    end if
    handled = true

  else if (m.videoPlayer.isInFocusChain() or m.timelineBar.isInFocusChain()) and (key = KeyButtons().LEFT or key = KeyButtons().RIGHT) then
    if not press then 
      __showProgramInfo()
      m.timelineBar.setFocus(true)
      __handleSeek(key)
    end if
    handled = true

  else if m.timelineBar <> invalid and m.timelineBar.isInFocusChain() and key = KeyButtons().DOWN then
    if not press then
      btn = __getFirstVisibleControllerButton()
      if btn <> invalid then btn.setFocus(true)
    end if
    handled = true

  else if m.videoPlayer.isInFocusChain() and (key = KeyButtons().UP or key = KeyButtons().DOWN) then
    if m.allowChannelList then 
      if not press then 
        now = CreateObject("roDateTime")
        now.ToLocalTime()
  
        if m.channelList.refreshLoadChannelList <> 0 and m.channelList.refreshLoadChannelList > now.AsSeconds() then 
          __openChannelList()
        else 
          m.showChannelListAfterUpdate = true
          __getChannels()
        end if
      end if 
    end if
    handled = true
  
  else if m.channelListContainer.isInFocusChain() and (key = KeyButtons().LEFT or key = KeyButtons().BACK) then

    if m.channelListContainer.visible = true then
      startHideChannelListTimer()
    end if

    if not press then __cancelChannelPosition()
    handled = true
  
  else if m.guide.isInFocusChain() and key = KeyButtons().BACK then 
    if press then 
      m.guide.visible = false
      m.videoPlayer.setFocus(true)
      m.guide.channelIdIndexOf = -1
      m.guide.searchChannelPosition = true
    end if
    handled = true 
  end if 

  if press and key <> KeyButtons().BACK and m.inactivityContinueButton.isInFocusChain() <> true then
    __hideInactivityPrompt()
    __resetInactivityTimer()
  end if

  return handled
end function

' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
  if m.top.data <> invalid and m.top.data <> "" then 
    __configurePlayer()
    m.streaming = ParseJson(m.top.data)
    m.errorChannel.visible = false
    m.spinner.visible = false
    m.itemSelected = invalid
    m.repositionChannnelList = false
    m.lastKey = m.streaming.key
    m.lastId = m.streaming.id
    openGuide = m.top.openGuide
    m.top.openGuide = false
    
    m.guide.loading = m.top.loading
  
    m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")

    __initVariables()
    
    if m.streaming.type <> invalid and m.streaming.type <> "" then
      streamType = LCase(m.streaming.type)
      if streamType = "live" then
        m.allowChannelList = true
        m.isLiveContent = true
        m.isLiveRewind = false
      else if streamType = "liverewind"
        m.allowChannelList = true
        m.isLiveContent = false
        m.isLiveRewind = true
      else
        m.allowChannelList = false
        m.isLiveContent = false
        m.isLiveRewind = false
      end if
    end if

    __setTimelineFromStreaming()

    if not m.isLiveContent then
      if m.videoPlayer <> invalid then
        m.videoPlayer.trickplaybar.currentTimeMarkerBlendColor = m.whiteColor
        m.videoPlayer.trickplaybar.textColor = m.whiteColor
        m.videoPlayer.trickplaybar.thumbBlendColor = m.whiteColor
        m.videoPlayer.trickplaybar.filledBarBlendColor = m.primaryColor
        m.videoPlayer.trickplaybar.filledBarImageUri = "pkg:/images/Shared/bar.png"
        m.videoPlayer.trickplaybar.trackBlendColor = m.grayColor
        m.videoPlayer.trickplaybar.trackImageUri = "pkg:/images/Shared/bar.png"
      end if
    else
      if m.timelineBar <> invalid then
        m.timelineBar.visible = false
        m.timelineBar.position = 0
        m.timelineBar.duration = 0
      end if
    end if

    ' Si debe reconectar automaticamente o preguntar al usuario si esta ahi
    m.inactivityPromptEnabled = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_ENABLED, 0) = 1
    ' Cuanto tiempo espera para redirigir
    m.inactivityPromptDurationInSeconds = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_DURATION_IN_SECONDS, -1)
    ' Cuanto espera para mostrar el cartel 
    m.inactivityPromptTimeInSeconds = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_TIME_IN_SECONDS, -1)

    if m.inactivityPromptTimeInSeconds <> -1
      __resetInactivityTimer()
    end if

    __loadPlayer(m.streaming, not openGuide)

    if not m.sendLastChannelWatched then 
      m.sendLastChannelWatched = true
      __saveLastWatched()
    end if

    if openGuide then
      m.guide.visible = true
      m.guide.setFocus(true)
    end if
    
    m.top.loading.visible = false
  end if
end sub

' Procesa la respuesta de la lista de  canales
sub onChannelsResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      if  m.channelList <> invalid then m.channelList.items = invalid

      m.guide.channelId = m.channelSelected.id

      m.guide.items = resp.data

      m.channelList.channelId = m.channelSelected.id
      m.channelList.items = resp.data

      if m.showChannelListAfterUpdate then __openChannelList(false)
    else
      if m.showChannelListAfterUpdate then m.showChannelListAfterUpdate = false 
      printError("ChannelsList Emty:", m.apiRequestManager.response)
    end if 
  else
    if m.showChannelListAfterUpdate then m.showChannelListAfterUpdate = false 
    printError("ChannelsList:", m.apiRequestManager.errorResponse)
  end if
end sub

' Metodo que se dispiara por los cambios de estado del player
Sub OnVideoPlayerStateChange()
  if m.videoPlayer <> invalid then
    if m.videoPlayer.state = "error"
      __errorProcessing()
    else if m.videoPlayer.state = "buffering"     
      m.errorChannel.visible = true
      m.spinner.visible = true
    else if m.videoPlayer.state = "playing"
      clearTimer(m.retryReconnection)
      m.lastErrorTime = invalid

      m.errorChannel.visible = false
      m.spinner.visible = false
    else if m.videoPlayer.state = "finished"
      printLog("finished")
    end if

    else if m.videoPlayer.state = "paused"
      if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/play.png"
    else if m.videoPlayer.state = "playing"
      if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/pause.png"
    end if
  
End Sub

' Metodo que actualiza la linea de tiempo cuando cambia la posicion del video
sub onVideoPositionChanged()
  __updateTimeline()
end sub

' Metodo que actualiza la linea de tiempo cuando cambia la duracion del video
sub onVideoDurationChanged()
  __updateTimeline()
end sub

' Metodo que se dispiara por la seleccion de un canal desde la lista de canales
sub onSelectItemChannelList() 
  if m.channelList <> invalid and m.channelList.isInFocusChain() then
    itemSelected = ParseJson(m.channelList.selected)

    if itemSelected <> invalid and itemSelected.id <> invalid and itemSelected.id <> 0 then 
      itemSelected.redirectKey = "ChannelId"
      itemSelected.redirectId = itemSelected.id
      itemSelected.key = "ChannelId"
      itemSelected.id = itemSelected.id
      m.repositionChannnelList = false

      m.guide.channelIdIndexOf = -1
      m.guide.channelId = itemSelected.id

      clearTimer(m.retryReconnection)
      m.lastErrorTime = invalid

      if itemSelected.parentalControl <> invalid and itemSelected.parentalControl then
        m.itemSelected = itemSelected
        m.lastButtonSelect = m.channelList.focusedChild
        m.channelList.selected = invalid
        m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.i18n, "button.ok"), i18n_t(m.i18n, "button.cancel")])
      else
        m.channelList.selected = invalid 
        __loadStreamingURL(itemSelected.redirectKey, itemSelected.redirectId, getStreamingAction().PLAY)
      end if 
    end if
  end if
end sub

' Metodo que se dispiara por la seleccion de un item desde la Guia
sub onSelectItemGuide() 
  if m.guide <> invalid and m.guide.isInFocusChain() then
    itemSelected = ParseJson(m.guide.selected)
    
    if itemSelected <> invalid and itemSelected.id <> invalid and itemSelected.id <> 0 and itemSelected.key <> invalid and itemSelected.key <> "" then 
      m.guide.selected = invalid
      
      if (itemSelected.currentChannelId <> m.channelList.channelId) or (itemSelected.currentChannelId <> invalid and m.channelList.channelId = invalid) then 
        m.channelList.channelId = itemSelected.currentChannelId
        __repositionChannelList()
      end if
      
      itemSelected.redirectKey = itemSelected.key
      itemSelected.redirectId = itemSelected.id
      itemSelected.key = itemSelected.key
      itemSelected.id = itemSelected.id

      streamingAction = getStreamingAction().PLAY

      if itemSelected.streamingAction <> invalid then streamingAction = itemSelected.streamingAction 

      clearTimer(m.retryReconnection)
      m.lastErrorTime = invalid

      m.focusplayerByload = true
      m.guide.visible = false
      m.videoPlayer.setFocus(true)
      __loadStreamingURL(itemSelected.redirectKey, itemSelected.redirectId, streamingAction)
    end if
  end if
end sub

' Procesa la respuesta al obtener la url de lo que se quiere ver
sub onStreamingsResponse() 
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      m.videoPlayer.control = "stop" 
      m.videoPlayer.content = invalid

      streaming = resp.data
      streaming.key = m.lastKey 
      streaming.id = m.lastId
      m.streaming = streaming

      m.errorChannel.visible = false
      m.spinner.visible = false

      __loadPlayer(streaming, false)

      if (m.guide <> invalid and m.channelSelected <> invalid and m.guide.channelId = m.channelSelected.id) then
        m.guide.channelIdIndexOf = -1
        m.guide.searchChannelPosition = true
      end if 
      
      __saveLastWatched()
    else 
      response = m.apiRequestManager.response
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      if m.lastErrorTime <> invalid then
        clearTimer(m.retryReconnection)

        m.retryReconnection.ObserveField("fire","onValidateConnectionAndRetry")
        m.retryReconnection.control = "start"
      end if
      
      printError("Streamings Emty:", response)
    end if
  else 
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if m.lastErrorTime <> invalid then 
      clearTimer(m.retryReconnection)

      m.retryReconnection.ObserveField("fire","onValidateConnectionAndRetry")
      m.retryReconnection.control = "start"
    end if

    printError("Streamings:", errorResponse)
  end if
end sub

' Procesa la respuesta al obtener el Summary de un programa
sub onProgramSummaryResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      fistLoad = false
      if m.program = invalid then fistLoad = true
      __loadProgramInfo(resp.data)
      __getChannels(fistLoad)
    else
      printError("ProgramSumary Empty:", m.apiRequestManager.response)
    end if 
  else
    printError("ProgramSumary:", m.apiRequestManager.errorResponse)
  end if
end sub

' Procesa la respuesta al validar la conexion contra las APIs
sub onValdiateConnectionResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    
    m.lastErrorTime = now.AsSeconds() + 30 
    __loadStreamingURL(m.lastKey, m.lastId, getStreamingType().DEFAULT)
  else
    m.lastErrorTime = invalid
    errorResponse = m.apiRequestManager.errorResponse
    clearTimer(m.retryReconnection)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    
    m.retryReconnection.ObserveField("fire","onValidateConnectionAndRetry")
    m.retryReconnection.control = "start"

    printError("Player Connection: ", errorResponse)
  end if
end sub

' Metodo que procesa la validacion de errores de conexion y toma la accion pertinente.
sub onValidateConnectionAndRetry()
  now = CreateObject("roDateTime")
  now.ToLocalTime()
 
  if  m.lastErrorTime <> invalid and now.asSeconds() < m.lastErrorTime then
    __loadStreamingURL(m.lastKey, m.lastId, getStreamingType().DEFAULT)
  else
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlHealth(m.apiUrl), "GET", "onValdiateConnectionResponse", invalid, invalid, true)
  end if
end sub

' Metodo que dispara el guardado del ultimo canal visto. La llamada a este metodo esta definida por un timer
sub onSaveLastWatched()
  if m.program <> invalid and m.program.channel <> invalid  and m.streaming <> invalid and (m.streaming.type <> invalid and m.streaming.type <> "" and (LCase(m.streaming.type) = "live") or (LCase(m.streaming.type) = "liverewind")) then 
    m.apiLastWatchedRequestManager = sendApiRequest(m.apiLastWatchedRequestManager, urlChannelsLastWatched(m.apiUrl), "PUT", "onLastWatchedResponse", FormatJson({ key: "ChannelId", id: m.program.channel.id }))
  end if
end sub

' Procesa la respuesta al guardado del ultimo canal vistro
sub onLastWatchedResponse()
  m.apiLastWatchedRequestManager = clearApiRequest(m.apiLastWatchedRequestManager)
end sub

' Metodo que dispara el guardado del beacon
sub onSendBeacon()
  position = 0
  url = urlWatchKeepAlive(m.apiBeaconUrl)

  if m.videoPlayer <> invalid then 
    if m.videoPlayer.position >= 0 then  position = m.videoPlayer.position
    
    if m.videoPlayer.state <> invalid and m.videoPlayer.state <> "" then
      if m.videoPlayer.state = "playing" then 
        url = url + "?watching=true"
      else 
        url = url + "?watching=false"
      end if
    end if 
  end if
  
  body = {
    watchSessionId: getWatchSessionId(),
    type: m.beaconType,
    contact: m.global.contact,
    device: m.global.device,
    program: m.program,
    title: invalid
    secondsElapsed: Fix(position)
  }

  m.apiBeaconRequestManager = sendApiRequest(m.apiBeaconRequestManager, url, "POST", "onSendBeaconResponse", FormatJson(body), getWatchToken())
end sub

' procesa el guardado del beacon
sub onSendBeaconResponse()
  if valdiateStatusCode(m.apiBeaconRequestManager.statusCode) then
    resp = ParseJson(m.apiBeaconRequestManager.response).data
    m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
    if resp <> invalid and resp.finished <> invalid and resp.finished then
      m.top.killedMe = FormatJson(resp)
      __closePlayer(true)
    end if 
  else
    statusCode = m.apiBeaconRequestManager.statusCode
    errorResponse = m.apiBeaconRequestManager.errorResponse 
    m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)

    watchSessionId = getWatchSessionId()
    if statusCode = 401 then 
      m.apiBeaconRequestManager = sendApiRequest(m.apiBeaconRequestManager, urlWatchValidate(m.apiUrl, watchSessionId, m.streaming.redirectKey, m.streaming.redirectId), "GET", "onWatchValidateResponse")
    end if

    printError("onSendBeaconResponse:", errorResponse)
  end if
end sub

' Procesa la respuesta de si el ususario puede ver
sub onWatchValidateResponse()
  if valdiateStatusCode(m.apiBeaconRequestManager.statusCode) then
    resp = ParseJson(m.apiBeaconRequestManager.response).data
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    if resp.resultCode = 200 then
      setWatchSessionId(resp.watchSessionId)
      setWatchToken(resp.watchToken)
      onSendBeacon()
    else 
      m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
      printError("WatchValidate ResultCode:", resp.resultCode)
    end if
  else 
    statusCode = m.apiBeaconRequestManager.statusCode
    errorResponse = m.apiBeaconRequestManager.errorResponse
    m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
    
    printError("WatchValidate Stastus:", statusCode.toStr() + " " +  errorResponse)

    actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("errorWatchValidate", "PlayerComponent"), getServerErrorStack(errorResponse), m.lastKey, m.lastId)
    __saveActionLog(actionLog)
  end if
end sub

' procesa el guardado de que se dejo de ver en el player
sub onEndWatchResponse()
  printLog("End Watch")
end sub

' Se dispara la validacion del PIN cargado en el modal
sub onPinDialogLoad()
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  m.pinDialog = invalid
  
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then 
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlParentalControlPin(m.apiUrl, resp.pin), "GET", "onParentalControlResponse")
  else 
    m.repositionChannnelList = true
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
  end if 
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if valdiateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)

    if resp <> invalid and resp.data <> invalid and resp.data then
      m.channelList.selected = invalid
      m.lastButtonSelect = invalid
      __loadStreamingURL(m.itemSelected.redirectKey, m.itemSelected.redirectId, getStreamingAction().PLAY)
    else
      m.itemSelected = invalid
      m.repositionChannnelList = true
      m.top.loading.visible = false
      m.dialog = createAndShowDialog(m.top, "", i18n_t(m.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedLastFocus")
    end if
  else     
    m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    printError("ParentalControl:", statusCode.toStr() + " " +  errorResponse)
  end if
end sub

' Hace foco en objeto que lo tenia antes de que se abriera el modal
sub onDialogClosedLastFocus()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  
  if option = 0 then
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
  end if
end sub

' Dispara la opctencion de la info del nuevo programa que se esta viendo
sub onGetNewProgramInfo()
  if m.program <> invalid then
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlProgramSummary(m.apiUrl, m.program.infoKey, m.program.infoId, getCarouselImagesTypes().NONE, getCarouselImagesTypes().NONE), "GET", "onProgramSummaryResponse")
  end if
end sub

' Esconde la informacion que se muestra sobre el player
sub onHidenProgramInfo()
  m.playerControllers.visible = false
  if m.timelineBar <> invalid then m.timelineBar.visible = false
  clearTimer(m.showInfoTimer)
  m.videoPlayer.setFocus(true)
end sub

' Define la confgiruacion inicial de la pantalla del player.
sub __configurePlayer()
  width = m.global.width
  height = m.global.height

  m.videoPlayer.width = width
  m.videoPlayer.height = height

  m.whiteColor = m.global.colors.WHITE
  m.primaryColor = m.global.colors.PRIMARY
  m.grayColor = m.global.colors.LIGHT_GRAY

  m.backgroundControllers.width = width
  m.backgroundControllers.height = height
  m.backgroundControllers.loadWidth = width
  m.backgroundControllers.loadHeight = height
  
  if m.timelineBar <> invalid then
    m.timelineBar.widthBar = width - 160
    m.timelineBar.translation = [0, 0]
  end if

  m.programInfo.translation = [80, (height - 50)]
  m.channelListContainer.translation = [(width - 360), 0]

  m.programSummaryPlayer.initConfig = true

  m.errorChannel.translation = [((m.global.width - 320) / 2), (m.global.height - 130) / 2]

  m.channelList.ObserveField("selected", "onSelectItemChannelList")
  m.guide.ObserveField("selected", "onSelectItemGuide")
end sub

' Carga el streaming que se reproducira en el player.
sub __loadPlayer(streaming, focusPlayer = true)
  videoContent = createObject("RoSGNode", "ContentNode")

  if streaming <> invalid then
    videoContent.url = streaming.playUrl 
    videoContent.title = ""
    videoContent.live = m.isLiveContent

    if streaming.streamFormat.id = getStreamingFormat().HLS then 
      videoContent.streamformat = "hls"
    else if streaming.streamFormat.id = getStreamingFormat().DASH
      videoContent.streamformat = "dash"
    end if
    
    m.videoPlayer.content = videoContent ' set node with children to video node content
    
    m.videoPlayer.visible = true

    m.videoPlayer.unobserveField("position")
    m.videoPlayer.unobserveField("duration")

    if not m.isLiveContent then
      m.videoPlayer.ObserveField("position", "onVideoPositionChanged")
      m.videoPlayer.ObserveField("duration", "onVideoDurationChanged")
    end if

    if focusPlayer then m.videoPlayer.setFocus(true)

    if not m.isLiveContent then m.videoPlayer.seek = m.streaming.startAt
    __updateTimeline()

    m.videoPlayer.control = "play" ' start playback
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlProgramSummary(m.apiUrl, streaming.key, streaming.id, getCarouselImagesTypes().NONE, getCarouselImagesTypes().NONE), "GET", "onProgramSummaryResponse")
    
    __resetInactivityTimer()
  end if
end sub

' Inicializa las vatiables de las URL que se usaran en esta pantalla.
sub __initVariables()
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  if m.apiBeaconUrl = invalid then m.apiBeaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 
end sub

' Configura datos base de la linea de tiempo segun el streaming recibido
sub __setTimelineFromStreaming()
  if m.timelineBar = invalid then return

  m.timelineBar.visible = false
  m.timelineBar.position = 0
  m.timelineBar.duration = 0
  m.liveRewindDuration = invalid
  m.streamStartSeconds = invalid

  if m.streaming = invalid then return

  if m.streaming.streamStartDate <> invalid and m.streaming.streamStartDate <> "" then
    m.streamStartSeconds = __parseIsoToSeconds(m.streaming.streamStartDate)
  end if

  if m.streaming.liveRewindDuration <> invalid and m.streaming.liveRewindDuration > 0 then
    m.liveRewindDuration = m.streaming.liveRewindDuration
    m.timelineBar.duration = m.liveRewindDuration
  else if m.streaming.duration <> invalid and m.streaming.duration > 0 then
    m.timelineBar.duration = m.streaming.duration
  end if

  if m.isLiveRewind and m.streamStartSeconds <> invalid and m.liveRewindDuration <> invalid then
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    elapsed = now.AsSeconds() - m.streamStartSeconds
    if elapsed < 0 then elapsed = 0
    if elapsed > m.liveRewindDuration then elapsed = m.liveRewindDuration
    m.timelineBar.position = elapsed
  else if m.streaming.startAt <> invalid then
    m.timelineBar.position = m.streaming.startAt
  end if
end sub

function __parseIsoToSeconds(dateString as String) as dynamic
  if dateString = invalid or dateString = "" then return invalid

  s = dateString
  s = s.Replace("T", " ")
  if Right(s, 1) = "Z" then s = Left(s, Len(s)-1) ' quita la Z

  dt = CreateObject("roDateTime")
  dt.FromISO8601String(s)
  dt.ToLocalTime()
  return dt.AsSeconds()
end function

' Dispara la busqueda de la lista de canales 
sub __getChannels(getNewChannels = true)
  if getNewChannels then m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlChannels(m.apiUrl), "GET", "onChannelsResponse")
end sub

' Carga la informacion del programa actual en pantalla
sub __loadProgramInfo(program)
  m.program = program

  if m.program.channel <> invalid then 
    m.channelSelected = m.program.channel
    m.channelList.channelId = m.channelSelected.id
    m.guide.channelId = m.channelSelected.id

    actionLog = getActionLog({ actionCode: ActionLogCode().OPEN_PLAYER, program: m.program, contentType: m.streaming.type })
    __saveActionLog(actionLog)

  end if

  programNode = createObject("roSGNode", "ProgramNode")
  startTime = CreateObject("roDateTime")
  endTime = CreateObject("roDateTime")
  now = CreateObject("roDateTime")
  now.ToLocalTime()

  if m.program.key <> invalid then programNode.key = m.program.key
  if m.program.id <> invalid then programNode.id = m.program.id

  if m.program.title <> invalid and m.program.title <> "" then 
    programNode.title = m.program.title
  end if

  if m.program.subtitle <> invalid and m.program.subtitle <> "" then programNode.subtitle = m.program.subtitle
  if m.program.synopsis <> invalid and m.program.synopsis <> "" then programNode.synopsis = m.program.synopsis
  
  if m.program.category <> invalid and m.program.category.name <> invalid and m.program.category.name <> "" then 
    programNode.categoryName = m.program.category.name
  end if

  if m.program.channel <> invalid then
    if m.program.channel.name <> invalid and m.program.channel.name <> "" then
      programNode.channelName = m.program.channel.name
    end if
    
    if m.program.channel.category <> invalid and m.program.channel.category <> "" then
      programNode.channelCategory = m.program.channel.category
    end if
  end if
  
  if m.program.formattedDuration <> invalid then programNode.formattedDuration = m.program.formattedDuration
  if m.program.durationInMinutes <> invalid then programNode.durationInMinutes = m.program.durationInMinutes

  if m.program.startTime <> invalid then 
    startTime.FromISO8601String(program.startTime)
    startTime.ToLocalTime()

    programNode.startTime = m.program.startTime
    programNode.startSeconds = startTime.AsSeconds()
    
    programNode.programTime = dateConverter(startTime, "HH:mm a")
  end if

  if m.program.endTime <> invalid then 
    endTime.FromISO8601String(program.endTime)
    endTime.ToLocalTime()

    programNode.endTime = m.program.endTime 
    programNode.endSeconds = endTime.AsSeconds()
  end if

  if not m.isLiveContent and m.timelineBar <> invalid then
    durationSeconds = 0
    if m.liveRewindDuration <> invalid then
      durationSeconds = m.liveRewindDuration
    else if programNode.startSeconds <> invalid and programNode.endSeconds <> invalid then
      durationSeconds = programNode.endSeconds - programNode.startSeconds
    else if m.program.durationInMinutes <> invalid then
      durationSeconds = m.program.durationInMinutes * 60
    end if

    if durationSeconds > 0 then m.timelineBar.duration = durationSeconds

    if m.videoPlayer <> invalid and m.videoPlayer.position >= 0 then
      m.timelineBar.position = m.videoPlayer.position
    else if m.streaming <> invalid and m.streaming.startAt <> invalid then
      m.timelineBar.position = m.streaming.startAt
    else
      m.timelineBar.position = 0
    end if
  end if
  
  if m.channelSelected <> invalid then
    m.errorChannelTitle.text = m.channelSelected.name
    if m.channelSelected.image <> invalid then m.errorChannelImage.uri = getImageUrl(m.channelSelected.image)
  end if
  
  m.programSummaryPlayer.program = programNode

  __initBeacon()
end sub

' Inicializa el timer que enviara el beacon cada X segundos.
sub __initBeacon()
  time = 20
  if m.streaming <> invalid and m.streaming.beacon <> invalid then
    if m.streaming.beacon.type <> invalid and m.streaming.beacon.type <> "" then 
    m.beaconType = m.streaming.beacon.type
    end if

    if m.streaming.beacon.time <> invalid and m.streaming.beacon.time > 0 then 
      time = m.streaming.beacon.time
    end if
  end if 

  clearTimer(m.beaconTimer)
  
  m.beaconTimer.duration = time
  m.beaconTimer.ObserveField("fire","onSendBeacon")
  m.beaconTimer.control = "start"
end sub

' Inicia el timer para guardar el ultimo canal visto.
sub __saveLastWatched()
  clearTimer(m.saveLastWatched)

  m.saveLastWatched.ObserveField("fire","onSaveLastWatched")
  m.saveLastWatched.control = "start"
end sub

' Actualiza la barra de tiempo con la informacion del player
sub __updateTimeline()
  if m.timelineBar = invalid or m.isLiveContent or m.videoPlayer = invalid then return

  duration = m.videoPlayer.duration
  position = m.videoPlayer.position

  if m.isLiveRewind and m.liveRewindDuration <> invalid then
    duration = m.liveRewindDuration
    if position = invalid or position < 0 then
      if m.streamStartSeconds <> invalid then
        now = CreateObject("roDateTime")
        now.ToLocalTime()
        position = now.AsSeconds() - m.streamStartSeconds
      else
        position = 0
      end if
    end if
  else
    if duration = invalid or duration <= 0 then duration = m.timelineBar.duration
  end if

  if duration <> invalid and duration > 0 then m.timelineBar.duration = duration

  if position <> invalid and position >= 0 then m.timelineBar.position = position
end sub

' Reinicia el timer de informacion en pantalla cuando el usuario busca manualmente
sub __restartShowInfoTimer()
  if m.showInfoTimer <> invalid then
    m.showInfoTimer.control = "stop"
    m.showInfoTimer.control = "start"
  end if
end sub

' Maneja el avance/retroceso con flechas en contenido grabado
sub __handleSeek(key as String)
  if m.isLiveContent or m.videoPlayer = invalid then return

  duration = m.videoPlayer.duration
  if duration = invalid or duration <= 0 then duration = m.timelineBar.duration
  if duration = invalid or duration <= 0 then return

  position = m.videoPlayer.position
  if position = invalid or position < 0 then position = 0

  jump = m.timelineSeekStep
  if jump = invalid or jump <= 0 then jump = 10

  if key = KeyButtons().RIGHT then
    position = position + jump
  else
    position = position - jump
  end if

  if position < 0 then position = 0
  if position > duration then position = duration

  m.videoPlayer.seek = position

  if m.timelineBar <> invalid then
    m.timelineBar.duration = duration
    m.timelineBar.position = position
  end if

  __restartShowInfoTimer()
end sub

' Devuelve el primer boton visible en los controles
function __getFirstVisibleControllerButton() as object
  buttons = [
    m.playPauseImageButton,
    m.restartImageButton,
    m.toLiveImageButton,
    m.guideImageButton
  ]

  for each btn in buttons
    if btn <> invalid and btn.visible then return btn
  end for

  return invalid
end function

' Limpia las varables y detiene los timers disparados para cerrar la pantalla del player 
sub __closePlayer(onBack = false)
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
  m.apiLastWatchedRequestManager = clearApiRequest(m.apiLastWatchedRequestManager)
  
  m.focusplayerByload = false
  m.sendLastChannelWatched = false
  m.playerControllers.visible = false

  m.programSummaryPlayer.program = invalid
  
  clearTimer(m.showInfoTimer)
  clearTimer(m.saveLastWatched)
  clearTimer(m.retryReconnection)
  clearTimer(m.newProgramTimer)
  clearTimer(m.beaconTimer)
  clearTimer(m.channelListTimer)
  clearTimer(m.inactivityTimer)
  clearTimer(m.inactivityAutoCloseTimer)
  
  m.top.data = ""
  m.beaconType = ""
  m.top.loading.visible = true
  m.lastErrorTime = invalid
  m.lastKey = invalid
  m.itemSelected = invalid
  m.repositionChannnelList = false
  m.lastButtonSelect = invalid
  m.lastId = 0
  m.isLiveRewind = false
  m.streamStartSeconds = invalid
  m.liveRewindDuration = invalid
  
  m.errorChannel.visible = false
  m.spinner.visible = false

  if m.videoPlayer <> invalid then
    m.videoPlayer.unobserveField("state")
    m.videoPlayer.unobserveField("position")
    m.videoPlayer.unobserveField("duration")
    m.videoPlayer.control = "stop"
  end if
  
  if not m.isLiveContent then
    position = 0
    if m.videoPlayer <> invalid and m.videoPlayer.position >= 0 then position = m.videoPlayer.position

    body = {
      watchSessionId: getWatchSessionId()
      watchToken: getWatchToken()
      allId: m.program.allId
      secondsElapsed: Fix(position)
    }
  
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlWatchEnd(m.apiUrl), "POST", "onEndWatchResponse", FormatJson(body), invalid, true)
  end if 
  
  m.program = invalid
  m.channelSelected = invalid
  
  if  m.channelList <> invalid then
    __cancelChannelPosition()
    m.guide.channelId = 0
    m.guide.items = invalid
    
    m.channelList.channelId = 0
    m.channelList.items = invalid
    m.channelList.unobserveField("selected")
  end if

  m.allowChannelList = false
  m.isLiveContent = false
  m.videoPlayer.visible = false
  if m.timelineBar <> invalid then
    m.timelineBar.visible = false
    m.timelineBar.position = 0
    m.timelineBar.duration = 0
  end if

  __hideInactivityPrompt()

  m.errorChannelTitle.text = ""
  m.errorChannelImage.uri = ""
  m.top.onBack = onBack
end sub

' Abre la lista de canales
sub __openChannelList(refreshProgressBars = true)
  m.showChannelListAfterUpdate = false
  m.channelList.refreshProgressBars = refreshProgressBars
  m.channelListContainer.visible = true
  m.channelList.positioninChannelId = true

  ' Al abrir la lista, arrancamos el timer de 40 segundos
  startHideChannelListTimer()
end sub

' Cierra la lista de canales
sub onHideChannelListTimerFired()
  ' Solo tiene sentido ocultar si está visible
  if m.channelListContainer.visible then
      m.channelListContainer.visible = false
      m.videoPlayer.setFocus(true)
  end if
end sub

sub startHideChannelListTimer()
    ' Siempre reiniciamos el timer a 40 segundos
    m.channelListTimer.control = "stop"
    m.channelListTimer.duration = 40
    m.channelListTimer.repeat = false
    m.channelListTimer.control = "start"

    m.channelListTimer.observeField("fire", "onHideChannelListTimerFired")
end sub

' Cancela la posicion del canal elejido tanto en la lista de canales como en la guia porque 
' ha ocurrido algun error al cargar el canal o se quiso cerrar la lista de canales sin elejir 
' ningun canal nuevo
sub __cancelChannelPosition()
  m.channelList.refreshProgressBars = false
  m.showChannelListAfterUpdate = false
  m.channelListContainer.visible = false

  m.videoPlayer.setFocus(true)

  if m.repositionChannnelList then
    __repositionChannelList()
  end if 
end sub

' Muestra la informacion del programa actual sobre el player y dispara un timer para escodnerla 
' automaticamente si no hay ninguna interaccion. 
sub __showProgramInfo()
  m.playerControllers.visible = true
  if m.timelineBar <> invalid and not m.isLiveContent then m.timelineBar.visible = true
  m.guideImageButton.setFocus(true)

  m.showInfoTimer.control = "start"
  m.showInfoTimer.ObserveField("fire","onHidenProgramInfo")
end sub

'Metodo que dispara la carga de un nuevo streaming en el player
sub __loadStreamingURL(key, id, streamingAction)
  m.itemSelected = invalid
  m.repositionChannnelList = false
  m.lastButtonSelect = invalid
  m.lastKey = key
  m.lastId = id
  ' Falta agregar el update Session
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.lastKey, m.lastId, streamingAction), "GET", "onStreamingsResponse") 
end sub

' Metodo que procesa el error que puede ocurrir al reproducir en el player y dispara los timers para
' las validaciones de reconexion y notifica al usuario que ha ocurrido un error. 
sub __errorProcessing()
  if (m.videoPlayer.errorCode = __getPlayerError().MEDIA_ERROR or m.videoPlayer.errorCode = __getPlayerError().UNKNOWN or m.videoPlayer.errorCode = __getPlayerError().NETWORK_ERROR) then 
    if m.lastErrorTime <> invalid then 
      clearTimer(m.retryReconnection)

      m.retryReconnection.ObserveField("fire","onValidateConnectionAndRetry")
      m.retryReconnection.control = "start"
    else 
      onValidateConnectionAndRetry()
    end if
  end if
  
  m.errorChannel.visible = true
  m.spinner.visible = true
end sub

' metofo que limpia los indicadores de la lista de canales para que esta se reposicione
sub __repositionChannelList()
    m.repositionChannnelList = false
    m.itemSelected = invalid 
    m.channelList.channelIdIndexOf = -1
    m.channelList.searchChannelPosition = true
end sub

' Enumerable con lso tipos de error.
function __getPlayerError() as Object
  return {
    NONE: 0,
    NETWORK_ERROR: -1,
    CONNECTION_TIMED_OUT: -2,
    UNKNOWN: -3,
    EMPTY_LIST: -4,
    MEDIA_ERROR: -5,
    DRM_ERROR: -6,
  }
end function

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

' Renueva el timer de que el usuario continua viendo. O se cargo una nueva url.
sub __extendTimeWatching()
  if m.streaming <> invalid and m.strea .type <> invalid
    if LCase(m.streaming.type) = getVideoType().LIVE or LCase(m.streaming.type) = getVideoType().LIVE_REWIND

      if m.inactivityPromptTimeInSeconds <> -1
        if (m.inactivityPrompt <> invalid)
          
        end if
       
      else 
        if (m.inactivityPrompt <> invalid)
        end if
      end if
    else
      if (m.inactivityPrompt <> invalid)
      end if
    end if
  end if
end sub

' Reconectar el stream automáticamente
sub __reconnectStream() 
  __loadStreamingURL(m.lastKey, m.lastId, getStreamingAction().PLAY)
end sub


sub __togglePlayPause()
  if m.videoPlayer = invalid then return

  state = m.videoPlayer.state

  ' Si está reproduciendo => pausar
  if state = "playing" or state = "buffering" then
    m.videoPlayer.control = "pause"
    if m.playPauseImageButton <> invalid then
      m.playPauseImageButton.uri = "pkg:/images/shared/play.png"
      m.playPauseImageButton.tooltip = i18n_t(m.i18n, "player.video.play")
    end if
    return
  end if

  ' Si está pausado o detenido => reproducir
  if state = "paused" or state = "stopped" then
    m.videoPlayer.control = "play"
    if m.playPauseImageButton <> invalid then
      m.playPauseImageButton.uri = "pkg:/images/shared/pause.png"
      m.playPauseImageButton.tooltip = i18n_t(m.i18n, "player.video.pause")
    end if
    return
  end if

  ' Fallback: si no sabemos, intentamos play
  m.videoPlayer.control = "play"
end sub
