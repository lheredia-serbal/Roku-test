' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.spinner = m.top.findNode("spinner")

    m.top.observeField("visible", "onVisibleChange")

    background = m.top.findNode("background")
 
    background.width = m.global.width
    background.height = m.global.height
    m.spinner.translation = [((m.global.width - 80) / 2), (m.global.height - 20) / 2]
end sub

 
' Se ejecuta cuando cambia la propiedad "visible" del componente
sub onVisibleChange()
    m.spinner.visible = m.top.visible
end sub