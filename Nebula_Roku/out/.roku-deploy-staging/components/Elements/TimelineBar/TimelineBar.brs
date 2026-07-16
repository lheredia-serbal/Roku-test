' Inicializa el componente de linea de tiempo
sub init()
  m.track = m.top.findNode("track")
  m.progress = m.top.findNode("progress")
  m.thumb = m.top.findNode("thumb")
  m.timeLabel = m.top.findNode("timeLabel")
  m.barContainer = m.top.findNode("barContainer")

  m.scaleInfo = m.global.scaleInfo
  
  m.trackHeightBlur  = scaleValue(5, m.scaleInfo)
  m.trackHeightFocus = scaleValue(9, m.scaleInfo)  ' <- más alta cuando tiene foco

  m.previewW = scaleValue(70, m.scaleInfo)
  m.previewH = scaleValue(20, m.scaleInfo)

  m.previewMargin = scaleValue(8, m.scaleInfo)
  m.thumbHalf = scaleValue(8.0, m.scaleInfo) ' se recalcula igual si cambia width

  m.thumbnailsUrlTemplate = ""
  m.baseEpochSeconds = 0
  m.totalWidth = 0
  m.currentDuration = 0.0
  m.currentPosition = 0.0
  m.currentPositionPx = 0.0
  m.lastPreviewEpoch = invalid
  m.lastPreviewEpoch = invalid

  m.playerSeekTime = 10
  m.playerIncreasedSeekTime = 30
  m.maxBar = 0
  m.relationMillSecPx = 0.0

  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0
  m.seekHoldBaseJump = 0
  m.pendingSeconds = 0
  m.pausedDate = 0

  m.seekHoldTimer = CreateObject("roSGNode", "Timer")
  m.seekHoldTimer.duration = 0.2
  m.seekHoldTimer.repeat = true
  m.seekHoldTimer.ObserveField("fire", "onSeekHoldTimerFired")
  m.top.appendChild(m.seekHoldTimer)
  
  m.pendingSecondTimer = CreateObject("roSGNode", "Timer")
  m.pendingSecondTimer.duration = 1
  m.pendingSecondTimer.repeat = true
  m.pendingSecondTimer.ObserveField("fire", "onPendingSecondTimerFired")
  m.top.appendChild(m.pendingSecondTimer)

  m.utcOffsetSec = __getDeviceUtcOffsetSeconds()

  m.committedRemaining = invalid
  m.pauseStartEpochSeconds = invalid
  m.lastStreamType = invalid
  m.cachedProgressWidth = invalid
  m.cachedThumbTranslation = invalid
  m.cachedTimeText = invalid
  m.pauseTickTimer = CreateObject("roSGNode", "Timer")
  m.pauseTickTimer.duration = 1
  m.pauseTickTimer.repeat = true
  m.pauseTickTimer.ObserveField("fire", "onPauseTick")
  m.top.appendChild(m.pauseTickTimer)

  if m.thumb <> invalid and m.thumb.uri = "" then m.thumb.uri = "pkg:/images/shared/ball.png"

  'Alto reservado (fijo) para que NO cambie el boundingRect
  thumbH = 0
  if m.thumb <> invalid and m.thumb.height <> invalid then thumbH = m.thumb.height
  
  m.trackHeightMax = m.trackHeightFocus
  
  if thumbH > m.trackHeightMax then m.trackHeightMax = thumbH

  m.top.observeField("focusedChild", "onHasFocusChanged")

  __initColors()
  __applyWidth()
  __getThumbPosition()
  __applyHeight(m.top.hasFocus = true)
end sub

' Maneja los eventos de teclado del TimelineBar.
function onKeyEvent(key as String, press as Boolean) as Boolean
  
  if (key = KeyButtons().LEFT or key = KeyButtons().RIGHT) and press then 

    if m.pendingSecondTimer <> invalid and __isLiveRewindStream() and m.pendingSeconds = 0 then
      m.pendingSecondTimer.control = "start"
      m.pendingSeconds = 0
      m.pausedDate = getNowAsSeconds()
    end if

    if press then
      __startSeekHold(key)
    else
      __stopSeekHold()
    end if

    '__updateProgress()

    return true
  end if

  if (key = KeyButtons().OK and press) then

    if m.pendingSecondTimer <> invalid and __isLiveRewindStream() then m.pendingSecondTimer.control = "stop"
    __getCurrentPosition()

    if __isLiveRewindStream() then
      m.top.seekPosition = __getPositionLiveRewind()
    else
      m.top.seekPosition = m.currentPosition
    end if
    
    return true
  end if

  return false
end function

sub __startSeekHold(key as String)
  if m.thumb = invalid then return

  if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"

  m.seekHoldActive = true
  m.seekHoldKey = key
  m.seekHoldTicks = 0

  base = m.playerSeekTime
  if base = invalid or base <= 0 then base = 10

  m.seekHoldBaseJump = base * 5

  ' 1 salto inmediato con el valor base, igual que __startSeekHold en PlayerScreen.
  __moveThumbWithJump(key, base)

  ' if __isLiveRewindStream() and m.seekHoldTimer <> invalid then
  '   m.seekHoldTimer.duration = 1
  '   m.seekHoldTimer.repeat = true
  '   m.seekHoldTimer.control = "start"
  ' end if
end sub

' Indica si el TimelineBar está asociado a un stream LiveRewind.
' Acepta tanto el tipo de video completo como el código interno de streaming LiveRewind.
function __isLiveRewindStream() as Boolean
  if m.top = invalid or m.top.streamType = invalid then return false

  streamType = LCase(m.top.streamType)
  liveRewindVideoType = LCase(getVideoType().LIVE_REWIND)
  liveRewindStreamingType = LCase(getStreamingType().LIVE_REWIND)

  return streamType = liveRewindVideoType or streamType = liveRewindStreamingType
end function

' Detiene el timer de navegación por seek y limpia el estado de la tecla retenida.

sub __stopSeekHold()
  if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"

  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0
end sub

sub onSeekHoldTimerFired()
  if not m.seekHoldActive then return
  if m.seekHoldKey = invalid then return

  m.seekHoldTicks = m.seekHoldTicks + 1

  jump = __getHoldJumpSeconds(m.seekHoldTicks)
  __moveThumbWithJump(m.seekHoldKey, jump)
end sub

function __getHoldJumpSeconds(ticks as Integer) as Integer
  base = m.seekHoldBaseJump
  if base = invalid or base <= 0 then
    base = m.playerSeekTime
    if base = invalid or base <= 0 then base = 10
    base = base * 5
  end if

  mult = 1
  if ticks >= 5 and ticks < 10 then mult = 2
  if ticks >= 10 and ticks < 20 then mult = 4
  if ticks >= 20 then mult = 8

  return base * mult
end function

sub __moveThumbWithJump(key as String, jump as Dynamic)
  if m.thumb = invalid then return

  __notifySeekKeyPressed()

  stepX = 0.0
  if m.relationMillSecPx <> invalid and jump <> invalid then
    stepX = m.relationMillSecPx * jump
  end if

  if stepX <= 0 then return

  if key = KeyButtons().LEFT then
    nextX = m.currentPositionPx - stepX
  else
    nextX = m.currentPositionPx + stepX
  end if

  minX = 0.0
  maxX = m.totalWidth
  if m.maxBar <> invalid and m.maxBar > 0 then maxX = m.maxBar
  if maxX = invalid or maxX < minX then maxX = minX

  if nextX < minX then nextX = minX
  if nextX > maxX then nextX = maxX

  if m.progress <> invalid then m.progress.width = nextX
  print "Thumb 1 " ; nextX - m.thumbHalf
  m.thumb.translation = [nextX - m.thumbHalf, m.thumbY]
  m.currentPositionPx = nextX

  __showThumbnails()
  __showLabelText()
end sub

' Ejecuta cada tick de pendingSecondTimer para continuar el seek LiveRewind cada 1 segundo.
sub onPendingSecondTimerFired()
  m.pendingSeconds = m.pendingSeconds + 1
end sub

sub __notifySeekKeyPressed()
  if m.top.seekKeyPress = invalid then m.top.seekKeyPress = 0
  m.top.seekKeyPress = m.top.seekKeyPress + 1
end sub

sub onWidthChanged()
  __applyWidth()
end sub

sub onDurationChanged()
  if m.top.duration <> invalid then 
    if (m.top.duration) = -1 then return
    m.currentDuration = m.top.duration
  end if

  m.maxBar = m.totalWidth
  m.relationMillSecPx = 0.0
  if m.maxBar <> invalid and m.maxBar > 0 and m.currentDuration <> invalid and m.currentDuration > 0 then
    m.relationMillSecPx = roundToOneDecimal(m.maxBar / m.currentDuration)
  end if

  __updateProgress()
end sub

sub onPositionChanged()
  if m.top.position <> invalid then
    if (m.top.position = -1 and m.top.duration = 0 ) then
      __resetProgressState(true)
      return
    end if
    m.currentPosition = m.top.position
    if (m.currentDuration <> invalid and m.currentDuration  <> 0 and m.totalWidth  <> invalid and m.totalWidth <> 0) then
      m.currentPositionPx = roundToOneDecimal((m.totalWidth * m.currentPosition) / m.currentDuration)
    end if
  end if
  __updateProgress()
end sub

sub onResetTokenChanged()
  __resetProgressState(false)
end sub

sub __resetProgressState(resetTimeBar)
  m.currentDuration = 0
  m.currentPosition = 0
  m.maxBar = 0
  m.relationMillSecPx = 0
  m.playerIncreasedSeekTime = 0
  if m.seekHoldTimer <> invalid then m.seekHoldTimer.control = "stop"
  m.seekHoldActive = false
  m.seekHoldKey = invalid
  m.seekHoldTicks = 0
  m.seekHoldBaseJump = 0
  m.pendingSeconds = 0
  m.pausedDate = 0
  m.lastPreviewEpoch = invalid
  m.committedRemaining = invalid
  m.pauseStartEpochSeconds = invalid
  m.cachedProgressWidth = invalid
  m.cachedThumbTranslation = invalid
  m.cachedTimeText = invalid

  if m.pauseTickTimer <> invalid then m.pauseTickTimer.control = "stop"
  if m.progress <> invalid then m.progress.width = 0

  if m.thumb <> invalid and resetTimeBar = true then 
    m.thumb.translation = [0, m.thumbY]
  end if
  if m.timeLabel <> invalid then m.timeLabel.text = "00:00"

  if m.top <> invalid then
    m.top.previewVisible = false
    m.top.previewUri = ""
    m.top.previewTimeText = ""
  end if
end sub

sub __applyWidth()
  if m.top.widthBar <> invalid and m.top.widthBar > 0 then
    m.totalWidth = m.top.widthBar
  else if m.totalWidth = 0
    m.totalWidth = scaleValue(800, m.scaleInfo)
  end if

  m.track.width = m.totalWidth
  m.bar = m.totalWidth

  if m.timeLabel <> invalid then m.timeLabel.width = m.totalWidth
end sub

sub __getThumbPosition()
  ' Medidas del thumb
  m.thumbH = 0.0
  if m.thumb <> invalid then
    if m.thumb.width <> invalid then m.thumbHalf = m.thumb.width / 2.0
    if m.thumb.height <> invalid then m.thumbH = m.thumb.height
  end if

  m.thumbY = 0
end sub

sub __applyHeight(hasFocus as boolean)
  h = m.trackHeightBlur
  if hasFocus then h = m.trackHeightFocus

  m.track.height = h
  m.progress.height = h

  ' centrar dentro del alto fijo del barContainer
  y = (m.trackHeightMax - h) / 2.0
  m.track.translation = [0, y]
  m.progress.translation = [0, y]
end sub

sub __updateProgress()
  if (m.currentDuration = invalid or m.currentPosition = invalid) then return
  if m.currentDuration <= 0 and m.currentPosition <= 0 then return

  ' LIVE: no hay tiempo, mostrar "En vivo" (traducido) y no usar position/duration
  if m.top <> invalid and m.top.isLive = true then
    if m.progress <> invalid then
      m.progress.width = m.totalWidth
    end if
  else
    if m.thumb <> invalid then m.thumb.visible = true
  end if

  if m.track = invalid or m.progress = invalid or m.barContainer = invalid then return

  ' Clamp position
  if m.currentPosition < 0 then m.currentPosition = 0
  if m.currentPosition > m.currentDuration then
    m.currentPosition = m.currentDuration
  end if

  ' Progreso 
  if (m.currentPosition > 0 and m.currentDuration > 0) then  
    progressWidth = (m.currentPosition / m.currentDuration) * m.totalWidth
  else
    progressWidth = 0
  end if
  
  if progressWidth < 0 then 
    progressWidth = 0
  end if

  m.progress.width = progressWidth

  ' Thumb X centrado en borde del progresoad
  thumbX = progressWidth - m.thumbHalf
  if thumbX < - m.thumbHalf then thumbX = - m.thumbHalf
  if thumbX > (m.totalWidth - m.thumbHalf) then thumbX = (m.totalWidth - m.thumbHalf)

  if m.thumb <> invalid then
    
    if (m.top.isLive ) then
      print "Thumb 4 " ; - m.totalWidth - m.thumbHalf
      m.thumb.translation = [m.totalWidth - m.thumbHalf, m.thumbY]
      m.progress.width =  m.totalWidth
      ' Setear el máximo rango en X que puede alcanzar la esfera de progreso
      m.maxWidth = m.totalWidth - m.thumbHalf
    else
      ' Validar que la esfera de progreso, no se salga fuera del rango máximo
      if m.maxWidth <> invalid and thumbX > m.maxWidth then thumbX = m.maxWidth
      if (thumbX <> invalid) then
        if thumbX < 0 then thumbX = 0

        print "Thumb 5 " ; - thumbX
        m.thumb.translation = [thumbX, m.thumbY]
      end if
    end if
  end if

  ' Preview: SOLO publica datos, NO dibuja nada
  shouldShow = (m.thumbnailsUrlTemplate <> invalid)
  if not shouldShow then
    m.top.previewVisible = false
    m.top.previewUri = ""
    m.top.previewTimeText = ""
    return
  else 
    if (m.top.streamType = getStreamingType().LIVE_REWIND) then 
      remaining = m.currentDuration - m.currentPosition
      if remaining < 0 then remaining = 0
      if (m.top.isPaused = true) then
        elapsedPaused = __getEpochSeconds() - m.pauseStartEpochSeconds
        if elapsedPaused > 0 then remaining = remaining + elapsedPaused
      end if
      m.top.previewTimeText = __formatTime(remaining) ' tiempo transcurrido
    else 
      m.top.previewTimeText = __formatTime(m.currentPosition) ' tiempo transcurrido
    end if
  end if

  __showThumbnails()
  __showLabelText()
end sub

sub __showThumbnails()

  ' Si no hay duración
  if m.currentDuration <= 0 and not m.top.isLive then
    m.progress.width = 0
    print "Thumb 3 " ; - m.thumbHalf
    if m.thumb <> invalid then m.thumb.translation = [- m.thumbHalf, m.thumbY]
    return
  end if
  
  epoch = 0
  __getCurrentPosition()
  if m.baseEpochSeconds <> invalid and m.baseEpochSeconds > 0 then
    ' IMPORTANTE!!!
    ' Se esta teniendo en cuenta el liveOffsetMs por ahora porque parece haber algun lado que la barra lo acumula y en los VOD esto no deberia ser asi
    liveOffsetMs = 0 
    if m.top.liveOffsetMs <> 0 then liveOffsetMs = int(m.top.liveOffsetMs / 1000)
    ' Si baseEpochSeconds está corrido -3h, sumale el offset
    epoch = Int(m.baseEpochSeconds) + Int(m.utcOffsetSec) + Int(m.currentPosition) - liveOffsetMs
  else
    epoch = Int(m.currentPosition)
  end if

  url = __buildThumbUrl(epoch)

  ' Posición relativa al TimelineBar (misma cuenta que ya hacías)
  previewX = m.currentPositionPx - (m.previewW / 2.0)
  previewX = __clamp(previewX, 0, m.totalWidth - m.previewW)

  previewY = m.thumbY - m.previewH - m.previewMargin

  m.top.previewX = previewX
  m.top.previewY = previewY
  m.top.previewUri = url
  m.top.previewVisible = true
end sub

sub __showLabelText()

  if m.timeLabel <> invalid then
    if m.top <> invalid and m.top.isLive = true then
      txt = m.top.liveText
      if txt = invalid or txt = "" then txt = i18n_t(m.global.i18n, "time.live")
      m.timeLabel.text = txt
      return
    end if

    ' Si no hay duración
    if m.currentDuration <= 0 and not m.top.isLive then
      if m.timeLabel <> invalid then m.timeLabel.text = "00:00"
      return
    end if

    ' Progreso 
    if (m.currentPosition > 0 and m.currentDuration > 0) then  
      progressWidth = (m.currentPosition / m.currentDuration) * m.totalWidth
    else
      progressWidth = 0
    end if
    
    if progressWidth < 0 then 
      progressWidth = 0
    end if

    ' Thumb X centrado en borde del progresoad
    thumbX = progressWidth - m.thumbHalf
    if thumbX < - m.thumbHalf then thumbX = - m.thumbHalf
    if thumbX > (m.totalWidth - m.thumbHalf) then thumbX = (m.totalWidth - m.thumbHalf)

    if (thumbX = m.totalWidth - m.thumbHalf and m.top.streamType = getStreamingType().LIVE_REWIND and m.top.liveText <> invalid) then
      m.timeLabel.text = m.top.liveText
    end if

    ' Texto: no actualizar durante 
    if not m.top.isLive then
      ' Tiempo restante = Total - Transcurrido
      if (m.top.streamType = getStreamingType().LIVE_REWIND) then
        if m.committedRemaining = invalid then
          m.committedRemaining = m.currentDuration - m.currentPosition
        end if

        remaining = m.currentDuration - m.currentPosition

        if remaining < 0 then remaining = 0
        if (m.top.isPaused = true) then
          elapsedPaused = __getEpochSeconds() - m.pauseStartEpochSeconds
          if elapsedPaused > 0 then remaining = remaining + elapsedPaused
        end if
        m.timeLabel.text = "-" + __formatTime(remaining)
      else if not m.top.isLive then 
        if m.committedRemaining = invalid and m.top.isPaused <> true then
          m.committedRemaining = m.currentDuration - m.currentPosition
        end if

        remaining = m.currentDuration - m.currentPosition
        if m.committedRemaining <> invalid then
          remaining = m.committedRemaining
        end if
        if remaining < 0 then remaining = 0
        
        m.timeLabel.text = __formatTime(remaining)
      end if
    end if
  end if
end sub

' Formatea tiempo.
function __formatTime(seconds as float) as string
  if seconds < 0 then seconds = 0

  total = Int(seconds)
  hours = Int(total / 3600)
  minutes = Int((total - (hours * 3600)) / 60)
  secs = total - (hours * 3600) - (minutes * 60)

  if hours > 0 then
    return hours.toStr() + ":" + __pad(minutes) + ":" + __pad(secs)
  else
    return __pad(minutes) + ":" + __pad(secs)
  end if
end function

' Rellena el valor solicitado.
function __pad(value as integer) as string
  if value < 10 then
    return "0" + value.toStr()
  else
    return value.toStr()
  end if
end function

sub __initColors()
  if m.global <> invalid and m.global.colors <> invalid then
    m.thumbColorFocused = m.global.colors.WHITE
    m.thumbColorBlur = m.global.colors.LIGHT_GRAY
    m.PlayerTimebarFocuced = m.global.colors.PLAYER_TIMEBAR_FOCUCED
    m.PlayerTimebarNotFocuced = m.global.colors.PLAYER_TIMEBAR_NOT_FOCUCED
    m.progress.color = m.PlayerTimebarNotFocuced
    m.track.color = m.global.colors.PLAYER_TIMEBAR_UNPLAYED
    m.timeLabel.color = m.global.colors.WHITE
    if m.thumb <> invalid then m.thumb.blendColor = m.thumbColorBlur
  end if
end sub

sub onThumbUriChanged()
  if m.thumb <> invalid then m.thumb.uri = m.top.thumbUri
end sub

sub onHasFocusChanged()
  hasFocus = m.top.isInFocusChain()
  __applyHeight(hasFocus)
  __updateProgress()

  if hasFocus then
    m.progress.color = m.PlayerTimebarFocuced
    m.thumb.blendColor = m.thumbColorFocused
  else 
    m.progress.color = m.PlayerTimebarNotFocuced
    m.thumb.blendColor = m.thumbColorBlur
  end if
end sub

sub onThumbnailsUrlChanged()
  if m.top.thumbnailsUrl <> invalid and m.top.thumbnailsUrl <> "" then 
    m.previewW = scaleValue(250, m.scaleInfo)
    m.previewH = Fix((m.previewW * 9) / 16) ' => 180
    m.thumbnailsUrlTemplate = m.top.thumbnailsUrl
  else 
    m.thumbnailsUrlTemplate = ""
    m.previewW = scaleValue(70, m.scaleInfo)
    m.previewH = scaleValue(20, m.scaleInfo)
  end if

  m.lastPreviewEpoch = invalid
end sub

sub onBaseEpochChanged()
  if m.top.baseEpochSeconds <> invalid and m.top.baseEpochSeconds > 0 then 
    m.baseEpochSeconds = m.top.baseEpochSeconds
    m.lastPreviewEpoch = invalid
    __updateProgress()
  else 
    if m.pauseTickTimer <> invalid then m.pauseTickTimer.control = "stop"
  end if 
end sub

sub onIsPausedChanged()
  if m.top <> invalid and m.top.isPaused = true then
    m.pauseStartEpochSeconds = __getEpochSeconds()
    if m.top.streamType <> getStreamingType().LIVE_REWIND then
      m.committedRemaining = m.currentDuration - m.currentPosition
      if m.committedRemaining < 0 then m.committedRemaining = 0
    end if
    if m.pauseTickTimer <> invalid then m.pauseTickTimer.control = "start"
  else
    m.pauseStartEpochSeconds = invalid
    if m.pauseTickTimer <> invalid then m.pauseTickTimer.control = "stop"
  end if
  __updateProgress()
end sub

sub onPauseTick()
  if m.top <> invalid and m.top.isPaused = true and m.top.streamType <> getStreamingType().LIVE_REWIND then
    __updateProgress()
  end if
end sub

' Limita el valor solicitado.
function __clamp(v as float, mn as float, mx as float) as float
  if v < mn then return mn
  if v > mx then return mx
  return v
end function

' Construye thumb URL.
function __buildThumbUrl(epochSeconds as integer) as string
  if m.thumbnailsUrlTemplate = invalid or m.thumbnailsUrlTemplate = "" then return ""
  return m.thumbnailsUrlTemplate.Replace("[DateInEpoch]", epochSeconds.toStr())
end function

sub onLiveTextChanged()
  __updateProgress()
end sub

function __getDeviceUtcOffsetSeconds() as integer
  ' Mismo instante, pero en UTC vs Local => diferencia = offset
  dtUtc = CreateObject("roDateTime")
  dtUtc.Mark()
  utcSecs = dtUtc.AsSeconds()

  dtLoc = CreateObject("roDateTime")
  dtLoc.Mark()
  dtLoc.ToLocalTime() ' ojo: es void, ajusta el objeto
  locSecs = dtLoc.AsSeconds()

  ' Para Argentina (UTC-3) normalmente devuelve +10800
  return utcSecs - locSecs
end function

' Obtiene epoch seconds.
function __getEpochSeconds() as integer
  dt = CreateObject("roDateTime")
  dt.Mark()
  return dt.AsSeconds()
end function

' Obtener la posición seleccionada por el usuario y posicionar el player
sub __getCurrentPosition()
  if (m.currentPositionPx <> invalid and m.currentPositionPx <> 0 and m.maxBar <> invalid and m.maxBar <> 0 and m.currentDuration <> invalid and m.currentDuration <> 0) then
    m.currentPosition = (m.currentDuration * m.currentPositionPx) / m.maxBar
  end if
end sub

' Obtener el tiempo en el cuando debe posicionarse cuando se cambia de live a liveRewind
function __getPositionLiveRewind() as integer
  ' Obtener el tiempo de la barra en segundos
  timeLineStartAsSeconds = m.pausedDate - m.currentDuration

  ' Obtener el tiempo del player desde que inicio hasta el inicio del timeline en segundos
  timeLinePreviewAsSeconds = timeLineStartAsSeconds - m.baseEpochSeconds

  return timeLinePreviewAsSeconds + m.currentPosition + m.pendingSeconds
end function