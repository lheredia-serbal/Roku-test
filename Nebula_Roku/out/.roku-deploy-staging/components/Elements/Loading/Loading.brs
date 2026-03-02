' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.spinner = m.top.findNode("spinner")

    m.top.observeField("visible", "onVisibleChange")

    background = m.top.findNode("background")

    m.scaleInfo = m.global.scaleInfo

    background.width = m.scaleInfo.width
    background.height = m.scaleInfo.height
    
    m.spinner.translation = [((m.scaleInfo.width - 80) / 2), ( m.scaleInfo.height - 20) / 2]
end sub

 
' Se ejecuta cuando cambia la propiedad "visible" del componente
sub onVisibleChange()
    m.spinner.visible = m.top.visible
end sub