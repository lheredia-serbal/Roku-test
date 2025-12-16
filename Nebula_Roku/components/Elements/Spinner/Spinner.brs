' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.animation = m.top.findNode("loadingAnimation")
    ball1 = m.top.findNode("ball1")
    ball2 = m.top.findNode("ball2")
    ball3 = m.top.findNode("ball3")

    primaryColor = m.global.colors.PRIMARY

    ball1.blendColor = primaryColor
    ball2.blendColor = primaryColor
    ball3.blendColor = primaryColor

    m.top.observeField("visible", "onVisibleChange")
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