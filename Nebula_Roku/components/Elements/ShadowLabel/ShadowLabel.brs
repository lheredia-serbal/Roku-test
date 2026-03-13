' ****** Funciones Públicas ******

sub init()
  m.shadowText = m.top.findNode("shadowText")
  m.mainText = m.top.findNode("mainText")

  m.top.observeField("width", "syncLayout")
  m.top.observeField("height", "syncLayout")

  syncStyle()
  syncText()
  syncLayout()
end sub

' Setear los textos
sub syncText()
  if m.shadowText = invalid or m.mainText = invalid then return
  m.shadowText.text = m.top.text
  m.mainText.text = m.top.text
  syncLayout()
end sub

' Setear los estilos
sub syncStyle()
  if m.shadowText = invalid or m.mainText = invalid then return

  m.mainText.font = m.top.font
  m.shadowText.font = m.top.font

  m.mainText.color = m.top.color
  m.shadowText.color = "0x000000FF"

  m.mainText.horizAlign = m.top.horizAlign
  m.shadowText.horizAlign = m.top.horizAlign

  m.mainText.vertAlign = m.top.vertAlign
  m.shadowText.vertAlign = m.top.vertAlign

  m.mainText.wrap = m.top.wrap
  m.shadowText.wrap = m.top.wrap

  maxLinesValue = __getWrapMaxLines()
  m.mainText.maxLines = maxLinesValue
  m.shadowText.maxLines = maxLinesValue
end sub

' Setear el alto, ancho y ubicación
sub syncLayout()
  if m.shadowText = invalid or m.mainText = invalid then return

  offsetX = 1
  offsetY = 1
  widthValue = 0
  heightValue = 0
  if m.top.width <> invalid and m.top.width > 0 then
    widthValue = m.top.width
  else
    widthValue = m.mainText.localBoundingRect().width + Abs(offsetX)
  end if

  if m.top.height <> invalid and m.top.height > 0 then
    heightValue = m.top.height
  else
    heightValue = m.mainText.localBoundingRect().height + Abs(offsetY)
  end if

  m.mainText.width = widthValue
  m.shadowText.width = widthValue
  m.mainText.height = heightValue
  m.shadowText.height = heightValue

  m.mainText.translation = [0, 0]
  m.shadowText.translation = [offsetX, offsetY]
end sub

' ****** Funciones Privadas ******

function __getWrapMaxLines() as integer
  if m.top.maxLines <> invalid and m.top.maxLines > 0 then
    return m.top.maxLines
  end if

  return 3
end function
