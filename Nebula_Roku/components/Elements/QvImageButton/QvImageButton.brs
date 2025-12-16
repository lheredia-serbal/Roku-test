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

' Actualiza el texto que se muestra como tooltip del boton
sub updateTooltip()
  m.btnTooltip.text = m.top.tooltip

  ' Forzamos medida si fuera necesario (la Label suele usar width fija).
  ' Calculamos la X para centrar el label respecto del buttonBg
  btnW = 0
  if m.buttonBg <> invalid and m.buttonBg.width <> invalid then
    btnW = m.buttonBg.width
  else
    btnW = 40 ' fallback
  end if
  lblW = m.btnTooltip.width
  ' Si label tiene width fijo, lblW es ese. Si quieres ajustar dinámicamente
  ' podrías cambiar label.width dependiendo del texto (pero aquí asumimos width fijo).
  x = (btnW - lblW) / 2
  ' translation es un array [x,y]
  m.btnTooltip.translation = [x, m.btnTooltip.translation[1]]
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
