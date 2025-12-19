' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.spinner = m.top.findNode("spinner")

    m.top.observeField("visible", "onVisibleChange")

    background = m.top.findNode("background")
 
    background.width = m.global.width
    background.height = m.global.height
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if
end sub

 
' Se ejecuta cuando cambia la propiedad "visible" del componente
sub onVisibleChange()
    m.spinner.visible = m.top.visible
end sub