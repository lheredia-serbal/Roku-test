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
  m.seekCommitTimer = m.top.findNode("seekCommitTimer")
  m.seekHoldTimer = m.top.findNode("seekHoldTimer")
  
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
  m.connectingGroup = m.top.findNode("connectingGroup")
  m.spinnerGroup = m.top.findNode("spinnerGroup")
  m.connectingContainer = m.top.findNode("connectingContainer")
  m.errorChannel = m.top.findNode("errorChannel")
  m.spinner = m.top.findNode("spinner")
  
  m.guide = m.top.findNode("Guide")
  
  m.inactivityBackground = m.top.findNode("inactivityBackground")
  m.inactivityContent = m.top.findNode("inactivityContent")
  m.inactivityOverlay = m.top.findNode("inactivityOverlay")
  m.inactivityMessage = m.top.findNode("inactivityMessage")
  m.inactivityLogo = m.top.findNode("inactivityLogo")
  m.inactivityContinueButton = m.top.findNode("inactivityContinueButton")
  m.inactivityTimer = m.top.findNode("inactivityTimer")
  m.inactivityAutoCloseTimer = m.top.findNode("inactivityAutoCloseTimer") 
  m.timelinePreviewBg = m.top.findNode("timelinePreviewBg") 
  m.showTimeTimer = m.top.findNode("showTimeTimer")

  m.controlsRow = m.top.findNode("controlsRow")
  
  m.seekCommitTimer.ObserveField("fire", "onSeekCommitTimerFired")
  m.seekHoldTimer.ObserveField("fire", "onSeekHoldTimerFired")
  m.timelineBarBarContainer = m.timelineBar.findNode("barContainer")
  m.showTimeTimer.observeField("fire", "onShowTimeTimerFired")

  if m.timelineBar <> invalid then
    m.timelineBar.observeField("seeking", "onTimelineSeekingChanged")
    m.timelineBar.observeField("previewVisible", "onTimelinePreviewChanged")
    m.timelineBar.observeField("previewX", "onTimelinePreviewChanged")
    m.timelineBar.observeField("previewY", "onTimelinePreviewChanged")
    m.timelineBar.observeField("previewUri", "onTimelinePreviewChanged")
  end if
  
  m.timelinePreviewOverlay = m.top.findNode("timelinePreviewOverlay")
  m.timelinePreviewPoster  = m.top.findNode("timelinePreviewPoster")

  m.scaleInfo = m.global.scaleInfo

  if m.global <> invalid then
    m.global.observeField("activeApiUrl", "onActiveApiUrlChanged")
  end if
  
  if m.videoPlayer <> invalid then m.videoPlayer.enableUI = false
  
  m.showChannelListAfterUpdate = false
  m.blockTuShowControls = true
  m.channelSelected = invalid
  m.allowChannelList = true
  m.isLiveContent = false
  m.isLiveRewind = false
  m.streamStartSeconds = invalid
  m.liveRewindDuration = invalid
  m.liveRewindMinDuration = invalid
  m.currentStreamType = invalid
  m.lastPosition = invalid
  m.actionPostChageState = invalid
  m.isReloadStreaming = false

  m.reloadInputBlockUntilMs = -1 ' tiempo limite (ms) para bloquear entradas tras recargar stream
  m.keyEventDebounceMs = 180 ' ventana minima entre eventos de la misma tecla
  m.lastKeyPressed = invalid ' guarda la ultima tecla presionada para anti-rebote
  m.lastKeyPressedAtMs = -999999 ' timestamp de la ultima tecla procesada
  m.keyEventClock = CreateObject("roTimespan") ' reloj monotónico para medir ms
  m.keyEventClock.Mark() ' inicia el reloj para lectura de tiempos relativos

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

  m.pendingSeekActive = false
  m.pendingSeekPosition = invalid

  m.saveOpenPlayer = true
  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0

  m.previewPinned = false
  m.endPlayerFrozen = invalid
  m.initStreeamingType = invalid
  m.pauseOnSeekActive = false
  m.disableLayoutChannelConnection = false

  ' --- Tap acceleration (FF/RW) ---
  m.trickTapWindowMs = 1000
  m.trickTapMaxMult = 6   ' ajustá a gusto (6x, 8x, etc)

  m.trickClock = CreateObject("roTimespan")
  m.trickClock.Mark()

  m.lastTrickKey = invalid
  m.lastTrickMs  = -999999
  m.trickTapCount = 0

  ' Base jump para el hold (se recalcula en cada start)
  m.seekHoldBaseJump = 0

  __ensurePreviewTimeNodes()
end sub

' Funcion que interpreta los eventos de teclado y retorna true si fue porcesada por este componente. Sino es porcesado por el
' entonces sigue con el siguente metodo onKeyEvent del compoente superior
function onKeyEvent(key as String, press as Boolean) as Boolean

  nowMs = __getNowMilliseconds() ' timestamp actual en milisegundos para filtros de entrada

  ' Bloquea eventos mientras se esta recargando o por una pequeña ventana posterior
  if m.reloadInputBlockUntilMs <> invalid and nowMs < m.reloadInputBlockUntilMs then return true ' descarta eventos en la ventana de bloqueo

  ' Si esta refrescando el url del stream, bloquear todos los botones
  if m.isReloadStreaming then return true ' corta inmediatamente cualquier accion mientras recarga

  ' Ignora repeticiones muy seguidas del mismo boton (key repeat del control remoto)
  if press and __isRepeatedKeyPress(key, nowMs) then return true ' evita key-repeat por spam de remoto
  handled = false

  if press and key = KeyButtons().REPLAY then
    handled = true

    if m.streaming <> invalid and LCase(m.streaming.type) = getVideoType().LIVE then return true ' si es cotenido vivo no hace nada

    __replayBack(20)
    __restartShowInfoTimer()

    ' si el program info está visible, mandar foco al timelinebar
    if m.playerControllers <> invalid and m.playerControllers.visible = true then
      if m.timelineBar <> invalid and m.timelineBar.visible = true then m.timelineBar.setFocus(true)
    end if
  end if
  

  if key = KeyButtons().PLAY then
    handled = true

    if m.streaming <> invalid and LCase(m.streaming.type) = getVideoType().LIVE then return true ' si es cotenido vivo no hace nada

    if m.streaming <> invalid and LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT then
      m.currentStreamType = getStreamingType().LIVE_REWIND
      m.actionPostChageState = "pause"

      __reconnectStream()
      __showProgramInfo()
    end if
  end if
  
  
  if m.inactivityContinueButton.isInFocusChain() then

    handled = true

    if press and (key = KeyButtons().OK or key = KeyButtons().BACK or KeyButtons().UP or KeyButtons().DOWN or KeyButtons().RIGHT or KeyButtons().LEFT) then
      __hideInactivityPrompt()
      __extendTimeWatching()

      __reconnectStream()
    end if

    return handled
  else if m.videoPlayer.isInFocusChain() and key = KeyButtons().BACK then
    if press then 
      __closePlayer()
      handled = false

      actionLog = getActionLog({ actionCode: ActionLogCode().CLOSE_PLAYER, program: m.program })
      __saveActionLog(actionLog)
    else 
      handled = true
    end if
  
  else if m.playerControllers.isInFocusChain() and key = KeyButtons().BACK then
    if press then onHidenProgramInfo()
    handled = true
    
  else if m.playerControllers.isInFocusChain() and key = KeyButtons().UP then
    __restartShowInfoTimer()
    if not press and m.timelineBar <> invalid and m.timelineBar.visible then m.timelineBar.setFocus(true)

  else if m.guideImageButton.isInFocusChain() then
    if press then __restartShowInfoTimer()

    if key = KeyButtons().OK and press then
      if m.showInfoTimer <> invalid then clearTimer(m.showInfoTimer)
      if m.playerControllers.visible then m.playerControllers.visible = false
      m.guide.visible = true
      m.guide.setFocus(true)
      m.guide.positioninChannelId = true

      actionLog = getActionLog({ actionCode: ActionLogCode().OPEN_PAGE, pageUrl: "Epg" })
      __saveActionLog(actionLog)
    end if

    if key = KeyButtons().UP and m.timelineBar.visible = true and press then m.timelineBar.setFocus(true)

    if key = KeyButtons().LEFT and press then
      if m.guideImageButton.focusLeft <> invalid then 
        if m.guideImageButton.focusLeft.disable then 
          if m.guideImageButton.focusLeft.focusLeft <> invalid then m.guideImageButton.focusLeft.focusLeft.setFocus(true) 
        else
          m.guideImageButton.focusLeft.setFocus(true)
        end if
      end if
    end if

    handled = true

  else if m.toLiveImageButton <> invalid and m.toLiveImageButton.isInFocusChain() then
    __restartShowInfoTimer()
    if key = KeyButtons().LEFT and m.toLiveImageButton.focusLeft <> invalid and press then
      m.toLiveImageButton.focusLeft.setFocus(true)
    end if

    if key = KeyButtons().RIGHT and m.toLiveImageButton.focusRight <> invalid and press then
      m.toLiveImageButton.focusRight.setFocus(true)
    end if

    if m.toLiveImageButton.isInFocusChain() and key = KeyButtons().OK then
      if m.isLiveRewind and m.videoPlayer <> invalid  and press then
        if LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().LIVE_REWIND then
          m.currentStreamType = getStreamingType().LIVE_REWIND

          m.timelineBar.isLive = true
          m.streaming.streamingType = getStreamingType().LIVE_REWIND
          __togglePlayPause()
          __loadStreamingURL(m.lastKey, m.lastId, getStreamingAction().PLAY, getStreamingType().DEFAULT)
          m.videoPlayer.control = "play"
        else
          ' en live-rewind, normalmente "live edge" es duration (ventana) o el final
          dur = m.timelineBar.duration
          if dur <> invalid and dur > 0 then
            m.videoPlayer.seek = dur
          end if
          m.videoPlayer.control = "play"
        end if
      end if
    end if

    handled = true

  else if m.restartImageButton <> invalid and m.restartImageButton.isInFocusChain() and press then
    if  press then __restartShowInfoTimer()
    
    if key = KeyButtons().LEFT and m.restartImageButton.focusLeft <> invalid then
      m.restartImageButton.focusLeft.setFocus(true)
    end if

    if key = KeyButtons().RIGHT and m.restartImageButton.focusRight <> invalid then
      if m.restartImageButton.focusRight.disable then
        if m.restartImageButton.focusRight.focusRight <> invalid then m.restartImageButton.focusRight.focusRight.setFocus(true)
      else
        m.restartImageButton.focusRight.setFocus(true)
      end if
    end if

    if (key = KeyButtons().OK) then
      if m.videoPlayer <> invalid then
        if LCase(m.streaming.type) = getVideoType().LIVE then return true

        if LCase(m.streaming.type) = getVideoType().LIVE_REWIND then
          useStartPid = false
          reloadWithinWindow = false

          if m.program <> invalid and m.program.startTime <> invalid and m.program.id <> invalid and m.program.id <> 0 and m.liveRewindDuration <> invalid then
            programStartDate = toDateTime(m.program.startTime)
            if programStartDate <> invalid then
              startLimit = dtCloneAddSeconds(getMomentNow(), -Int(m.liveRewindDuration))
              if dtIsBefore(programStartDate, startLimit) then useStartPid = true
            end if
          end if
          if m.liveRewindMinDuration <> invalid and m.liveRewindDuration <> invalid and m.liveRewindMinDuration <> m.liveRewindDuration then
            reloadWithinWindow = true
          end if

          if useStartPid then
            m.currentStreamType = getStreamingType().LIVE_REWIND
            m.streaming.streamingType = getStreamingType().LIVE_REWIND
            __togglePlayPause()
            m.disableLayoutChannelConnection = true
            __loadStreamingURL(m.lastKey, m.lastId, getStreamingAction().PLAY, getStreamingType().LIVE_REWIND, m.program.id)
            m.actionPostChageState = "restart"

          else if reloadWithinWindow then
            m.currentStreamType = getStreamingType().LIVE_REWIND
            m.streaming.streamingType = getStreamingType().LIVE_REWIND
            __togglePlayPause()
            m.disableLayoutChannelConnection = true
            __loadStreamingURL(m.lastKey, m.lastId, getStreamingAction().PLAY, getStreamingType().LIVE_REWIND)
            m.actionPostChageState = "restart"

          else if m.streaming.streamingType = getStreamingType().DEFAULT then

            m.streaming.streamingType = getStreamingType().LIVE_REWIND
            __togglePlayPause()
            __reconnectStream()
            m.actionPostChageState = "restart"

          else if m.streaming.streamingType = getStreamingType().LIVE_REWIND
          __restartVideo()
          end if
        else
          m.videoPlayer.control = "pause" ' opcional, evita saltos visuales
          m.videoPlayer.seek = 0
          m.videoPlayer.control = "play"
        end if
      end if
    end if

    handled = true

  else if m.playPauseImageButton.isInFocusChain() then    
    if press then
      __restartShowInfoTimer()
      if key = KeyButtons().RIGHT and m.playPauseImageButton.focusRight <> invalid then
          m.playPauseImageButton.focusRight.setFocus(true)
        else if (key = KeyButtons().OK) and not LCase(m.streaming.type) = getVideoType().LIVE then
          if LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT then
            m.currentStreamType = getStreamingType().LIVE_REWIND
            m.actionPostChageState = "pause"
            __reconnectStream()
          else
            __togglePlayPause()
          end if
      end if
    end if
    handled = true
  
  else if m.videoPlayer.isInFocusChain() and key = KeyButtons().OK and not handled then
    ' Bloquea los casos de click sobre el player hasta que la informacion 
    ' del programa haya contenstado al menos una vez por ok o error
    if m.blockTuShowControls then return true

    if not press and not m.focusplayerByload then 
      __showProgramInfo()
    else 
      m.focusplayerByload = false
    end if

    handled = true
    
  else if m.timelineBar <> invalid and m.timelineBar.isInFocusChain() and key = KeyButtons().OK and not handled then
    handled = true

    if press then
    ' Evitar doble commit
    if m.seekCommitTimer <> invalid then m.seekCommitTimer.control = "stop"

    ' (opcional pero recomendado) si estaba en hold, lo cortamos
    if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"
    m.seekHoldActive = false
    m.seekHoldKey = invalid
    m.seekHoldTicks = 0

    ' Commit inmediato (misma lógica del timer)
    __commitPendingSeek()
    if m.timelineBar <> invalid then
      m.timelineBar.seekCommitToken = m.timelineBar.seekCommitToken + 1
    end if

    ' Salir de modo seeking
    if m.timelineBar <> invalid then m.timelineBar.seeking = false

    ' Ocultar miniatura y volver a mostrar programInfo/summary
    m.previewPinned = false
    if m.timelinePreviewOverlay <> invalid then m.timelinePreviewOverlay.visible = false
    __setSeekUi(false) ' esto deja opacity=1 al programSummaryPlayer
    if m.programSummaryPlayer <> invalid then m.programSummaryPlayer.visible = true
  end if

  else if m.timelineBar.isInFocusChain() and __isSeekKey(key) then
    handled = true

    if LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT then
      m.currentStreamType = getStreamingType().LIVE_REWIND
      m.actionPostChageState = "pause"
      __reconnectStream()
    else
      if (not m.isReloadStreaming)
        if press then
          __startSeekHold(key)  ' <- 1 salto inmediato + timer repetitivo
        else
          __stopSeekHold()      ' <- al soltar, deja el debounce para commit
        end if
      end if
    end if

  else if m.videoPlayer.isInFocusChain() and __isSeekKey(key) then
    handled = true
    __showProgramInfo()

    if (not m.isReloadStreaming) then
      if m.streaming <> invalid and LCase(m.streaming.type) = getVideoType().LIVE then return true ' si es cotenido vivo no hace nada
      if not press and not m.focusplayerByload then 
        m.timelineBar.setFocus(true)
      else 
        m.focusplayerByload = false
      end if
    end if

  else if m.timelineBar <> invalid and m.timelineBar.isInFocusChain() and key = KeyButtons().DOWN then
    if not press then
      __restartShowInfoTimer()
      ' Si había miniatura (pinneada o visible), la cerramos y volvemos al summary
      if m.previewPinned or (m.timelinePreviewOverlay <> invalid and m.timelinePreviewOverlay.visible) then
        m.previewPinned = false

        if m.timelinePreviewOverlay <> invalid then
          m.timelinePreviewOverlay.visible = false
        end if

        ' salimos del modo seeking para que no vuelva a esconder el summary
        m.timelineBar.seeking = false

        __setSeekUi(false) ' esto te pone opacity=1 y/o el estado normal
        if m.programSummaryPlayer <> invalid then
          m.programSummaryPlayer.visible = true
          m.programSummaryPlayer.opacity = 1
        end if
      end if

      btn = __getFirstVisibleControllerButton()
      if btn <> invalid then btn.setFocus(true)
    end if
    if not press then __cancelPendingSeek()

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

  return handled
end function

' Devuelve tiempo monotónico en ms para controlar ventanas de bloqueo/debounce
function __getNowMilliseconds() as Integer
  if m.keyEventClock = invalid then
    m.keyEventClock = CreateObject("roTimespan")
    m.keyEventClock.Mark()
  end if

  return m.keyEventClock.TotalMilliseconds() ' ms transcurridos desde Mark()
end function

' Determina si una pulsacion es repetida dentro de la ventana de debounce
function __isRepeatedKeyPress(key as String, nowMs as Integer) as Boolean
  if m.lastKeyPressed = key and (nowMs - m.lastKeyPressedAtMs) < m.keyEventDebounceMs then ' mismo boton en muy poco tiempo
    return true
  end if

  m.lastKeyPressed = key ' actualiza la ultima tecla valida
  m.lastKeyPressedAtMs = nowMs ' actualiza el tiempo de la ultima tecla valida
  return false
end function


' Carga los datos de componente, si no recibe datos o los recibe vacios entonces dispara la limpieza del componete
sub initData()
  if m.top.data <> invalid and m.top.data <> "" then 
    __applyTranslations()
    __configurePlayer()
    m.streaming = ParseJson(m.top.data)
    m.disableLayoutChannelConnection = false
    m.errorChannel.visible = false
    m.spinner.visible = false
    m.itemSelected = invalid
    m.repositionChannnelList = false
    m.lastKey = m.streaming.key
    m.lastId = m.streaming.id
    m.streamingType = m.streaming.streamingType
    openGuide = m.top.openGuide
    m.top.openGuide = false
    
    m.guide.loading = m.top.loading
    
    m.videoPlayer.observeField("state", "OnVideoPlayerStateChange")
    
    __initVariables()
    
    if m.streaming.type <> invalid and m.streaming.type <> "" then
      streamType = LCase(m.streaming.type)
      m.initStreeamingType = streamType
      if streamType = getVideoType().LIVE then
        m.allowChannelList = true
        m.isLiveContent = true
        m.isLiveRewind = false
        m.isVodContent  = false
      else if streamType = getVideoType().LIVE_REWIND
        m.allowChannelList = true
        m.isLiveContent = false
        m.isLiveRewind = true
        m.isVodContent  = false
      else
        m.allowChannelList = false
        m.isLiveContent = false
        m.isLiveRewind = false
        m.isVodContent  = true
      end if
    end if

    __setTimelineFromStreaming()
    __rebuildControllerButtons()

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
      if m.timelineBar <> invalid then m.timelineBar.visible = true
    else
      if m.timelineBar <> invalid then
        m.timelineBar.visible = false
      end if
    end if

    __applyControlsVisibility()

    ' Si debe reconectar automaticamente o preguntar al usuario si esta ahi
    m.inactivityPromptEnabled = (getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_ENABLED, 0) = 1)
    ' Cuanto tiempo espera para redirigir
    m.inactivityPromptDurationInSeconds = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_DURATION_IN_SECONDS, -1)
    ' Cuanto espera para mostrar el cartel 
    m.inactivityPromptTimeInSeconds = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_TIME_IN_SECONDS, -1)

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

    ' Pasar template de thumbnails a TimelineBar
    if m.timelineBar <> invalid and m.streaming <> invalid then
      if m.streaming.thumbnailsUrl <> invalid then
        m.timelineBar.thumbnailsUrl = m.streaming.thumbnailsUrl
      else
        m.timelineBar.thumbnailsUrl = ""
      end if
    end if

    if m.timelineBar <> invalid then
      isLiveTimeline = (LCase(m.streaming.type) = getVideoType().LIVE) or (LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT)
      m.timelineBar.isLive = isLiveTimeline
    end if
  end if
end sub

' Mostrar el modal de inactividad
sub onInactivityTimerFired()
  if m.inactivityOverlay <> invalid then

    if m.inactivityPromptEnabled then
      m.inactivityOverlay.visible = true
      __startInactivityAutoCloseTimer()
      if m.inactivityContinueButton <> invalid then m.inactivityContinueButton.setFocus(true)
    else 
      __reconnectStream()
    end if
  end if
end sub

' Cuando pasa un tiempo mientras se muestra el modal de inactividad sin que el usuario hay presionado una botón, cerrar el player
sub onInactivityAutoCloseTimerFired()
  if m.inactivityOverlay <> invalid and m.inactivityOverlay.visible then __closePlayer(true)
end sub

sub onShowTimeTimerFired()
  __showTimeToEnd()
end sub

' Dispara el evento de deslogueo
sub onLogoutEvent()
  if m.guide.logout then 
    onHidenProgramInfo()
    m.focusplayerByload = true
    m.guide.visible = false
    m.guide.logout = false
    m.top.logout = true
  end if 
end sub

' Dispara el evento de deslogueo
sub onLogoutChange()
  if m.top.logout then 
    __closePlayer(false, true)
  end if 
end sub

' Procesa la respuesta de la lista de  canales
sub onChannelsResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      if  m.channelList <> invalid then m.channelList.items = invalid

      m.guide.channelId = m.channelSelected.id

      m.guide.items = resp.data

      m.channelList.channelId = m.channelSelected.id
      m.channelList.items = resp.data

      if m.showChannelListAfterUpdate then
        __openChannelList(false)
      end if
    else
      if m.showChannelListAfterUpdate then m.showChannelListAfterUpdate = false 
      printError("ChannelsList Emty:", m.apiRequestManager.response)
    end if 
  else
    if not m.apiRequestManager.serverError then
      error = m.apiRequestManager.errorResponse
      statusCode = m.apiRequestManager.statusCode
      m.apiRequestManager = clearApiRequest(m.apiRequestManager) 

      printError("ChannelsList:", error)
      
      if validateLogout(statusCode, m.top) then return
      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)
      if m.showChannelListAfterUpdate then m.showChannelListAfterUpdate = false 
    end if
  end if
end sub

' Metodo que se dispiara por los cambios de estado del player
Sub OnVideoPlayerStateChange()
  if m.videoPlayer = invalid then return
    state = m.videoPlayer.state

  if state = "error" then
    __errorProcessing()
    return
  end if

  if state = "buffering" then
    if not m.disableLayoutChannelConnection then 
      m.errorChannel.visible = true
      m.spinner.visible = true
    end if
  else
    m.errorChannel.visible = false
    m.spinner.visible = false
  end if

  if state = "paused" then
    if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/play.png"
  else if state = "playing" then
    clearTimer(m.retryReconnection)
    m.lastErrorTime = invalid

    if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/pause.png"
  end if

  if m.actionPostChageState <> invalid then
    if m.actionPostChageState = "pause" and state = "playing" then
      m.disableLayoutChannelConnection = false
      __togglePlayPause()
      m.actionPostChageState = invalid
    end if
  end if

  if m.timelineBar <> invalid then
    m.timelineBar.isPaused = (state = "paused")
  end if
End Sub

' Metodo que actualiza la linea de tiempo cuando cambia la posicion del video
sub onVideoPositionChanged()
  if (m.videoPlayer.position = 0) then return 
  __updateTimeline()
end sub

' Metodo que actualiza la linea de tiempo cuando cambia la duracion del video
sub onVideoDurationChanged()
  if (m.videoPlayer.duration = 0) then return 
  if (m.streaming = invalid) then return 
  if (LCase(m.streaming.type) = getVideoType().LIVE) then return 
  if (LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT) then return 
  __updateTimeline()
end sub

sub onUpdateWatchSessionResponse()
  if validateStatusCode(m.apiSessionRequestManager.statusCode) then
    resp = ParseJson(m.apiSessionRequestManager.response)
    if resp.data <> invalid then
      if resp.data.watchToken <> invalid then setWatchToken(resp.data.watchToken)
      if resp.data.watchSessionId <> invalid then setWatchSessionId(resp.data.watchSessionId)
    else
    printError("WatchSesionToken:", m.apiRequestManager.errorResponse)
    end if
  else
    if not m.apiRequestManager.serverError then
      statusCode = m.apiSessionRequestManager.statusCode
      printError("WatchSesionToken:", m.apiRequestManager.errorResponse)
      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)
    end if
  end if  
end sub

' Metodo que se dispiara por la seleccion de un canal desde la lista de canales
sub onSelectItemChannelList() 
  if m.channelList <> invalid and m.channelList.isInFocusChain() then
    m.disableLayoutChannelConnection = false
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
        m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
      else
        m.channelList.selected = invalid 
        __refreshWatchTokenData(itemSelected.redirectKey, itemSelected.redirectId)
        __loadStreamingURL(itemSelected.redirectKey, itemSelected.redirectId, getStreamingAction().PLAY)
      end if 
    end if
  end if
end sub

' Metodo que se dispiara por la seleccion de un item desde la Guia
sub onSelectItemGuide() 
  if m.guide <> invalid and m.guide.isInFocusChain() then
    m.disableLayoutChannelConnection = false
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
      __refreshWatchTokenData(itemSelected.redirectKey, itemSelected.redirectId)
      __loadStreamingURL(itemSelected.redirectKey, itemSelected.redirectId, streamingAction)
    end if
  end if
end sub

' Procesa la respuesta al obtener la url de lo que se quiere ver
sub onStreamingsResponse() 
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then

      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      m.videoPlayer.control = "stop" 
      m.videoPlayer.content = invalid

      streaming = resp.data
      streaming.key = m.lastKey 
      streaming.id = m.lastId
      streaming.streamingType = m.newStreamingType

      m.streaming = streaming
      streamType = ""
      isLiveTimeline = false
      
      if m.streaming.type <> invalid and m.streaming.type <> "" then
        streamType = LCase(m.streaming.type)
        if streamType = getVideoType().LIVE then
          m.isLiveContent = true
          m.isLiveRewind = false
          m.isVodContent  = false
          if (m.streaming.streamingType = getStreamingType().DEFAULT) then isLiveTimeline = true
        else if streamType = getVideoType().LIVE_REWIND
          m.isLiveContent = false
          m.isLiveRewind = true
          m.isVodContent  = false
          if (m.streaming.streamingType = getStreamingType().DEFAULT) then isLiveTimeline = true  
        else
          m.isLiveContent = false
          m.isLiveRewind = false
          m.isVodContent  = true
        end if
      end if

      if m.timelineBar <> invalid then
        m.timelineBar.streamType = m.newStreamingType
        m.timelineBar.isLive = isLiveTimeline  
      end if
      
      __setTimelineFromStreaming()
      __rebuildControllerButtons()
      
      if m.toLiveImageButton <> invalid and m.toLiveImageButton.visible 
        if isLiveTimeline then 
          m.toLiveImageButton.disable = true
        else
          m.toLiveImageButton.disable = false
      end if
    end if

    if m.timelineBar <> invalid then
      if not m.isLiveContent then
        m.timelineBar.visible = true
      else
        m.timelineBar.visible = false
        m.timelineBar.position = 0
        m.timelineBar.duration = 0
      end if

      if m.streaming.thumbnailsUrl <> invalid then
        m.timelineBar.thumbnailsUrl = m.streaming.thumbnailsUrl
      else
        m.timelineBar.thumbnailsUrl = ""
      end if
    end if

    m.currentStreamType = m.streaming.streamingType

    m.errorChannel.visible = false
    m.spinner.visible = false

      if m.streaming <> invalid and m.streaming.streamStartDate <> invalid and m.streaming.streamStartDate <> "" then
        m.streamStartDate = toDateTime(m.streaming.streamStartDate)
        if m.streamStartDate = invalid then return

        if m.lastId <> 0 then
          if streamType = getVideoType().LIVE_REWIND then
            m.endPlayerFrozen = getMomentNow()
            m.startPlayerFrozen = dtCloneAddSeconds(m.endPlayerFrozen, -Int(m.liveRewindDuration))
           m.diffDuration = __getDiffStartPlay()
          end if 
        end if
      end if

     __loadPlayer(streaming, false)

      ' Si estoy cambiando la url del Live por la de Rewind entonces no es necesario reposicionar la guia y la lista de canales
     if (m.streaming.streamingType = getStreamingType().DEFAULT) then
        if (m.guide <> invalid and m.channelSelected <> invalid and m.guide.channelId = m.channelSelected.id) then
          m.guide.channelIdIndexOf = -1
          m.guide.searchChannelPosition = true
        end if 
        
        __saveLastWatched()
      end if 
      
      if m.actionPostChageState = "restart" then
        __restartVideo()
        m.actionPostChageState = invalid
      end if
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
    if not m.apiRequestManager.serverError then
      errorResponse = m.apiRequestManager.errorResponse
      statusCode = m.apiRequestManager.statusCode
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      printError("Streamings:", errorResponse)
      
      if validateLogout(statusCode, m.top) then return

      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)

      if m.lastErrorTime <> invalid then 
        clearTimer(m.retryReconnection)

        m.retryReconnection.ObserveField("fire","onValidateConnectionAndRetry")
        m.retryReconnection.control = "start"
      end if
    end if
  end if
end sub

' Procesa la respuesta al obtener el Summary de un programa
sub onProgramSummaryResponse()
  m.blockTuShowControls = false

  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      fistLoad = false
      if m.program = invalid then fistLoad = true
      __loadProgramInfo(resp.data)
      __getChannels(fistLoad)
    else
      clearTimer(m.newProgramTimer)
      m.newProgramTimer.duration = 120
      m.newProgramTimer.ObserveField("fire","onGetNewProgramInfo")
      m.newProgramTimer.control = "start"

      printError("ProgramSumary Empty:", errorResponse)
    end if 
  else
    if not m.apiRequestManager.serverError then
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      printError("ProgramSumary:", errorResponse)
      
      if validateLogout(statusCode, m.top) then return

      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)

      if statusCode >= 400 and statusCode <= 599 then  
        clearTimer(m.newProgramTimer)
        m.newProgramTimer.duration = 120
        m.newProgramTimer.ObserveField("fire","onGetNewProgramInfo")
        m.newProgramTimer.control = "start"
      end if
    end if 
  end if
end sub

' Procesa la respuesta al validar la conexion contra las APIs
sub onValdiateConnectionResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    m.disableLayoutChannelConnection = false
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    
    m.lastErrorTime = now.AsSeconds() + 30 
    __loadStreamingURL(m.lastKey, m.lastId, getStreamingType().DEFAULT)
  else
    if not m.apiRequestManager.serverError then
      m.lastErrorTime = invalid
      errorResponse = m.apiRequestManager.errorResponse
      clearTimer(m.retryReconnection)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      
      m.retryReconnection.ObserveField("fire","onValidateConnectionAndRetry")
      m.retryReconnection.control = "start"

      printError("Player Connection: ", errorResponse)
    end if
  end if
end sub

' Metodo que procesa la validacion de errores de conexion y toma la accion pertinente.
sub onValidateConnectionAndRetry()
  now = CreateObject("roDateTime")
  now.ToLocalTime()
 
  if  m.lastErrorTime <> invalid and now.asSeconds() < m.lastErrorTime then
    m.disableLayoutChannelConnection = false
    __loadStreamingURL(m.lastKey, m.lastId, getStreamingType().DEFAULT)
  else
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlHealth(m.apiUrl), "GET", "onValdiateConnectionResponse", invalid, invalid, invalid, true)
  end if
end sub

' Metodo que dispara el guardado del ultimo canal visto. La llamada a este metodo esta definida por un timer
sub onSaveLastWatched()
  if m.program <> invalid and m.program.channel <> invalid  and m.streaming <> invalid and (m.streaming.type <> invalid and m.streaming.type <> "" and (LCase(m.streaming.type) = getVideoType().LIVE) or (LCase(m.streaming.type) = getVideoType().LIVE_REWIND)) then 
    m.apiLastWatchedRequestManager = sendApiRequest(m.apiLastWatchedRequestManager, urlChannelsLastWatched(m.apiUrl), "PUT", "onLastWatchedResponse", invalid, FormatJson({ key: "ChannelId", id: m.program.channel.id }))
  end if
end sub

' Procesa la respuesta al guardado del ultimo canal vistro
sub onLastWatchedResponse()
  if validateStatusCode(m.apiLastWatchedRequestManager.statusCode) then
    m.apiLastWatchedRequestManager = clearApiRequest(m.apiLastWatchedRequestManager) 
  else 
    if not m.apiRequestManager.serverError then
      error = m.apiLastWatchedRequestManager.errorResponse
      statusCode = m.apiLastWatchedRequestManager.statusCode
      m.apiLastWatchedRequestManager = clearApiRequest(m.apiLastWatchedRequestManager) 

      printError("WatchValidate ResultCode:", error)

      if validateLogout(statusCode, m.top) then return

      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)
    end if
  end if 
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
    secondsElapsed: Int(position)
  }

  m.apiBeaconRequestManager = sendApiRequest(m.apiBeaconRequestManager, url, "POST", "onSendBeaconResponse", invalid, FormatJson(body), getWatchToken())
end sub

' procesa el guardado del beacon
sub onSendBeaconResponse()
  if validateStatusCode(m.apiBeaconRequestManager.statusCode) then
    resp = ParseJson(m.apiBeaconRequestManager.response).data
    m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
    if resp <> invalid and resp.finished <> invalid and resp.finished then
      m.top.killedMe = FormatJson(resp)
      __closePlayer(true)
    end if 
  else
    if not m.apiRequestManager.serverError then
      statusCode = m.apiBeaconRequestManager.statusCode
      errorResponse = m.apiBeaconRequestManager.errorResponse 
      m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)

      watchSessionId = getWatchSessionId()
      if statusCode = 401 then 
        requestId = createRequestId()
        m.apiBeaconRequestManager = sendApiRequest(m.apiBeaconRequestManager, urlWatchValidate(m.apiUrl, watchSessionId, m.streaming.redirectKey, m.streaming.redirectId), "GET", "onWatchValidateResponse", requestId)
      end if

      printError("onSendBeaconResponse:", errorResponse)

      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)
    end if
  end if
end sub

' Procesa la respuesta de si el ususario puede ver
sub onWatchValidateResponse()
  if validateStatusCode(m.apiBeaconRequestManager.statusCode) then
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
    if not m.apiRequestManager.serverError then
      statusCode = m.apiBeaconRequestManager.statusCode
      errorResponse = m.apiBeaconRequestManager.errorResponse
      m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
      
      printError("WatchValidate Stastus:", statusCode.toStr() + " " +  errorResponse)
      
      if validateLogout(statusCode, m.top) then return

      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)

      actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("errorWatchValidate", "PlayerComponent"), getServerErrorStack(errorResponse), m.lastKey, m.lastId)
      __saveActionLog(actionLog)
    end if
  end if
end sub

' procesa el guardado de que se dejo de ver en el player
sub onEndWatchResponse()
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  printLog("End Watch")
end sub

' Se dispara la validacion del PIN cargado en el modal
sub onPinDialogLoad()
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  m.pinDialog = invalid
  
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then 
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
    requestId = createRequestId()
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlParentalControlPin(m.apiUrl, resp.pin), "GET", "onParentalControlResponse", requestId)
  else 
    m.repositionChannnelList = true
    if m.lastButtonSelect <> invalid then m.lastButtonSelect.setFocus(true)
  end if 
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)

    if resp <> invalid and resp.data <> invalid and resp.data then
      m.channelList.selected = invalid
      m.lastButtonSelect = invalid
      __loadStreamingURL(m.itemSelected.redirectKey, m.itemSelected.redirectId, getStreamingAction().PLAY)
    else
      m.itemSelected = invalid
      m.repositionChannnelList = true
      m.top.loading.visible = false
      m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedLastFocus")
    end if
  else
    if not m.apiRequestManager.serverError then
      m.top.loading.visible = false
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      printError("ParentalControl:", statusCode.toStr() + " " +  errorResponse)
      
      if validateLogout(statusCode, m.top) then return

      ' Cambio agregado: mostrar CDN dialog desde Player cuando aplica 9000.
      __showPlayerCdnErrorDialog(statusCode, ApiType().CLIENTS_API_URL)
    end if
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
  requestId = createRequestId()
  if m.program <> invalid then
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlProgramSummary(m.apiUrl, m.program.infoKey, m.program.infoId, getCarouselImagesTypes().NONE, getCarouselImagesTypes().NONE), "GET", "onProgramSummaryResponse", requestId)
  else if m.lastKey <> invalid AND  m.lastId <> invalid then 
    m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlProgramSummary(m.apiUrl, m.lastKey, m.lastId, getCarouselImagesTypes().NONE, getCarouselImagesTypes().NONE), "GET", "onProgramSummaryResponse", requestId)
  end if
end sub

' Esconde la informacion que se muestra sobre el player
sub onHidenProgramInfo()
  m.playerControllers.visible = false
  clearTimer(m.showInfoTimer)

  ' acá recién se oculta la miniatura y vuelve el summary
  m.previewPinned = false
  if m.timelinePreviewOverlay <> invalid then m.timelinePreviewOverlay.visible = false
  __setSeekUi(false)
  __cancelPendingSeek()

  m.videoPlayer.setFocus(true)
end sub

' Cierra la lista de canales
sub onHideChannelListTimerFired()
  ' Solo tiene sentido ocultar si está visible
  if m.channelListContainer.visible then
      m.channelListContainer.visible = false
      m.videoPlayer.setFocus(true)
  end if
end sub

' Obtener el beacon token
sub onActionLogTokenResponse() 
  if not m.apiRequestManager.serverError then
    resp = ParseJson(m.apiLogRequestManager.response)
    actionLog = ParseJson(m.apiLogRequestManager.dataAux)

    setBeaconToken(resp.actionsLogToken)

    now = CreateObject("roDateTime")
    now.ToLocalTime()
    m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

    m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager) 
    __sendActionLog(actionLog)
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  if not m.apiRequestManager.serverError then
    m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
  end if
end sub

' Cambio agregado: helper activo para abrir CdnErrorDialog en Player cuando aplica.
sub __showPlayerCdnErrorDialog(statusCode as Integer, apiTypeParam as Dynamic)
  if statusCode = invalid then return
  if statusCode <> 9000 then return
  if apiTypeParam = ApiType().LOGS_API_URL then return
  if m.global = invalid or m.global.retryServiceState = invalid then return
  if m.global.retryServiceState.errorVisibleSubject <> true then return
  setCdnErrorCodeFromStatus(statusCode, apiTypeParam)
  showCdnErrorDialog(true)
end sub

sub startHideChannelListTimer()
    ' Siempre reiniciamos el timer a 40 segundos
    m.channelListTimer.control = "stop"
    m.channelListTimer.duration = 40
    m.channelListTimer.repeat = false
    m.channelListTimer.control = "start"

    m.channelListTimer.observeField("fire", "onHideChannelListTimerFired")
end sub

' Define la confgiruacion inicial de la pantalla del player.
sub __configurePlayer()
  width = m.scaleInfo.width
  height = m.scaleInfo.height

  m.videoPlayer.width = width
  m.videoPlayer.height = height
  m.videoPlayer.seekMode = "accurate"

  m.whiteColor = m.global.colors.WHITE
  m.primaryColor = m.global.colors.PRIMARY
  m.grayColor = m.global.colors.LIGHT_GRAY

  m.backgroundControllers.width = width
  m.backgroundControllers.height = height
  m.backgroundControllers.loadWidth = width
  m.backgroundControllers.loadHeight = height
  
  if m.timelineBar <> invalid then
    m.timelineBar.widthBar = width - scaleValue(160, m.scaleInfo)
    m.timelineBar.translation = [0, 0]
  end if

  m.selectedIndicator.size = scaleSize([280, 110], m.scaleInfo)
  m.selectedIndicator.translation = scaleSize([0, 126], m.scaleInfo)

  m.programInfo.translation = [scaleValue(80, m.scaleInfo), (height - scaleValue(50, m.scaleInfo))]
  m.channelListContainer.translation = [(width - scaleValue(330, m.scaleInfo)), 0]

  m.programSummaryPlayer.initConfig = true

  m.errorChannel.translation = [((m.scaleInfo.width - scaleValue(320, m.scaleInfo)) / 2), (m.scaleInfo.height - scaleValue(130, m.scaleInfo)) / 2]

  m.connectingGroup.width = scaleValue(320, m.scaleInfo)
  m.connectingGroup.height = scaleValue(130, m.scaleInfo)

  m.spinnerGroup.translation = scaleSize([145, 95], m.scaleInfo)

  m.connectingContainer.translation = scaleSize([25, 25], m.scaleInfo)
  
  m.errorChannelImage.width = scaleValue(70, m.scaleInfo)
  m.errorChannelImage.height = scaleValue(70, m.scaleInfo)

  m.inactivityBackground.width = scaleValue(640, m.scaleInfo)
  m.inactivityBackground.height = scaleValue(320, m.scaleInfo)

  m.inactivityContent.translation = scaleSize([320, 32], m.scaleInfo)
  m.inactivityOverlay.translation = [((m.scaleInfo.width - scaleValue(640, m.scaleInfo)) / 2), ( m.scaleInfo.height - scaleValue(320, m.scaleInfo)) / 2]

  
  m.inactivityContent.itemSpacings = scaleSize([32, 32], m.scaleInfo)

  m.inactivityLogo.width = scaleValue(286, m.scaleInfo)
  m.inactivityLogo.height = scaleValue(100, m.scaleInfo)

  m.inactivityMessage.width = scaleValue(640, m.scaleInfo)

  m.channelList.ObserveField("selected", "onSelectItemChannelList")
  m.guide.ObserveField("selected", "onSelectItemGuide")
  m.guide.ObserveField("logout", "onLogoutEvent")
end sub

' Carga el streaming que se reproducira en el player.
sub __loadPlayer(streaming, focusPlayer = true)
  videoContent = createObject("RoSGNode", "ContentNode")

  if streaming <> invalid then
    videoContent.url = streaming.playUrl 
    videoContent.title = ""
    videoContent.live = m.isLiveContent

    m.currentStreamType = streaming.streamingType

    if streaming.streamFormat.id = getStreamingFormat().HLS then 
      videoContent.streamformat = getVideoContentStreamformat().HLS
    else if streaming.streamFormat.id = getStreamingFormat().DASH
      videoContent.streamformat = getVideoContentStreamformat().DASH
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

    m.videoPlayer.control = "play" ' start playback

    if not m.isLiveContent then
      if m.lastPosition <> invalid then
        m.videoPlayer.seek = m.lastPosition
        m.lastPosition = invalid
      else
        m.videoPlayer.seek = m.streaming.startAt
      end if
    end if

    __updateTimeline()

    ' Si estoy cambiando la url del Live por la de Rewind entonces no es necesario dispara la busuqeda del programa de nuevo
    if (m.streaming.streamingType = getStreamingType().DEFAULT) then
      requestId = createRequestId()
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlProgramSummary(m.apiUrl, streaming.key, streaming.id, getCarouselImagesTypes().NONE, getCarouselImagesTypes().NONE), "GET", "onProgramSummaryResponse", requestId)
    end if
    
    if m.inactivityPromptTimeInSeconds <> -1 then __extendTimeWatching()
    m.isReloadStreaming = false
    m.reloadInputBlockUntilMs = __getNowMilliseconds() + 350
  end if
end sub

' Inicializa las vatiables de las URL que se usaran en esta pantalla.
sub __initVariables()
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL) 
  if m.apiBeaconUrl = invalid then m.apiBeaconUrl = getConfigVariable(m.global.configVariablesKeys.BEACON_URL) 
  ' Si debe reconectar automaticamente o preguntar al usuario si esta ahi
  if m.inactivityPromptEnabled = invalid then m.inactivityPromptEnabled = (getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_ENABLED, 0) = 1)
  ' Cuanto tiempo espera para redirigir 
  if m.inactivityPromptDurationInSeconds = invalid then m.inactivityPromptDurationInSeconds = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_DURATION_IN_SECONDS, -1)
  ' Cuanto espera para mostrar el cartel 
  if m.inactivityPromptTimeInSeconds = invalid then m.inactivityPromptTimeInSeconds = getIntValueConfigVariable(EqvAppConfigVariable().INACTIVITY_PROMPT_TIME_IN_SECONDS, -1)
end sub

' Configura datos base de la linea de tiempo segun el streaming recibido
sub __setTimelineFromStreaming()
  if m.timelineBar = invalid then return

  m.timelineBar.visible = false
  m.timelineBar.baseEpochSeconds = invalid
  m.timelineBar.position = -1
  m.liveRewindDuration = invalid
  m.liveRewindMinDuration = invalid
  m.streamStartSeconds = invalid

  if m.streaming = invalid then return

  if m.streaming.streamStartDate <> invalid and m.streaming.streamStartDate <> "" then
    m.streamStartSeconds = __parseIsoToSeconds(m.streaming.streamStartDate)
  end if

  if m.streaming.liveRewindDuration <> invalid and m.streaming.liveRewindDuration > 0 then
    m.liveRewindDuration = m.streaming.liveRewindDuration
    m.liveRewindMinDuration = m.streaming.liveRewindMinDuration
    m.timelineBar.duration = m.liveRewindDuration
  else if m.streaming.duration <> invalid and m.streaming.duration > 0 then
    m.timelineBar.duration = m.streaming.duration
  else 
    m.timelineBar.duration = -1
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

  if m.timelineBar <> invalid then
    m.timelineBar.baseEpochSeconds = m.streamStartSeconds
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

' Ocultar el modal de inactividad
sub __hideInactivityPrompt(logout = false)
  if m.inactivityAutoCloseTimer <> invalid then m.inactivityAutoCloseTimer.control = "stop"

  if m.inactivityOverlay <> invalid then
    wasVisible = m.inactivityOverlay.visible
    m.inactivityOverlay.visible = false
    if not logout and wasVisible and m.videoPlayer <> invalid then m.videoPlayer.setFocus(true)
  end if
end sub

' Convierte iso to seconds.
function __parseIsoToSeconds(dateString as String) as dynamic
  if dateString = invalid or dateString = "" then return invalid

  dt = CreateObject("roDateTime")
  dt.FromISO8601String(dateString)
  dt.ToLocalTime()
  return dt.AsSeconds()
end function

' Dispara la busqueda de la lista de canales 
sub __getChannels(getNewChannels = true)
  requestId = createRequestId()
  if getNewChannels then m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlChannels(m.apiUrl), "GET", "onChannelsResponse", requestId)
end sub

' Carga la informacion del programa actual en pantalla
sub __loadProgramInfo(program)
  clearTimer(m.newProgramTimer)
  m.program = program

  if m.program.channel <> invalid then 
    m.channelSelected = m.program.channel
    m.channelList.channelId = m.channelSelected.id
    m.guide.channelId = m.channelSelected.id

    if m.saveOpenPlayer then 
      actionLog = getActionLog({ actionCode: ActionLogCode().OPEN_PLAYER, program: m.program, contentType: m.streaming.type })
      __saveActionLog(actionLog)
      m.saveOpenPlayer = false
    end if 
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
    
    programNode.programTime = dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours"))
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

  if m.program.remainingInSeconds <> invalid then 
    ' Si el tiempo es cero entonces no realizo la busqueda de un nuevo programa por estar en un VOD
    time = 0

    if m.program.remainingInSeconds > 0 then
      ' Si el tiempo es mayor a cero le agrego un tiempo de gracia para la proxima busqueda
      time = m.program.remainingInSeconds + 5
    else
      ' Si el tiempo es menor o igual a cero valido que sea u nprograma en vivo
      if programNode.endSeconds >= now.asSeconds() AND programNode.startSeconds <= now.asSeconds() then
        ' Si es un programa en vivo entocnes defino un tiempo por defecto de la proxima busqueda
        time = 1800
      end if
    end if

    if time > 0 then
      m.newProgramTimer.duration = time
      m.newProgramTimer.ObserveField("fire","onGetNewProgramInfo")
      m.newProgramTimer.control = "start"
    end if
  end if 
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
  if m.streaming = invalid or (m.streaming <> invalid and LCase(m.streaming.type) = getVideoType().LIVE) then return
  if m.streaming <> invalid and LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT then return

  if m.timelineBar = invalid or m.isLiveContent or m.videoPlayer = invalid then return

  ' si hay seek pendiente, mantenemos el preview y no pisamos con position real
  if m.pendingSeekActive and m.pendingSeekPosition <> invalid then
    dur = m.videoPlayer.duration
    if m.isLiveRewind and m.liveRewindDuration <> invalid then dur = m.liveRewindDuration
    if dur = invalid or dur <= 0 then dur = m.timelineBar.duration
    if dur <> invalid and dur > 0 then m.timelineBar.duration = dur

    m.timelineBar.position = m.pendingSeekPosition
    return
  end if

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

  if position <> invalid and position >= 0 then 
    m.timelineBar.position = position
  end if
end sub

' Reinicia el timer de informacion en pantalla cuando el usuario busca manualmente
sub __restartShowInfoTimer()
  if m.showInfoTimer <> invalid then
    m.showInfoTimer.control = "stop"
    m.showInfoTimer.control = "start"
  end if
end sub

' Determina si la tecla presionada debe buscar en la linea de tiempo
function __isSeekKey(key as String) as Boolean
  if key = invalid then return false

  return key = KeyButtons().LEFT or key = KeyButtons().RIGHT or key = KeyButtons().FAST_FORWARD or key = KeyButtons().REWIND
end function

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

  if key = KeyButtons().RIGHT or key = KeyButtons().FAST_FORWARD then
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
  if m.controlsRow = invalid then return invalid

  count = m.controlsRow.getChildCount()
  for i = 0 to count - 1
    btn = m.controlsRow.getChild(i)
    if btn <> invalid and btn.visible and btn.focusable then return btn
  end for

  return invalid
end function

' Limpia las varables y detiene los timers disparados para cerrar la pantalla del player 
sub __closePlayer(onBack = false, logout = false)
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  m.apiBeaconRequestManager = clearApiRequest(m.apiBeaconRequestManager)
  m.apiLastWatchedRequestManager = clearApiRequest(m.apiLastWatchedRequestManager)
  
  m.focusplayerByload = false
  m.sendLastChannelWatched = false
  m.playerControllers.visible = false
  m.blockTuShowControls = true
  m.saveOpenPlayer = true
  if m.showChannelListAfterUpdate then m.showChannelListAfterUpdate = false 

  m.programSummaryPlayer.program = invalid
  
  clearTimer(m.showInfoTimer)
  clearTimer(m.saveLastWatched)
  clearTimer(m.retryReconnection)
  clearTimer(m.newProgramTimer)
  clearTimer(m.beaconTimer)
  clearTimer(m.channelListTimer)
  clearTimer(m.inactivityTimer)
  clearTimer(m.inactivityAutoCloseTimer)
  clearTimer(m.showTimeTimer)
  
  m.top.data = ""
  m.beaconType = ""
  if not logout then m.top.loading.visible = true
  m.lastErrorTime = invalid
  m.lastKey = invalid
  m.itemSelected = invalid
  m.repositionChannnelList = false
  m.lastButtonSelect = invalid
  m.lastId = 0
  m.isLiveRewind = false
  m.streamStartSeconds = invalid
  m.liveRewindDuration = invalid
  m.initStreeamingType = invalid
  
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

    if not logout then 
      body = {
        watchSessionId: getWatchSessionId()
        watchToken: getWatchToken()
        allId: m.program.allId
        secondsElapsed: Int(position)
      }
    
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlWatchEnd(m.apiUrl), "POST", "onEndWatchResponse", invalid, FormatJson(body), invalid, true)
    end if
  end if 
  
  m.program = invalid
  m.channelSelected = invalid
  
  if  m.channelList <> invalid then
    __cancelChannelPosition(logout)
    m.guide.channelId = 0
    m.guide.items = invalid
    
    m.channelList.channelId = 0
    m.channelList.items = invalid
    m.channelList.unobserveField("selected")
    m.guide.unobserveField("selected")
    m.guide.unobserveField("logout")
  end if

  m.allowChannelList = false
  m.isLiveContent = false
  m.videoPlayer.visible = false

  if m.timelineBar <> invalid then
    m.timelineBar.visible = false
    m.timelineBar.position = -1
    m.timelineBar.duration = -1
    m.timelineBar.baseEpochSeconds = invalid
  end if

  __hideInactivityPrompt(logout)

  m.errorChannelTitle.text = ""
  m.errorChannelImage.uri = ""
  if not logout then m.top.onBack = onBack

  m.pendingSeekActive = false
  m.pendingSeekPosition = invalid
  if m.seekCommitTimer <> invalid then m.seekCommitTimer.control = "stop"

  if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"
  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0

  if m.timelineBar <> invalid then m.timelineBar.seeking = false
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

' Cancela la posicion del canal elejido tanto en la lista de canales como en la guia porque 
' ha ocurrido algun error al cargar el canal o se quiso cerrar la lista de canales sin elejir 
' ningun canal nuevo
sub __cancelChannelPosition(logout = false)
  m.channelList.refreshProgressBars = false
  m.showChannelListAfterUpdate = false
  m.channelListContainer.visible = false

  if not logout then m.videoPlayer.setFocus(true)

  if not logout and m.repositionChannnelList then
    __repositionChannelList()
  end if 
end sub

' Muestra la informacion del programa actual sobre el player y dispara un timer para escodnerla 
' automaticamente si no hay ninguna interaccion. 
sub __showProgramInfo()
  m.playerControllers.visible = true
  if m.timelineBar <> invalid and not m.isLiveContent then m.timelineBar.visible = true
  btn = __getFirstVisibleControllerButton()
  if btn <> invalid then btn.setFocus(true)
  m.videoPlayer.setFocus(false)

  m.showInfoTimer.control = "start"
  m.showInfoTimer.ObserveField("fire","onHidenProgramInfo")

  ' respeta el estado seeking
  onTimelineSeekingChanged()
end sub

'Metodo que dispara la carga de un nuevo streaming en el player
sub __loadStreamingURL(key, id, streamingAction, streamingType = getStreamingType().DEFAULT, startpid = 0)
  m.itemSelected = invalid
  m.repositionChannnelList = false
  m.lastButtonSelect = invalid
  m.lastKey = key
  m.lastId = id
  m.newStreamingType = streamingType
  
  ' Falta agregar el update Session
  requestId = createRequestId()
  m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.lastKey, m.lastId, streamingAction, streamingType, startpid), "GET", "onStreamingsResponse") 
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
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogsToken(m.apiUrl), "GET", "onActionLogTokenResponse", invalid, invalid, invalid, false, FormatJson(actionLog))
  else
    __sendActionLog(actionLog)
  end if
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogs(m.beaconUrl), "POST", "onActionLogResponse", invalid, FormatJson(actionLog), beaconToken, false)
  end if
end sub

' Renueva el timer de que el usuario continua viendo. O se cargo una nueva url.
sub __extendTimeWatching()
  if m.streaming <> invalid and m.streaming.type <> invalid
    if LCase(m.streaming.type) = getVideoType().LIVE or LCase(m.streaming.type) = getVideoType().LIVE_REWIND

      if m.inactivityPromptTimeInSeconds <> -1
        __resetInactivityTimer()
      else 
        clearTimer(m.inactivityTimer)
      end if
    else
      clearTimer(m.inactivityTimer)
    end if
  end if
end sub

' Reconectar el stream automáticamente
sub __reconnectStream(saveTime = true)
  if not m.isReloadStreaming then
    m.isReloadStreaming = true
    m.reloadInputBlockUntilMs = __getNowMilliseconds() + 1200
    m.disableLayoutChannelConnection = true
    if (saveTime and m.streaming <> invalid and m.streaming.liveRewindDuration)
      m.lastPosition = m.streaming.liveRewindDuration - (m.videoPlayer.duration - m.videoPlayer.position) - 30
    end if

    m.currentStreamType = m.streaming.streamingType

    __loadStreamingURL(m.lastKey, m.lastId, getStreamingAction().PLAY, m.currentStreamType, m.program.id)
  end if
end sub


sub __togglePlayPause()
  if m.videoPlayer = invalid then return

  state = m.videoPlayer.state

  ' Pausar
  if state = "playing" or state = "buffering" then
    if m.videoPlayer.position <> invalid and m.videoPlayer.position > 0 then m.pausePosition = m.videoPlayer.position

    m.userPaused = true
    m.videoPlayer.control = "pause"

    if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/play.png"


    streamType = invalid
    if m.streaming <> invalid and m.streaming.type <> invalid then streamType = LCase(m.streaming.type)

    if (streamType = getVideoType().LIVE_REWIND) then
      m.endPlayerFrozen = getMomentNow()
      m.startPlayerFrozen = dtCloneAddSeconds(m.endPlayerFrozen, -Int(m.liveRewindDuration))
    else if (streamType = getVideoType().VOD or streamType = getVideoType().DVR)
      m.startPlayerFrozen = getMomentNow()
      m.endPlayerFrozen = dtCloneAddSeconds(m.endPlayerFrozen, -m.videoPlayer.duration)
    end if
    return
  end if

  ' Reanudar (desde paused)
  if state = "paused" then
    m.userPaused = false
    m.videoPlayer.control = "resume" ' <- clave
    if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/pause.png"
    return
  end if

  ' Si por alguna razón quedó "stopped", reanudar manualmente desde la última posición
  if state = "stopped" then
    m.userPaused = false
    if m.pausePosition <> invalid and m.pausePosition > 0 then
      m.videoPlayer.seek = m.pausePosition
    end if
    m.videoPlayer.control = "play"
    if m.playPauseImageButton <> invalid then m.playPauseImageButton.uri = "pkg:/images/shared/pause.png"
    return
  end if
end sub

sub __applyControlsVisibility()
  ' El botón guía siempre visible (si querés)
  if m.guideImageButton <> invalid then m.guideImageButton.visible = true

  ' Si el foco quedó en un botón oculto, lo movemos al primero visible
  idx = __getFocusedControllerButtonIndex()
  if idx <> -1 then
    btn = m.controllerButtons[idx]
    if btn <> invalid and btn.visible = false then
      firstBtn = __getFirstVisibleControllerButton()
      if firstBtn <> invalid then firstBtn.setFocus(true)
    end if
  end if
end sub

' Obtiene en foco botón del controlador index.
function __getFocusedControllerButtonIndex() as Integer
  if m.controllerButtons = invalid then return -1

  for i = 0 to m.controllerButtons.count() - 1
    btn = m.controllerButtons[i]
    if btn <> invalid and btn.isInFocusChain() then return i
  end for

  return -1
end function

function __focusControllerButtonAt(index as Integer) as Boolean
  if m.controllerButtons = invalid then return false
  if index < 0 or index >= m.controllerButtons.count() then return false

  btn = m.controllerButtons[index]
  if btn = invalid then return false
  if btn.visible = false then return false

  btn.setFocus(true)
  return true
end function

function __moveControllerFocus(direction as Integer) as Boolean
  ' direction: -1 = left, +1 = right
  if m.controllerButtons = invalid then return false

  idx = __getFocusedControllerButtonIndex()
  if idx = -1 then
    ' si ninguno está enfocado, mandamos al primero visible
    btn = __getFirstVisibleControllerButton()
    if btn <> invalid then btn.setFocus(true)
    return true
  end if

  i = idx + direction
  while i >= 0 and i < m.controllerButtons.count()
    btn = m.controllerButtons[i]
    if btn <> invalid and btn.visible then
      btn.setFocus(true)
      return true
    end if
    i = i + direction
  end while

  ' opcional: wrap (volver al otro extremo)
  ' si no querés wrap, devolvé false acá
  if direction > 0 then
    i = 0
    while i < m.controllerButtons.count()
      btn = m.controllerButtons[i]
      if btn <> invalid and btn.visible then
        btn.setFocus(true)
        return true
      end if
      i++
    end while
  else
    i = m.controllerButtons.count() - 1
    while i >= 0
      btn = m.controllerButtons[i]
      if btn <> invalid and btn.visible then
        btn.setFocus(true)
        return true
      end if
      i--
    end while
  end if

  return true
end function

sub __rebuildControllerButtons()
  lastFocus = invalid
  if m.playerControllers <> invalid and m.playerControllers.visible then 
    if m.playPauseImageButton <> invalid  and m.playPauseImageButton.isInFocusChain() then lastFocus = "playPauseImageButton"
    if m.toLiveImageButton <> invalid  and m.toLiveImageButton.isInFocusChain() then lastFocus = "toLiveImageButton"
    if m.restartImageButton <> invalid  and m.restartImageButton.isInFocusChain() then lastFocus = "restartImageButton"
  end if 

  if m.controlsRow = invalid then return
  ' Vaciar el layout
  while m.controlsRow.getChildCount() > 0
    m.controlsRow.removeChildIndex(0)
  end while

  ' Armar botones segun el tipo de streaming
  m.controllerButtons = []
  __resetControllerButtonFocus()

  streamType = invalid
  if m.streaming <> invalid and m.streaming.type <> invalid then streamType = LCase(m.streaming.type)

  if m.playPauseImageButton <> invalid then
    m.playPauseImageButton.visible = false
    m.playPauseImageButton.focusable = false
  end if

  if m.restartImageButton <> invalid then
    m.restartImageButton.visible = false
    m.restartImageButton.focusable = false
  end if

  if m.toLiveImageButton <> invalid then
    m.toLiveImageButton.visible = false
    m.toLiveImageButton.focusable = false
  end if

  if m.guideImageButton <> invalid then
    m.guideImageButton.visible = false
    m.guideImageButton.focusable = false
  end if

  showPlayRestart = (streamType = getVideoType().LIVE_REWIND or streamType = getVideoType().VOD or streamType = getVideoType().DVR)
  showToLive = (streamType = getVideoType().LIVE_REWIND)
  showGuide = (m.initStreeamingType = getVideoType().LIVE or m.initStreeamingType = getVideoType().LIVE_REWIND)

  if showPlayRestart and m.playPauseImageButton <> invalid then
    m.playPauseImageButton.visible = true
    m.playPauseImageButton.focusable = true
    m.controlsRow.appendChild(m.playPauseImageButton)
    m.controllerButtons.push(m.playPauseImageButton)
  end if

  if showPlayRestart and m.restartImageButton <> invalid then
    m.restartImageButton.visible = true
    m.restartImageButton.focusable = true
    m.controlsRow.appendChild(m.restartImageButton)
    m.controllerButtons.push(m.restartImageButton)
  end if

  if showToLive and m.toLiveImageButton <> invalid then
    m.toLiveImageButton.visible = true
    m.toLiveImageButton.focusable = (m.streaming <> invalid and m.streaming.streamingType = getStreamingType().LIVE_REWIND)
    if m.toLiveImageButton.focusable then
      m.toLiveImageButton.opacity = 1.0
    else
      m.toLiveImageButton.opacity = 0.4
    end if
    m.controlsRow.appendChild(m.toLiveImageButton)
    if m.toLiveImageButton.focusable then m.controllerButtons.push(m.toLiveImageButton)
  end if

  if showGuide and m.guideImageButton <> invalid then
    m.guideImageButton.visible = true
    m.guideImageButton.focusable = true
    m.controlsRow.appendChild(m.guideImageButton)
    m.controllerButtons.push(m.guideImageButton)
  end if

  __setControllerButtonFocusNeighbors()
  if lastFocus <> invalid then
    if lastFocus = "playPauseImageButton" and m.playPauseImageButton.focusable then m.playPauseImageButton.setFocus(true)
    if lastFocus = "restartImageButton" and m.restartImageButton.focusable then m.restartImageButton.setFocus(true)
    if (lastFocus = "toLiveImageButton") then
      if m.toLiveImageButton.focusable then 
        m.toLiveImageButton.setFocus(true)
      else 
        if m.playPauseImageButton.focusable then m.playPauseImageButton.setFocus(true)
      end if 
    end if 
  end if
end sub

sub __resetControllerButtonFocus()
  if m.playPauseImageButton <> invalid then
    m.playPauseImageButton.focusRight = invalid
  end if

  if m.restartImageButton <> invalid then
    m.restartImageButton.focusLeft = invalid
    m.restartImageButton.focusRight = invalid
  end if

  if m.toLiveImageButton <> invalid then
    m.toLiveImageButton.focusLeft = invalid
    m.toLiveImageButton.focusRight = invalid
  end if

  if m.guideImageButton <> invalid then
    m.guideImageButton.focusLeft = invalid
  end if
end sub

sub __setControllerButtonFocusNeighbors()
  if m.controllerButtons = invalid then return

  count = m.controllerButtons.count()
  if count = 0 then return

  for i = 0 to count - 1
    btn = m.controllerButtons[i]
    if btn <> invalid then
      if i > 0 then
        btn.focusLeft = m.controllerButtons[i - 1]
      else
        btn.focusLeft = invalid
      end if
  
      if i < count - 1 then
        btn.focusRight = m.controllerButtons[i + 1]
      else
        btn.focusRight = invalid
      end if 
    end if
  end for
end sub

sub __queueSeek(key as String)
  if m.isLiveContent or m.videoPlayer = invalid then return

  ' duration
  duration = m.videoPlayer.duration
  if m.isLiveRewind and m.liveRewindDuration <> invalid then
    duration = m.liveRewindDuration
  else
    if duration = invalid or duration <= 0 then duration = m.timelineBar.duration
  end if
  if duration = invalid or duration <= 0 then return

  ' posición base: si ya veníamos acumulando, seguimos desde el pending
  if m.pendingSeekActive and m.pendingSeekPosition <> invalid then
    position = m.pendingSeekPosition
  else
    position = m.videoPlayer.position
    if position = invalid or position < 0 then position = 0
  end if

  jump = m.timelineSeekStep
  if jump = invalid or jump <= 0 then jump = 10

  if key = KeyButtons().RIGHT or key = KeyButtons().FAST_FORWARD then
    position = position + jump
  else
    position = position - jump
  end if

  if position < 0 then position = 0
  if position > duration then position = duration

  m.pendingSeekActive = true
  m.pendingSeekPosition = position

  ' Preview UI inmediato (sin aplicar seek al stream todavía)
  if m.timelineBar <> invalid then
    m.timelineBar.duration = duration
    m.timelineBar.position = position
  end if

  __restartShowInfoTimer()
  __restartSeekCommitTimer()

  if m.timelineBar <> invalid then m.timelineBar.seeking = true
end sub

sub __restartSeekCommitTimer()
  return
end sub

sub onSeekCommitTimerFired()
  return
end sub

sub __commitPendingSeek()
  if not m.pendingSeekActive then return
  if m.videoPlayer = invalid then return
  if m.pendingSeekPosition = invalid then return

  if m.streaming <> invalid and m.streaming.type <> invalid and LCase(m.streaming.type) = getVideoType().LIVE_REWIND then
    if m.streaming.streamingType = getStreamingType().LIVE_REWIND then
      duration = m.videoPlayer.duration
      if m.isLiveRewind and m.liveRewindDuration <> invalid then
        duration = m.liveRewindDuration
      else if duration = invalid or duration <= 0 then
        if m.timelineBar <> invalid then duration = m.timelineBar.duration
      end if

      if duration <> invalid and duration > 0 and m.pendingSeekPosition >= (duration - 1) then
        m.pendingSeekActive = false
        m.pendingSeekPosition = invalid
        if m.timelineBar <> invalid then m.timelineBar.seeking = false

        m.currentStreamType = getStreamingType().DEFAULT
        __reconnectStream(false)
        return
      end if
    end if
  end if

  m.videoPlayer.seek = m.pendingSeekPosition

  m.pendingSeekActive = false
  m.pendingSeekPosition = invalid

  if m.timelineBar <> invalid then m.timelineBar.seeking = false
end sub

sub __cancelPendingSeek()
  if not m.pendingSeekActive then return

  m.pendingSeekActive = false
  m.pendingSeekPosition = invalid

  if m.timelineBar <> invalid then
    m.timelineBar.seeking = false
    if m.videoPlayer <> invalid then 
      m.timelineBar.position = m.videoPlayer.position
    end if
  end if
end sub

sub __startSeekHold(key as String)
  if m.isLiveContent or m.videoPlayer = invalid then return

  if LCase(m.streaming.type) = getVideoType().LIVE_REWIND and m.streaming.streamingType = getStreamingType().DEFAULT then
    m.currentStreamType = getStreamingType().LIVE_REWIND
    __reconnectStream()
  end if

  ' mientras está apretado, NO queremos commit
  if m.seekCommitTimer <> invalid then m.seekCommitTimer.control = "stop"

  m.seekHoldActive = true
  m.seekHoldKey = key
  m.seekHoldTicks = 0

  base = m.timelineSeekStep
  if base = invalid or base <= 0 then base = 10

  mult = 1
  if key = KeyButtons().FAST_FORWARD or key = KeyButtons().REWIND then
    mult = __getTrickTapMultiplier(key)
  else
    ' si querés que LEFT/RIGHT no acumulen taps, queda 1
    mult = 1
  end if

  m.seekHoldBaseJump = base * mult

  ' 1 salto inmediato con tap-mult
  __queueSeekWithJump(key, m.seekHoldBaseJump)

  ' timer de hold (tu lógica actual)
  if m.seekHoldTimer <> invalid then
    m.seekHoldTimer.control = "stop"
    m.seekHoldTimer.duration = 0.2
    m.seekHoldTimer.repeat = true
    m.seekHoldTimer.control = "start"
  end if

  if m.timelineBar <> invalid then m.timelineBar.seeking = true
end sub

sub __stopSeekHold()
  if m.seekHoldTimer <> invalid then
    m.seekHoldTimer.control = "stop"
  end if

  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0

  ' ahora sí: 2 segundos desde que soltó
  __restartSeekCommitTimer()

  if m.timelineBar <> invalid then m.timelineBar.seeking = false
end sub

sub onSeekHoldTimerFired()
  if not m.seekHoldActive then return
  if m.seekHoldKey = invalid then return

  m.seekHoldTicks = m.seekHoldTicks + 1

  jump = __getHoldJumpSeconds(m.seekHoldTicks)
  __queueSeekWithJump(m.seekHoldKey, jump)
end sub

function __getHoldJumpSeconds(ticks as Integer) as Integer
  base = m.seekHoldBaseJump
  if base = invalid or base <= 0 then
    base = m.timelineSeekStep
    if base = invalid or base <= 0 then base = 10
  end if

  mult = 1
  if ticks >= 5  and ticks < 10 then mult = 2
  if ticks >= 10 and ticks < 20 then mult = 4
  if ticks >= 20 then mult = 8

  return base * mult
end function

sub __queueSeekWithJump(key as String, jumpOverride as Integer)
  if m.isLiveContent or m.videoPlayer = invalid then return

  ' duration
  duration = m.videoPlayer.duration
  if m.isLiveRewind and m.liveRewindDuration <> invalid then
    duration = m.liveRewindDuration
  else
    if duration = invalid or duration <= 0 then duration = m.timelineBar.duration
  end if
  if duration = invalid or duration <= 0 then return

  ' posición base
  if m.pendingSeekActive and m.pendingSeekPosition <> invalid then
    position = m.pendingSeekPosition
  else
    position = m.videoPlayer.position
    if position = invalid or position < 0 then position = 0
  end if

  jump = jumpOverride
  if jump = invalid or jump <= 0 then
    jump = m.timelineSeekStep
    if jump = invalid or jump <= 0 then jump = 10
  end if

  if key = KeyButtons().RIGHT or key = KeyButtons().FAST_FORWARD then
    position = position + jump
  else
    position = position - jump
  end if

  if position < 0 then position = 0
  if position > duration then position = duration

  m.pendingSeekActive = true
  m.pendingSeekPosition = position

  ' Preview UI
  if m.timelineBar <> invalid then
    m.timelineBar.duration = duration
    m.timelineBar.position = position
  end if

  __restartShowInfoTimer()
    ' solo reiniciar commit si NO está en hold
  if not m.seekHoldActive then __restartSeekCommitTimer()

  if m.timelineBar <> invalid then m.timelineBar.seeking = true
end sub

sub onTimelineSeekingChanged()
  if m.timelineBar = invalid then return

  isSeeking = (m.timelineBar.seeking = true)

  ' Ocultar “program info” mientras se muestra la miniatura
  if m.programSummaryPlayer <> invalid then
    m.programSummaryPlayer.visible = (not isSeeking)
  end if

  if isSeeking then
    shouldPause = false
    if m.streaming <> invalid and m.streaming.type <> invalid then
      stype = LCase(m.streaming.type)
      if stype = getVideoType().LIVE_REWIND then
        if m.streaming.streamingType = getStreamingType().LIVE_REWIND then shouldPause = true
      else if stype = getVideoType().VOD or stype = getVideoType().DVR then
        shouldPause = true
      end if
    end if

    if shouldPause and not m.pauseOnSeekActive then
      m.pauseOnSeekActive = true
      __pauseVideo()
    end if
  else
    m.pauseOnSeekActive = false
  end if
end sub

sub onTimelinePreviewChanged()
  if m.timelinePreviewOverlay = invalid or m.timelinePreviewPoster = invalid then return
  if m.timelineBar = invalid then return

' Si TimelineBar dice "no visible"...
  if m.timelineBar.previewVisible <> true then
    ' Si ya pinneamos la miniatura, NO ocultar ni traer el summary de vuelta
    if m.previewPinned then return

    ' Caso normal: no hay preview activo
    m.timelinePreviewOverlay.visible = false
    __setSeekUi(false)
    return
  end if

  piT = m.programInfo.translation
  if piT = invalid then piT = [0, 0]

  tb = m.timelineBar.boundingRect()

  bcX = 0 : bcY = 0

  if m.timelineBarBarContainer <> invalid then
    bc = m.timelineBarBarContainer.boundingRect()
    bcX = bc.x
    bcY = bc.y
  end if

  uri = m.timelineBar.previewUri
  if uri <> invalid and uri <> "" then 
    ' Logica cuando hay thumbnails
    m.timelinePreviewPoster.uri = uri

    x = piT[0] + tb.x + bcX + m.timelineBar.previewX
    y = piT[1] + tb.y + bcY + m.timelineBar.previewY + scaleValue(40, m.scaleInfo)

    m.timelinePreviewOverlay.translation = [x, y]
    m.timelinePreviewOverlay.visible = true

    ' PIN: queda visible aunque suelte las teclas
    m.previewPinned = true
    __setSeekUi(true)

    ' tamaños deseados (16:9)
    w = scaleValue(250, m.scaleInfo)
    h = Fix((w * 9) / 16) ' 180

    m.timelinePreviewBg.width  = w
    m.timelinePreviewBg.height = h

    m.timelinePreviewPoster.width  = w - scaleValue(4, m.scaleInfo)
    m.timelinePreviewPoster.height = h - scaleValue(4, m.scaleInfo)
    m.timelinePreviewPoster.loadWidth  = w
    m.timelinePreviewPoster.loadHeight = h
    m.timelinePreviewPoster.loadDisplayMode = "scaleToZoom"
    m.timelinePreviewPoster.visible = true

    ' IMPORTANTE: append después del poster para que quede “por encima” de la imagen
    m.timelinePreviewOverlay.appendChild(m.timelinePreviewTimeBg)
    m.timelinePreviewOverlay.appendChild(m.timelinePreviewTimeLabel)

    m.timelinePreviewTimeLabel.text = m.timelineBar.previewTimeText

    ' Si también lo querés 16:9:
    bgW = scaleValue(70, m.scaleInfo)
    bgH = scaleValue(20, m.scaleInfo)

    bgX = w - bgW
    bgY = h - bgH

    m.timelinePreviewTimeBg.width = bgW
    m.timelinePreviewTimeBg.height = bgH
    m.timelinePreviewTimeBg.translation = [bgX, bgY]
    m.timelinePreviewTimeBg.visible = true

    ' Label dentro del recuadro (con un mini padding interno)
    m.timelinePreviewTimeLabel.width = bgW - scaleValue(6, m.scaleInfo)
    m.timelinePreviewTimeLabel.height = bgH
    if m.timelinePreviewTimeLabel.horizAlign <> "right" then m.timelinePreviewTimeLabel.horizAlign = "right"
    m.timelinePreviewTimeLabel.translation = [bgX + scaleValue(3, m.scaleInfo), bgY]
    m.timelinePreviewTimeLabel.text = m.timelineBar.previewTimeText
  else
    ' Solo tiene que mostrar el tiempo
    x = piT[0] + tb.x + bcX + m.timelineBar.previewX
    y = piT[1] + tb.y + bcY

    m.timelinePreviewOverlay.translation = [x, y]
    m.timelinePreviewOverlay.visible = true

    ' PIN: queda visible aunque suelte las teclas
    m.previewPinned = true
    __setSeekUi(true)

    w = scaleValue(70, m.scaleInfo)
    h = scaleValue(20, m.scaleInfo)

    m.timelinePreviewBg.width  = w
    m.timelinePreviewBg.height = h
    m.timelinePreviewPoster.visible = false

    m.timelinePreviewOverlay.appendChild(m.timelinePreviewTimeLabel)

    m.timelinePreviewTimeLabel.text = m.timelineBar.previewTimeText
    m.timelinePreviewTimeBg.visible = false
    
    ' Label dentro del recuadro (con un mini padding interno)
    m.timelinePreviewTimeLabel.width = w
    m.timelinePreviewTimeLabel.height = h 
    if m.timelinePreviewTimeLabel.horizAlign <> "center" then m.timelinePreviewTimeLabel.horizAlign = "center"
    m.timelinePreviewTimeLabel.translation = [0, scaleValue(2, m.scaleInfo)]
    m.timelinePreviewTimeLabel.text = m.timelineBar.previewTimeText
  end if
end sub

sub __setSeekUi(isSeeking as Boolean)
  if m.programSummaryPlayer = invalid then return
  if isSeeking then
    m.programSummaryPlayer.opacity = 0
  else
    m.programSummaryPlayer.opacity = 1
  end if
end sub

sub __ensurePreviewTimeNodes()
  if m.timelinePreviewOverlay = invalid then return

  ' si ya existen, no duplicar
  if m.timelinePreviewTimeLabel <> invalid and m.timelinePreviewTimeBg <> invalid then return

  m.timelinePreviewTimeBg = CreateObject("roSGNode", "Rectangle")
  m.timelinePreviewTimeBg.color = "#000000"

  m.timelinePreviewTimeLabel = CreateObject("roSGNode", "Label")
  m.timelinePreviewTimeLabel.horizAlign = "right"
  m.timelinePreviewTimeLabel.vertAlign = "center"
  m.timelinePreviewTimeLabel.font = "font:TinySystemFont"
  m.timelinePreviewTimeLabel.color = "#FFFFFF"
  m.timelinePreviewTimeLabel.text = ""
end sub

' Devuelve true si el controlsRow contiene un hijo con ese id
function __controlsRowContainsButton(buttonId as String) as Boolean
  if m.controlsRow = invalid then return false
  if buttonId = invalid or buttonId = "" then return false

  count = m.controlsRow.getChildCount()
  for i = 0 to count - 1
    child = m.controlsRow.getChild(i)
    if child <> invalid then
      ' El id del nodo (definido en XML) se puede leer así
      if child.id = buttonId then return true
    end if
  end for

  return false
end function

sub __replayBack(seconds as Integer)
  if m.videoPlayer = invalid then return
  if seconds = invalid or seconds <= 0 then seconds = 20

  ' No aplica a LIVE puro (sin ventana de rewind)
  if m.isLiveContent then return

  ' cancelar timers/estado de seek pendiente para evitar doble ejecución
  if m.seekCommitTimer <> invalid then m.seekCommitTimer.control = "stop"
  if m.seekHoldTimer   <> invalid then m.seekHoldTimer.control = "stop"

  m.pendingSeekActive = false
  m.pendingSeekPosition = invalid
  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0

  if m.timelineBar <> invalid then m.timelineBar.seeking = false

  ' Posición actual
  posi = m.videoPlayer.position
  if posi = invalid or posi < 0 then
    if m.timelineBar <> invalid then
      posi = m.timelineBar.position
    else
      posi = 0
    end if
  end if

  newPos = posi - seconds
  if newPos < 0 then newPos = 0

  ' Duración (para clamp, sobre todo en live-rewind)
  dur = m.videoPlayer.duration
  if m.isLiveRewind and m.liveRewindDuration <> invalid then
    dur = m.liveRewindDuration
  else if dur = invalid or dur <= 0 then
    if m.timelineBar <> invalid then dur = m.timelineBar.duration
  end if
  if dur <> invalid and dur > 0 and newPos > dur then newPos = dur

  ' seek real
  m.videoPlayer.seek = newPos

  ' Mantener TimelineBar sincronizada
  if m.timelineBar <> invalid then
    if dur <> invalid and dur > 0 then m.timelineBar.duration = dur
    m.timelineBar.position = newPos
  end if

  ' si había miniatura/preview, la ocultamos y devolvemos summary
  m.previewPinned = false
  if m.timelinePreviewOverlay <> invalid then m.timelinePreviewOverlaytimelinePreviewOverlay = false
  __setSeekUi(false)
  if m.programSummaryPlayer <> invalid then
    m.programSummaryPlayer.visible = true
    m.programSummaryPlayer.opacity = 1
  end if
end sub

function __getTrickTapMultiplier(key as String) as Integer
  if m.trickClock = invalid then
    m.trickClock = CreateObject("roTimespan")
    m.trickClock.Mark()
  end if

  nowMs = m.trickClock.TotalMilliseconds()

  if m.lastTrickKey = key and (nowMs - m.lastTrickMs) <= m.trickTapWindowMs then
    m.trickTapCount = m.trickTapCount + 1
  else
    m.trickTapCount = 1
  end if

  ' clamp
  if m.trickTapCount > m.trickTapMaxMult then m.trickTapCount = m.trickTapMaxMult

  m.lastTrickKey = key
  m.lastTrickMs  = nowMs

  return m.trickTapCount  ' 1 => 1x, 2 => 2x, 3 => 3x...
end function

' Aplicar las traducciones en el componente
sub __applyTranslations()
  if m.global.i18n = invalid then return

  m.connectingSignal.text = i18n_t(m.global.i18n, "player.playerPage.connecting")
  m.playPauseImageButton.tooltip = i18n_t(m.global.i18n, "player.video.pause")
  m.restartImageButton.tooltip = i18n_t(m.global.i18n, "player.video.restart")
  m.toLiveImageButton.tooltip = i18n_t(m.global.i18n, "player.video.goLive")
  m.guideImageButton.tooltip = i18n_t(m.global.i18n, "player.video.guide")
  m.inactivityMessage.text = i18n_t(m.global.i18n, "player.playerPage.askHere")
  m.inactivityContinueButton.text = i18n_t(m.global.i18n, "button.continueSee")
  m.timelineBar.liveText = i18n_t(m.global.i18n, "time.live")
end sub

sub __restartVideo()
  m.videoPlayer.control = "pause"
  m.timelineBar.isLive = false

  if m.program <> invalid and m.program.startTime <> invalid then
    programStartDate = toDateTime(m.program.startTime)

    if programStartDate <> invalid and m.startPlayerFrozen <> invalid and programStartDate.AsSeconds() >= m.startPlayerFrozen.AsSeconds() then
      m.pauseMoment = CreateObject("roDateTime")
      m.pauseMoment.FromSeconds(programStartDate.AsSeconds())

      __selectTime()
      __playVideo()
    else
      __toStart()
    end if
  else
    __toStart()
  end if
end sub

sub __refreshWatchTokenData(key as string, id as integer)
  m.apiSessionRequestManager = sendApiRequest(m.apiSessionRequestManager, urlUpdateWatchSession(m.apiUrl, key,  id), "GET", "onUpdateWatchSessionResponse", invalid, getWatchToken())
end sub

function getMomentNow() as object
  nowUtc = CreateObject("roDateTime")
  nowUtc.Mark() ' ahora (UTC)

  adjustedSec = nowUtc.AsSeconds()

  cloned = CreateObject("roDateTime")
  cloned.FromSeconds(adjustedSec)
  return cloned
end function

' Selecciona la nueva posición a reproducir.
' @param playing: si luego de posicionarse debe dar play.
sub __selectTime(playing = invalid as dynamic)
  if playing = invalid then playing = true

  timeVod = -1

  streamingType = m.streaming.streamingType

  if streamingType = getStreamingType().LIVE_REWIND then
    realType = invalid
    if m.streaming <> invalid then realType = m.streaming.streamingType

    if realType = getStreamingType().DEFAULT then
      ' Si loadUrlRewind es síncrono:
      __reconnectStream()
      selectTimeRewind(playing, true)
    else
      selectTimeRewind(playing, false)
    end if

  else
    startLimit = dtCloneAddSeconds(m.startPlayerFrozen, -m.liveRewindDuration)

    if (not dtIsSame(m.pauseMoment, m.pauseMomentFrozen)) and dtIsBefore(startLimit, m.pauseMoment) then

      playInSeconds = 0

      if dtIsBefore(startLimit, m.pauseMoment) then
        m._isEnded = false

        if dtIsBefore(m.pauseMoment, m.endPlayerFrozen) then
          m.isLive = false
          playInSeconds = dtDiffSeconds(m.pauseMoment, m.streamStartDate)
        else
          ' quiere ir al final
          m.isLive = false
          playInSeconds = m.liveRewindDuration - m.playerSeekTime
        end if
      else
        m._isEnded = false
        m.isLive = false
        playInSeconds = dtDiffSeconds(startLimit, m.streamStartDate)
      end if

      timeVod = playInSeconds
    else if not dtIsBefore(startLimit, m.pauseMoment) then
      m._isEnded = false
      m.isLive = false
      timeVod = dtDiffSeconds(startLimit, m.streamStartDate)

      __setPlayerCurrentTime(timeVod)
    else if m._isEnded = true then
      return
    end if

    if playing then
      __playVideo()
      __setPlayerCurrentTime(timeVod)
    else
      __setPlayerCurrentTime(timeVod)
    end if
  end if
end sub

' Selecciona la nueva posicion a reproducir en una URL de rewind.
' @param playing: si luego de posicionarse debe dar play.
' @param isFirstLoad: si es primera carga (ignora caso pausa = pausaFrozen).
sub selectTimeRewind(playing as boolean, isFirstLoad as boolean)
  extraTime = 0           ' en segundos (puede ser negativo)
  playInSeconds = 0
  origin = getMomentNow() ' roDateTime (equivalente a momentNow)

  startLimit = dtCloneAddSeconds(origin, -Int(m.liveRewindDuration))

  if (not dtIsSame(m.pauseMoment, m.pauseMomentFrozen)) and dtIsBefore(startLimit, m.pauseMoment) then

    if dtIsBefore(startLimit, m.pauseMoment) then
      m._isEnded = false

      if dtIsBefore(m.pauseMoment, m.endPlayerFrozen) then
        m.isLive = false

        playInSeconds = dtDiffSeconds(m.pauseMoment, m.streamStartDate)

        pmPlus2 = dtCloneAddSeconds(m.pauseMoment, 2)
        if not dtIsBefore(pmPlus2, m.startPlayerFrozen) then
          extraTime = -2
        end if

      else
        ' quiere ir al vivo
        __goToLive()
        return
      end if

    else
      m._isEnded = false
      m.isLive = false

      playInSeconds = dtDiffSeconds(startLimit, m.streamStartDate)
    end if

    __setPlayerCurrentTime(playInSeconds + extraTime)

  else if not dtIsBefore(startLimit, m.pauseMoment) then
    m._isEnded = false
    m.isLive = false

    playInSeconds = dtDiffSeconds(startLimit, m.streamStartDate)
    __setPlayerCurrentTime(playInSeconds + extraTime)

  else if isFirstLoad and dtIsSame(m.pauseMoment, m.pauseMomentFrozen) then

    if not dtIsBefore(startLimit, m.pauseMoment) then
      m._isEnded = false
      m.isLive = false

      playInSeconds = dtDiffSeconds(startLimit, m.streamStartDate)
      __setPlayerCurrentTime(playInSeconds + extraTime)

    else
      ' cae dentro del intervalo permitido (primer carga)
      m.isLive = false

      playInSeconds = dtDiffSeconds(m.pauseMoment, m.streamStartDate)

      lowerLimit = dtCloneAddMs(m.pauseMoment, -Int(m.chunkSizeMs))

      if not dtIsBefore(lowerLimit, m.startPlayerFrozen) then
        extraTime = -(m.chunkSizeMs / 1000.0)
      end if

      __setPlayerCurrentTime(playInSeconds + extraTime)
    end if
  end if

  if playing then __playVideo(false)
end sub

' Metodo encargado de "dibujar" como si estuviera en vivo y solicitar que se cargue la nueva url
sub __goToLive()
  __pauseVideo()

  sType = LCase(m.streaming.type)

  if sType = getVideoType().LIVE_REWIND then
    m.isLive = true

    ' limpio variables para evitar conflictos
    m.showThumbnail = false
    m.lastSearchDate = invalid
    m.endPlayerFrozen = invalid
    m.startPlayerFrozen = invalid
    m.pauseMomentFrozen = invalid
    m.pauseMoment = invalid
    m.diffDuration = 0

    ' goToLiveEvent.emit()
    if m.top <> invalid then m.top.goToLiveRequested = true

  else if sType = getVideoType().DVR or sType = getVideoType().VOD then
    m.isLive = false

    ' limpio variables
    m.showThumbnail = false
    m.lastSearchDate = invalid
    m.pauseMomentFrozen = invalid
    m.pauseMoment = invalid
    m.diffDuration = 0

    __loadTimeToEnd()
  end if
end sub

' Detiene la reproduccion del video y cambia el icono.
sub __pauseVideo()
  if m.videoPlayer = invalid then return

  paused = __isPlayerPaused()

  if paused and (m._isEnded <> true) then return
  if paused and (m._isEnded = true) and (m.pauseMoment <> invalid) then return

  __playerPause()

  m.playPauseIcon = "play"

  if not (m.streaming <> invalid and m.streaming.type <> invalid) then return
  stype = LCase(m.streaming.type)

  if stype = getVideoType().LIVE_REWIND then
    m.isLive = false

    m.endPlayerFrozen = getMomentNow()
    m.startPlayerFrozen = dtCloneAddSeconds(m.endPlayerFrozen, -Int(m.liveRewindDuration))

    realType = invalid
    if m.streaming <> invalid then realType = m.streaming.streamingType

    if realType = getStreamingType().DEFAULT then
      m.countSecondsPaused = 0
      m.pauseMomentFrozen = __dtClone(m.endPlayerFrozen)
    else
      curr = __getPlayerCurrentTime()
      m.pauseMomentFrozen = dtCloneAddSeconds(m.streamStartDate, Int(curr))

      if dtIsAfter(m.pauseMomentFrozen, m.endPlayerFrozen) then
        m.pauseMomentFrozen = __dtClone(m.endPlayerFrozen)
      end if
    end if

    m.pauseMoment = __dtClone(m.pauseMomentFrozen)
    m.diffDuration = __getDiffStartPlay()

  else if stype = getVideoType().DVR or stype = getVideoType().VOD then
    m.isLive = false

    if m.startPlayerFrozen <> invalid and m.videoPlayer <> invalid then
      curr = __getPlayerCurrentTime()
      m.pauseMomentFrozen = dtCloneAddSeconds(m.startPlayerFrozen, Int(curr))
    end if

    if m.pauseMomentFrozen <> invalid then
      m.pauseMoment = __dtClone(m.pauseMomentFrozen)
    end if

    m.diffDuration = __getDiffStartPlay()
    __loadTimeToEnd()
  end if
end sub

' Devuelve la diferencia (en segundos) entre el inicio absoluto del player y
' el inicio relativo de la barra donde el usuario puede posicionarse.
function __getDiffStartPlay() as integer
  duration = 0

  if m.startPlayerFrozen <> invalid then
    duration = Abs(dtDiffSeconds(m.startPlayerFrozen, m.streamStartDate))
  else
    if m.streaming <> invalid and m.streaming.type <> invalid and LCase(m.streaming.type) = getVideoType().LIVE_REWIND then
      origin = getMomentNow()
      startLimit = dtCloneAddSeconds(origin, -Int(m.liveRewindDuration))
      duration = Abs(dtDiffSeconds(startLimit, m.streamStartDate))
    end if
  end if

  if duration >= 1 then
    return duration
  end if

  if m.streaming <> invalid and LCase(m.streaming.streamingType) = getStreamingType().LIVE_REWIND then
    return 1
  else
    return 0
  end if
end function

sub __setPlayerCurrentTime(sec as float)
  if sec < 0 then sec = 0
  if m.videoPlayer = invalid then return

  m.videoPlayer.seek = Int(sec)
end sub

' Pone a reproducir el video y cambia el icono.
' @param validateLimit: valida limites de tiempo
sub __playVideo(validateLimit = invalid as dynamic)
  if validateLimit = invalid then validateLimit = false

  if m.videoPlayer = invalid then return
  if not __isPlayerPaused() then return
  if not (m.streaming <> invalid and m.streaming.type <> invalid) then return 
  
  stype = LCase(m.streaming.type)

  if stype = getVideoType().LIVE_REWIND then

    realType = invalid
    if m.streaming <> invalid then realType = m.streaming.streamingType

    if realType = getStreamingType().DEFAULT then
      __reconnectStream()
      return
    else
      if validateLimit then
        startLimit = dtCloneAddSeconds(getMomentNow(), -Int(m.liveRewindDuration))

        if not dtIsBefore(startLimit, m.pauseMoment) then
          m.isLive = false
          __setPlayerCurrentTime(dtDiffSeconds(startLimit, m.streamStartDate))
        end if
      end if

      m.videoPlayer.control = "play"
      m.playPauseIcon = "pause"

      m.showThumbnail = false
      m.lastSearchDate = invalid
      m.endPlayerFrozen = invalid
      m.startPlayerFrozen = invalid
      m.pauseMomentFrozen = invalid
      m.pauseMoment = invalid
      m.diffDuration = invalid
    end if

  else if stype = getVideoType().DVR or stype = getVideoType().VOD then
    m.videoPlayer.control = "play"
    m.playPauseIcon = "pause"

    m.showThumbnail = false
    m.lastSearchDate = invalid
    m.pauseMomentFrozen = invalid
    m.pauseMoment = invalid
    m.diffDuration = invalid

    if m._isEnded = true then __loadTimeToEnd()
  else
    m.videoPlayer.control = "play"
    m.playPauseIcon = "pause"
  end if
end sub

sub __loadTimeToEnd()
  __showTimeToEnd()

  if m.showTimeTimer <> invalid then
    m.showTimeTimer.control = "stop"
    m.showTimeTimer.control = "start"
  end if
end sub

' Actualiza y muestra el tiempo que lo separa del vivo o del final de la barra
sub __showTimeToEnd()
  if m.streaming = invalid or m.streaming.type = invalid then return
  if LCase(m.streaming.type) = getVideoType().LIVE then return

  if m.videoPlayer = invalid then return

  curr = __getPlayerCurrentTime()
  if curr = invalid then return

  stype = LCase(m.streaming.type)

  if stype = getVideoType().LIVE_REWIND then
    if m._isLive = true then
      m.endTime = "00:00"
    else
      realType = invalid
      if m.streaming <> invalid then realType = m.streaming.streamingType

      if realType = getStreamingType().DEFAULT then
        if (m.countSecondsPaused = invalid) then m.countSecondsPaused = 0
        m.endTime = formatTime(-1 * m.countSecondsPaused)
        m.countSecondsPaused = m.countSecondsPaused + 1
      else
        nowDt = getMomentNow()
        baseDt = dtCloneAddSeconds(m.streamStartDate, Int(curr))
        timeInSeconds = dtDiffSeconds(nowDt, baseDt)

        m.endTime = formatTime(-1 * timeInSeconds)
      end if
    end if

  else if stype = getVideoType().VOD or stype = getVideoType().DVR then
    if not __isPlayerPaused() then
      dur = __getPlayerDuration()
      if dur <> invalid then
        timeInSeconds = Int(dur) - Int(curr)
        m.endTime = formatTime(timeInSeconds)
      end if
    end if
  end if
end sub

function __getPlayerCurrentTime() as dynamic
  if m.videoPlayer = invalid then return invalid
  return m.videoPlayer.position ' segundos
end function

function __getPlayerDuration() as dynamic
  if m.videoPlayer = invalid then return invalid
  return m.videoPlayer.duration ' segundos (si tu Video lo expone)
end function

function __isPlayerPaused() as boolean
  if m.videoPlayer = invalid then return true
  return (m.videoPlayer.state = "paused")
end function

sub onActiveApiUrlChanged()
  __syncApiUrlFromGlobal()
end sub

sub __syncApiUrlFromGlobal()
  if m.global.activeApiUrl <> invalid and m.global.activeApiUrl <> "" then
    m.apiUrl = m.global.activeApiUrl
  end if
end sub

sub __playerPause()
  if m.videoPlayer = invalid then return
  m.videoPlayer.control = "pause"
end sub

' Metodo encargado de ir al inicio del Streaming.
' @param playing: si luego de posicionarse debe dar play.
sub __toStart(playing = invalid as dynamic)
  if playing = invalid then playing = true

  m._isEnded = false
  m.isLive = false

  __pauseVideo() ' por defecto emite pausa según tu implementación

  ' aca es start
  __setPlayerCurrentTime(__getDiffStartPlay())

  if playing then __playVideo()
end sub

