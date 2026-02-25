' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.animation = m.top.findNode("loadingAnimation")
    ball1 = m.top.findNode("ball1")
    ball2 = m.top.findNode("ball2")
    ball3 = m.top.findNode("ball3")

     m.balls = [ball1, ball2, ball3]
    __applyColors()

    m.top.observeField("visible", "onVisibleChange")

    if m.global <> invalid and m.global.hasField("colors") then
        m.global.observeField("colors", "onGlobalColorsChanged")
    end if
end sub

sub __applyColors()
    primaryColor = "0xFFFFFFFF"
    if m.global <> invalid and m.global.colors <> invalid and m.global.colors.PRIMARY <> invalid then
        primaryColor = m.global.colors.PRIMARY
    end if

    for each ball in m.balls
        ball.blendColor = primaryColor
    end for
end sub

sub onGlobalColorsChanged()
    __applyColors()
end sub
 
' Se ejecuta cuando cambia la propiedad "visible" del componente
sub onVisibleChange()
    if m.animation = invalid then return

    if m.top.visible = true then
        ' Arranca la animación cuando el componente es visible
        if m.animation <> invalid then m.animation.control = "start"
    else
        ' Detiene la animación cuando se oculta
        if m.animation <> invalid then m.animation.control = "stop"
    end if
end sub