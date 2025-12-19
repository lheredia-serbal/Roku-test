' Inicializa el componente de linea de tiempo
sub init()
  m.scaleInfo = m.global.scaleInfo
  if m.scaleInfo = invalid then
    m.scaleInfo = getScaleInfo()
  end if

  m.componentHeightBlur  = scaleValue(12, m.scaleInfo)
  m.componentHeightFocus = scaleValue(12, m.scaleInfo)

  m.track = m.top.findNode("track")
  m.progress = m.top.findNode("progress")
  m.thumb = m.top.findNode("thumb")
  m.timeLabel = m.top.findNode("timeLabel")
  m.barContainer = m.top.findNode("barContainer")

  m.trackHeightBlur  = scaleValue(6, m.scaleInfo)
  m.trackHeightFocus = scaleValue(10, m.scaleInfo)  ' <- más alta cuando tiene foco

  m.previewW = scaleValue(250, m.scaleInfo)
  m.previewH = Fix((m.previewW * 9) / 16) ' => 180
  m.previewMargin = scaleValue(8, m.scaleInfo)

  m.thumbHalf = scaleValue(8.0, m.scaleInfo) ' se recalcula igual si cambia width

  m.thumbnailsUrlTemplate = ""
  m.baseEpochSeconds = 0
  m.lastPreviewEpoch = invalid

  m.baseHeight = scaleValue(6, m.scaleInfo)
  m.focusExtraHeight = scaleValue(20, m.scaleInfo)

  m.totalWidth = 0
  m.currentDuration = 0.0
  m.currentPosition = 0.0
  
  m.lastPreviewEpoch = invalid

  m.previewPinned = false

  if m.thumb <> invalid and m.thumb.uri = "" then
    m.thumb.uri = "pkg:/images/shared/ball.png"
  end if

  'Alto reservado (fijo) para que NO cambie el boundingRect
  thumbH = 0
  if m.thumb <> invalid and m.thumb.height <> invalid then thumbH = m.thumb.height
    m.trackHeightMax = m.trackHeightFocus
  if thumbH > m.trackHeightMax then m.trackHeightMax = thumbH

  if m.barContainer <> invalid then
    m.barContainer.height = m.trackHeightMax
  end if

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
  if m.top.duration <> invalid then m.currentDuration = m.top.duration
  __updateProgress()
end sub

sub onPositionChanged()
  if m.top.position <> invalid then m.currentPosition = m.top.position
  __updateProgress()
end sub

sub __applyWidth()
  if m.top.widthBar <> invalid and m.top.widthBar > 0 then
    m.totalWidth = m.top.widthBar
  else if m.totalWidth = 0
    m.totalWidth = scaleValue(800, m.scaleInfo)
  end if

  m.barContainer.width = m.totalWidth
  m.track.width = m.totalWidth

  if m.timeLabel <> invalid then m.timeLabel.width = m.totalWidth

  __updateProgress()
end sub

sub __applyHeight(hasFocus as boolean)
  h = m.trackHeightBlur
  if hasFocus then h = m.trackHeightFocus

  m.track.height = h
  m.progress.height = h

  ' ✅ centrar dentro del alto fijo del barContainer
  y = (m.trackHeightMax - h) / 2.0
  m.track.translation = [0, y]
  m.progress.translation = [0, y]

  __updateProgress()
end sub

sub __updateProgress()

  ' ✅ LIVE: no hay tiempo, mostrar "En vivo" (traducido) y no usar position/duration
  if m.top <> invalid and m.top.isLive = true then
    if m.progress <> invalid then m.progress.width = m.totalWidth
    if m.thumb <> invalid then m.thumb.visible = false
    if m.timeLabel <> invalid then
      txt = m.top.liveText
      if txt = invalid or txt = "" then txt = "En vivo"
      m.timeLabel.text = txt
    end if
    return
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
  if m.currentDuration <= 0 then
    m.progress.width = 0
    if m.thumb <> invalid then m.thumb.translation = [-thumbHalf, thumbY]
    if m.timeLabel <> invalid then m.timeLabel.text = "00:00 / 00:00"
    return
  end if

  ' Clamp position
  if m.currentPosition < 0 then m.currentPosition = 0
  if m.currentPosition > m.currentDuration then m.currentPosition = m.currentDuration

  ' Progreso
  progressWidth = (m.currentPosition / m.currentDuration) * m.totalWidth
  m.progress.width = progressWidth

  ' Thumb X centrado en borde del progreso
  thumbX = progressWidth - thumbHalf
  if thumbX < -thumbHalf then thumbX = -thumbHalf
  if thumbX > (m.totalWidth - thumbHalf) then thumbX = (m.totalWidth - thumbHalf)

  if m.thumb <> invalid then
    m.thumb.translation = [thumbX, thumbY]
  end if

  ' Texto
  if m.timeLabel <> invalid then
    ' Tiempo restante = Total - Transcurrido
    remaining = m.currentDuration - m.currentPosition
    if remaining < 0 then remaining = 0

    m.timeLabel.text = __formatTime(remaining)
  end if

  ' ✅ Preview: SOLO publica datos, NO dibuja nada
  shouldShow = (m.top.seeking = true) and (m.thumbnailsUrlTemplate <> invalid and m.thumbnailsUrlTemplate <> "")
  if not shouldShow then
    m.top.previewVisible = false
    m.top.previewUri = ""
    m.top.previewTimeText = ""
    return
  else 
    m.top.previewTimeText = __formatTime(m.currentPosition) ' tiempo transcurrido
  end if

  epoch = 0
  if m.baseEpochSeconds <> invalid and m.baseEpochSeconds > 0 then
    epoch = Fix(m.baseEpochSeconds + m.currentPosition)
  else
    epoch = Fix(m.currentPosition)
  end if

  url = __buildThumbUrl(epoch)
  if url = "" then
    m.top.previewVisible = false
    return
  end if

  ' Posición relativa al TimelineBar (misma cuenta que ya hacías)
  previewX = (thumbX + thumbHalf) - (m.previewW / 2.0)
  previewX = __clamp(previewX, 0, m.totalWidth - m.previewW)

  previewY = thumbY - m.previewH - m.previewMargin

  m.top.previewX = previewX
  m.top.previewY = previewY
  m.top.previewUri = url
  m.top.previewVisible = true
end sub

function __formatTime(seconds as float) as string
  if seconds < 0 then seconds = 0

  total = Fix(seconds)
  hours = Fix(total / 3600)
  minutes = Fix((total - (hours * 3600)) / 60)
  secs = total - (hours * 3600) - (minutes * 60)

  if hours > 0 then
    return hours.toStr() + ":" + __pad(minutes) + ":" + __pad(secs)
  else
    return __pad(minutes) + ":" + __pad(secs)
  end if
end function

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
    m.progress.color = m.global.colors.PLAYER_TIMEBAR_NOT_FOCUCED
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
    m.progress.color = m.global.colors.PLAYER_TIMEBAR_FOCUCED
  else 
    m.progress.color = m.global.colors.PLAYER_TIMEBAR_NOT_FOCUCED
  end if
end sub

sub onThumbnailsUrlChanged()
  if m.top.thumbnailsUrl <> invalid then m.thumbnailsUrlTemplate = m.top.thumbnailsUrl
  m.lastPreviewEpoch = invalid
  __updateProgress()
end sub

sub onBaseEpochChanged()
  if m.top.baseEpochSeconds <> invalid then m.baseEpochSeconds = m.top.baseEpochSeconds
  m.lastPreviewEpoch = invalid
  __updateProgress()
end sub

sub onSeekingChanged()
  __updateProgress()
end sub

function __clamp(v as float, mn as float, mx as float) as float
  if v < mn then return mn
  if v > mx then return mx
  return v
end function

function __buildThumbUrl(epochSeconds as integer) as string
  if m.thumbnailsUrlTemplate = invalid or m.thumbnailsUrlTemplate = "" then return ""
  return m.thumbnailsUrlTemplate.Replace("[DateInEpoch]", epochSeconds.toStr())
end function

sub onIsLiveChanged()
  __updateProgress()
end sub

sub onLiveTextChanged()
  __updateProgress()
end sub