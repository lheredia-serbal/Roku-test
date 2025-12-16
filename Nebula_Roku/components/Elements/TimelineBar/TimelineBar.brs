' Inicializa el componente de linea de tiempo
sub init()
  m.track = m.top.findNode("track")
  m.progress = m.top.findNode("progress")
  m.thumb = m.top.findNode("thumb")
  m.timeLabel = m.top.findNode("timeLabel")
  m.barContainer = m.top.findNode("barContainer")

  m.baseHeight = 6
  m.focusExtraHeight = 20

  m.totalWidth = 0
  m.currentDuration = 0.0
  m.currentPosition = 0.0

  if m.thumb <> invalid and m.thumb.uri = "" then
    m.thumb.uri = "pkg:/images/shared/ball.png"
  end if

  m.top.observeField("focusedChild", "onFocusChanged")

  __initColors()
  __applyWidth()
  __applyHeight(false)
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
    m.totalWidth = 800
  end if

  m.barContainer.width = m.totalWidth
  m.track.width = m.totalWidth
  __updateProgress()
end sub

sub __applyHeight(hasFocus as boolean)
  height = m.baseHeight
  if hasFocus then height = m.baseHeight + m.focusExtraHeight

  m.track.height = height
  m.progress.height = height
  __updateProgress()
end sub

sub __updateProgress()
  if m.currentDuration <= 0 then
    m.progress.width = 0
    thumbHalf = 0
    if m.thumb <> invalid and m.thumb.width <> invalid then thumbHalf = m.thumb.width / 2
    m.thumb.translation = [-thumbHalf, -(m.track.height / 2)]
    m.timeLabel.text = "00:00 / 00:00"
    return
  end if

  if m.currentPosition < 0 then m.currentPosition = 0
  if m.currentPosition > m.currentDuration then m.currentPosition = m.currentDuration

  progressWidth = (m.currentPosition / m.currentDuration) * m.totalWidth
  m.progress.width = progressWidth

  thumbHalf = 0
  if m.thumb <> invalid and m.thumb.width <> invalid then thumbHalf = m.thumb.width / 2

  thumbX = progressWidth - thumbHalf
  if thumbX < -thumbHalf then thumbX = -thumbHalf
  if thumbX > m.totalWidth - thumbHalf then thumbX = m.totalWidth - thumbHalf
  m.thumb.translation = [thumbX, -(m.track.height / 2)]

  m.timeLabel.text = __formatTime(m.currentPosition) + " / " + __formatTime(m.currentDuration)
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

' Ajusta estilos al cambiar el foco del componente
sub onFocusChanged()
  hasFocus = false
  if m.top <> invalid and m.top.hasFocus <> invalid then hasFocus = m.top.hasFocus

  if m.top.isInFocusChain() then
    m.top.thumbUri = "pkg:/images/client/ball.png"
  else
    m.top.thumbUri = "pkg:/images/shared/ball.png"
  end if

  __applyHeight(hasFocus)

  if m.global <> invalid and m.global.colors <> invalid then
    if hasFocus then
      m.progress.color = m.global.colors.PLAYER_TIMEBAR_FOCUCED
      if m.thumb <> invalid then m.thumb.blendColor = m.thumbColorFocused
    else
      m.progress.color = m.global.colors.PLAYER_TIMEBAR_NOT_FOCUCED
      if m.thumb <> invalid then m.thumb.blendColor = m.thumbColorBlur
    end if
  end if
end sub
