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
  m.lastPreviewEpoch = invalid
  m.lastPreviewEpoch = invalid

  m.utcOffsetSec = __getDeviceUtcOffsetSeconds()

  m.previewPinned = false
  m.lastCommittedPosition = invalid
  m.lastCommittedDuration = invalid
  m.committedRemaining = invalid
  m.pauseStartEpochSeconds = invalid
  m.lastStreamType = invalid
  m.suspendUi = false
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
  __applyHeight(m.top.hasFocus = true)
  __updateProgress()
end sub

sub onWidthChanged()
  __applyWidth()
end sub

sub onDurationChanged()
  if m.top.duration <> invalid then 
    if (m.top.duration) = -1 then return
    m.currentDuration = m.top.duration
  end if
  __updateProgress()
end sub

sub onPositionChanged()
  if m.top.position <> invalid then 
    if (m.top.position) = -1 then return
    m.currentPosition = m.top.position
  end if 
  __updateProgress()
end sub

sub __applyWidth()
  if m.top.widthBar <> invalid and m.top.widthBar > 0 then
    m.totalWidth = m.top.widthBar
  else if m.totalWidth = 0
    m.totalWidth = scaleValue(800, m.scaleInfo)
  end if

  m.track.width = m.totalWidth

  if m.timeLabel <> invalid then m.timeLabel.width = m.totalWidth

  __updateProgress()
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

  __updateProgress()
end sub

sub __updateProgress()
  print "__updateProgress()"
  if (m.currentDuration = invalid or m.currentPosition = invalid) then return
  if m.currentDuration <= 0  and m.currentPosition <= 0 then return 
  if m.suspendUi = true and m.top <> invalid and m.top.isPaused <> true then
    __restoreCachedUi()
    return
  end if

  ' LIVE: no hay tiempo, mostrar "En vivo" (traducido) y no usar position/duration
  if m.top <> invalid and m.top.isLive = true then
    if m.progress <> invalid then
      print "1"
      print m.totalWidth
      m.progress.width = m.totalWidth
    end if
    if m.timeLabel <> invalid then
      txt = m.top.liveText
      if txt = invalid or txt = "" then txt = i18n_t(m.global.i18n, "time.live")
      m.timeLabel.text = txt
    end if
  else
    if m.thumb <> invalid then m.thumb.visible = true
  end if

  if m.track = invalid or m.progress = invalid or m.barContainer = invalid then return

  ' Medidas del thumb
  thumbHalf = 0.0
  thumbH = 0.0
  if m.thumb <> invalid then
    if m.thumb.width <> invalid then thumbHalf = m.thumb.width / 2.0
    if m.thumb.height <> invalid then thumbH = m.thumb.height
  end if
  m.thumbHalf = thumbHalf

  ' Centrado vertical del thumb
  trackY = 0.0
  if m.track <> invalid and m.track.translation <> invalid then
    trackY = m.track.translation[1]
  end if

  thumbY = trackY + (m.track.height / 2.0) - (thumbH / 2.0)

  ' Si no hay duración
  if m.currentDuration <= 0 and not m.top.isLive then
    print "2"
    print 0
    m.progress.width = 0
    if m.thumb <> invalid then m.thumb.translation = [-thumbHalf, thumbY]
    if m.timeLabel <> invalid then m.timeLabel.text = "00:00"
    return
  end if

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
  
  if progressWidth > 1 then
    print "3"
    print progressWidth
    m.progress.width = progressWidth
  end if

  ' Thumb X centrado en borde del progreso
  thumbX = progressWidth - thumbHalf
  if thumbX < -thumbHalf then thumbX = -thumbHalf
  if thumbX > (m.totalWidth - thumbHalf) then thumbX = (m.totalWidth - thumbHalf)

  if m.thumb <> invalid then
    
    if (m.top.isLive ) then
      m.thumb.translation = [m.totalWidth - 20, thumbY]
      print "4"
      print m.totalWidth
      m.progress.width =  m.totalWidth
      ' Setear el máximo rango en X que puede alcanzar la esfera de progreso
      m.maxWidth = m.totalWidth - 20
    else
      ' Validar que la esfera de progreso, no se salga fuera del rango máximo
      if m.maxWidth <> invalid and thumbX > m.maxWidth then thumbX = m.maxWidth
      if (thumbX <> invalid and thumbX > -1) then
        m.thumb.translation = [thumbX, thumbY]
      end if
    end if
  end if

  ' Texto: no actualizar durante seeking (evita saltos mientras el usuario se mueve)
  if m.timeLabel <> invalid and not m.top.isLive and m.top.seeking <> true then
    ' Tiempo restante = Total - Transcurrido
    if (m.top.streamType = getStreamingType().LIVE_REWIND) then
      if m.committedRemaining = invalid and not m.top.seeking then
        m.committedRemaining = m.currentDuration - m.currentPosition
      end if

      remaining = m.currentDuration - m.currentPosition
      'if m.committedRemaining <> invalid then remaining = m.committedRemaining

      if remaining < 0 then remaining = 0
      if (m.top.isPaused = true) then
        elapsedPaused = __getEpochSeconds() - m.pauseStartEpochSeconds
        if elapsedPaused > 0 then remaining = remaining + elapsedPaused
      end if
      m.timeLabel.text = "-" + __formatTime(remaining)
    else if not m.top.isLive then 
      if m.committedRemaining = invalid and not m.top.seeking and m.top.isPaused <> true then
        m.committedRemaining = m.currentDuration - m.currentPosition
      end if

      remaining = m.currentDuration - m.currentPosition
      if m.committedRemaining <> invalid and (m.top.seeking or m.top.isPaused = true) then
        remaining = m.committedRemaining
      end if
      if remaining < 0 then remaining = 0
      m.timeLabel.text = __formatTime(remaining)
    end if
  end if

  ' Preview: SOLO publica datos, NO dibuja nada
  shouldShow = (m.top.seeking = true) and (m.thumbnailsUrlTemplate <> invalid)
  if not shouldShow then
    m.top.previewVisible = false
    m.top.previewUri = ""
    m.top.previewTimeText = ""
    return
  else 
    if (m.top.streamType = getStreamingType().LIVE_REWIND) then 
      liveText = "-"
      remaining = m.currentDuration - m.currentPosition
      if remaining < 0 then remaining = 0
      m.top.previewTimeText = liveText + __formatTime(remaining) ' tiempo transcurrido
    else 
      m.top.previewTimeText = __formatTime(m.currentPosition) ' tiempo transcurrido
    end if
  end if

  epoch = 0
  if m.baseEpochSeconds <> invalid and m.baseEpochSeconds > 0 then
    ' Si baseEpochSeconds está corrido -3h, sumale el offset
    epoch = Int(m.baseEpochSeconds) + Int(m.utcOffsetSec) + Int(m.currentPosition)
  else
    epoch = Int(m.currentPosition)
  end if

  url = __buildThumbUrl(epoch)
  ' Posición relativa al TimelineBar (misma cuenta que ya hacías)
  previewX = (thumbX + thumbHalf) - (m.previewW / 2.0)
  previewX = __clamp(previewX, 0, m.totalWidth - m.previewW)

  previewY = thumbY - m.previewH - m.previewMargin
  
  m.top.previewX = previewX
  m.top.previewY = previewY
  m.top.previewUri = url
  m.top.previewVisible = true
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
  __updateProgress()
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

sub onSeekingChanged()
  if m.top <> invalid and m.top.seeking = true then
    if m.top.streamType <> getStreamingType().LIVE_REWIND then
      m.committedRemaining = m.currentDuration - m.currentPosition
      if m.committedRemaining < 0 then m.committedRemaining = 0
    else if m.committedRemaining = invalid
      m.committedRemaining = m.currentDuration - m.currentPosition
      if m.committedRemaining < 0 then m.committedRemaining = 0
    end if
  end if
  __updateProgress()
end sub

sub onSeekCommitTokenChanged()
  __commitSelection()
  __updateProgress()
end sub

sub onIsPausedChanged()
  if m.top <> invalid and m.top.isPaused = true then
    m.pauseStartEpochSeconds = __getEpochSeconds()
    if m.top.streamType <> getStreamingType().LIVE_REWIND then
      m.committedRemaining = m.currentDuration - m.currentPosition
      if m.committedRemaining < 0 then m.committedRemaining = 0
    end if
    if m.pauseTickTimer <> invalid then m.pauseTickTimer.control = "start"
    if m.suspendUi = true then m.suspendUi = false
  else
    m.pauseStartEpochSeconds = invalid
    if m.pauseTickTimer <> invalid then m.pauseTickTimer.control = "stop"
  end if
  __updateProgress()
end sub

sub onPauseTick()
  if m.top <> invalid and m.top.isPaused = true then
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

sub __cacheUi()
  if m.progress <> invalid then m.cachedProgressWidth = m.progress.width
  if m.thumb <> invalid then m.cachedThumbTranslation = m.thumb.translation
  if m.timeLabel <> invalid then 
    m.cachedTimeText = m.timeLabel.text
  end if
end sub

' Obtiene dispositivo UTC offset seconds.
sub __restoreCachedUi()
  if m.cachedProgressWidth <> invalid and m.progress <> invalid then 
    print "5"
    print m.cachedProgressWidth
    m.progress.width = m.cachedProgressWidth
  end if
  if m.cachedThumbTranslation <> invalid and m.thumb <> invalid then m.thumb.translation = m.cachedThumbTranslation
  if m.cachedTimeText <> invalid and m.timeLabel <> invalid then 
    m.timeLabel.text = m.cachedTimeText
  end if 
end sub

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

sub __commitSelection()
  if m.top = invalid then return
  if m.currentDuration <= 0 then return

  m.lastCommittedPosition = m.currentPosition
  m.lastCommittedDuration = m.currentDuration
  m.committedRemaining = m.lastCommittedDuration - m.lastCommittedPosition
  if m.committedRemaining < 0 then m.committedRemaining = 0

  if m.top.streamType = getStreamingType().LIVE_REWIND and m.top.isPaused = true then
    m.pauseStartEpochSeconds = __getEpochSeconds()
  end if
end sub

' Obtiene epoch seconds.
function __getEpochSeconds() as integer
  dt = CreateObject("roDateTime")
  dt.Mark()
  return dt.AsSeconds()
end function
