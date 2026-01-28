' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.buttonBg = m.top.FindNode("buttonBg")
  m.btnImage = m.top.FindNode("btnImage")
  m.btnTooltip = m.top.FindNode("btnTooltip")
  
  m.borderContainer = m.top.FindNode("borderContainer")
  m.rectLeft = m.top.FindNode("rectLeft")
  m.rectTop = m.top.FindNode("rectTop")
  m.rectRight = m.top.FindNode("rectRight")
  m.rectBottom = m.top.FindNode("rectBottom")
  
  m.top.observeField("focusedChild", "onFocusChange")
end sub

' Actualiza la URL de la imagen del boton
sub updateUri()
  m.btnImage.uri = m.top.uri
  __initColors()
end sub

' Detecta el estado Disable de lboton y muestra el estilo en consecuencia
sub onChangeDisable()
  if m.top.disable then
    m.top.opacity = 0.4
  else
    m.top.opacity = 1.0
  end if
end sub

' Actualiza el texto que se muestra como tooltip del boton
sub updateTooltip()
  size = 45
  m.btnTooltip.text = m.top.tooltip
  if (m.scaleInfo = invalid) then m.scaleInfo = m.global.scaleInfo

  ' Forzamos medida si fuera necesario (la Label suele usar width fija).
  ' Calculamos la X para centrar el label respecto del buttonBg
  m.buttonBg.width = scaleValue(size, m.scaleInfo)
  m.buttonBg.height = scaleValue(size, m.scaleInfo)

  ' translation es un array [x,y]
  tooltipWidth = scaleValue((size + 10), m.scaleInfo)
  if m.btnTooltip.text <> invalid and m.btnTooltip.text <> "" then
    textLen = Len(m.btnTooltip.text)
    textWidth = scaleValue(7 * textLen, m.scaleInfo)
    if textWidth > tooltipWidth then tooltipWidth = textWidth
  end if
  m.btnTooltip.width = tooltipWidth
  m.btnTooltip.translation = [-(tooltipWidth - m.buttonBg.width) / 2.0, scaleValue((size + 5), m.scaleInfo)]

  m.btnImage.width = scaleValue((size/2), m.scaleInfo)
  m.btnImage.height = scaleValue((size/2), m.scaleInfo)
  m.btnImage.translation = [scaleValue(10, m.scaleInfo), scaleValue(10, m.scaleInfo)] 

  m.rectLeft.width = scaleValue(1, m.scaleInfo)
  m.rectLeft.height = scaleValue((size + 1), m.scaleInfo)

  m.rectTop.width = scaleValue(size, m.scaleInfo)
  m.rectTop.height = scaleValue(1, m.scaleInfo)

  m.rectRight.width = scaleValue(1, m.scaleInfo)
  m.rectRight.height = scaleValue((size + 1), m.scaleInfo)
  m.rectRight.translation = [scaleValue(size, m.scaleInfo), scaleValue(0, m.scaleInfo)] 

  m.rectBottom.width = scaleValue(size, m.scaleInfo)
  m.rectBottom.height = scaleValue(1, m.scaleInfo)
  m.rectBottom.translation = [scaleValue(0, m.scaleInfo), scaleValue(size, m.scaleInfo)] 
end sub

' Dispara la validacion si el componente tiene o no el foco sobre él
sub onFocusChange()
  if m.top.focusedChild <> invalid and m.top.focusedChild.focusable then 
    ' Tiene foco 
    m.borderContainer.visible = true
    m.btnTooltip.visible = true
    m.buttonBg.color = m.bgColorSelected
  else 
    ' No tiene foco
    m.borderContainer.visible = false
    m.btnTooltip.visible = false
    m.buttonBg.color = m.bgColorTransparent
  end if
end sub

' Define los colores iniciales del componente
sub __initColors()
  m.bgColorSelected = m.global.colors.PRIMARY
  m.bgColorTransparent = m.global.colors.TRANSPARENT
  borderColor = m.global.colors.WHITE
  m.rectLeft.color = borderColor
  m.rectTop.color = borderColor
  m.rectRight.color = borderColor
  m.rectBottom.color = borderColor
  m.btnImage.blendColor = borderColor
end sub
