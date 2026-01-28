' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
  m.borderSize = 1
  m.butonBg = m.top.FindNode("butonBg")
  m.layoutContainer = m.top.FindNode("layoutContainer")
  m.btnText = m.top.FindNode("btnText")
  m.rectLeft = m.top.FindNode("rectLeft")
  m.rectTop = m.top.FindNode("rectTop")
  m.rectRight = m.top.FindNode("rectRight")
  m.rectBottom = m.top.FindNode("rectBottom")
  
  m.scaleInfo = m.global.scaleInfo

  m.top.observeField("focusedChild", "onFocusChange")

  m.HeightToHide = 1
  m.defaultHeight = 0
end sub

' Actualiza el texto del boton
sub updateText()
  m.btnText.text = m.top.text
  __initColors()
  changeSize()
end sub

' Actualiza el color del texto del boton
sub updateTextColor()
  if m.top.textColor <> invalid and m.top.textColor <> "" then 
    m.btnText.color = m.top.textColor
  end if 
end sub

' Actualiza el color del borde del boton
sub updateBorderColor()
  if m.top.borderColor <> invalid and m.top.borderColor <> "" then 
    m.rectLeft.color = m.top.borderColor
    m.rectTop.color = m.top.borderColor
    m.rectRight.color = m.top.borderColor
    m.rectBottom.color = m.top.borderColor
  end if 
end sub

' Detecta el estado Disable de lboton y muestra el estilo en consecuencia
sub onChangeDisable()
  if m.top.disable then
    m.top.opacity = 0.4
  else
    m.top.opacity = 1.0
  end if
end sub

' Actualiza la fuente del boton.
sub updateFont()
  if  m.top.font <> invalid and m.top.font <> "" and m.top.font <> "font:SmallestSystemFont" then
    m.btnText.font = m.top.font
  end if
end sub

' Actualiza el tamaño del boton
sub changeSize()
  size = scaleSize([m.butonBg.width, m.butonBg.height], m.scaleInfo)
  
  if m.top.size <> invalid then 
    if m.top.size.count() = 1 then size = [m.top.size[0], m.butonBg.height]
    if m.top.size.count() = 2 then size = [m.top.size[0], m.top.size[1]]
    
    if size[0] = 0 then size[0] = m.butonBg.width
    if size[1] = 0 then size[1] = m.butonBg.height

    m.butonBg.width = size[0]
    m.butonBg.height = size[1]

    m.layoutContainer.translation = [size[0] / 2, size[1] / 2]
  end if 

  ' Si es uno significa que se desea esconder
  if size[0] <> 1 and size[1] <> 1 then 
    'Izquierda
    if not m.rectLeft.visible then m.rectLeft.visible = true
    m.rectLeft.width = m.borderSize
    m.rectLeft.height = size[1] + m.borderSize
    
    'Superior
    if not m.rectTop.visible then m.rectTop.visible = true
    m.rectTop.width = size[0] + m.borderSize
    m.rectTop.height = m.borderSize
    
    'Derecha
    if not m.rectRight.visible then m.rectRight.visible = true
    m.rectRight.width = m.borderSize
    m.rectRight.height = size[1] + m.borderSize
    m.rectRight.translation = [(size[0] + m.borderSize), 0]
    
    'Inferior
    if not m.rectBottom.visible then m.rectBottom.visible = true
    m.rectBottom.width = size[0] + (m.borderSize * 2)
    m.rectBottom.height = m.borderSize
    m.rectBottom.translation = [0, (size[1] + m.borderSize)]

    m.btnText.height = m.defaultHeight
    m.btnText.visible = true

  else if size[0] = 1 and size[1] = 1 then
    m.rectLeft.width = m.HeightToHide
    m.rectLeft.height = m.HeightToHide
    m.rectLeft.visible = false
    
    m.rectTop.width = m.HeightToHide
    m.rectTop.height = m.HeightToHide
    m.rectTop.visible = false
    
    m.rectRight.width = m.HeightToHide
    m.rectRight.height = m.HeightToHide
    m.rectRight.visible = false
    
    m.rectBottom.width = m.HeightToHide
    m.rectBottom.height = m.HeightToHide
    m.rectBottom.visible = false

    m.rectRight.translation = [0, 0]
    m.rectBottom.translation = [0, 0]
    m.btnText.height = m.HeightToHide
    m.btnText.visible = false
  end if 
end sub

' Dispara la validacion si el componente tiene o no el foco sobre él
sub onFocusChange()
  if m.top.focusedChild <> invalid and m.top.focusedChild.focusable then 
    ' Tiene foco 
    m.butonBg.color = m.bgColorSelected
  else 
    ' No tiene foco 
    m.butonBg.color = m.bgColorTransparent
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
  m.btnText.color = borderColor
end sub
