' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.borderSize = 3
    m.rectLeft   = m.top.FindNode("rectLeft")
    m.rectTop    = m.top.FindNode("rectTop")
    m.rectRight  = m.top.FindNode("rectRight")
    m.rectBottom = m.top.FindNode("rectBottom")

    setColor()
end sub

' Define y setea los colores iniciales del componente
sub setColor()
    ' Color por defecto si algo falta en el global
    newColor = &hFFFFFFFF  ' blanco, o el que uses como default

    ' Usar el global del proyecto SIN tocarlo
    if m.global <> invalid and m.global.doesexist("colors") then
        if m.global.colors <> invalid and m.global.colors.doesexist("PRIMARY") then
            newColor = m.global.colors.PRIMARY
        end if
    end if

    ' Si el componente recibió un color explícito, ese manda
    if m.top.color <> invalid and m.top.color <> "" then
        newColor = m.top.color
    end if

    m.rectLeft.color   = newColor
    m.rectTop.color    = newColor
    m.rectRight.color  = newColor
    m.rectBottom.color = newColor
end sub

' Actualiza el tamaño del indicador de seleccion del carousel
sub changeSize()
    size = [120, 120]
    if m.top.size <> invalid and m.top.size.count() = 2 then size = m.top.size

    'Izquierda
    m.rectLeft.width = m.borderSize
    m.rectLeft.height = size[1] + m.borderSize
    
    'Superior
    m.rectTop.width = size[0] + m.borderSize
    m.rectTop.height = m.borderSize
    
    'Derecha
    m.rectRight.width = m.borderSize
    m.rectRight.height = size[1] + m.borderSize
    m.rectRight.translation = [(size[0] + m.borderSize), 0]

    'Inferior
    m.rectBottom.width = size[0] + (m.borderSize * 2)
    m.rectBottom.height = m.borderSize
    m.rectBottom.translation = [0, (size[1] + m.borderSize)] 
end sub