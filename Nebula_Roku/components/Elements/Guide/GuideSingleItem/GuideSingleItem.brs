' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect = m.top.findNode("theRect")
    m.imageItem = m.top.findNode("imageItem")
    m.programTitleByError = m.top.findNode("programTitleByError")
    m.programTitle = m.top.findNode("programTitle")
    m.programTime = m.top.findNode("programTime")
    
    m.padding = 14
    m.backgroundImage = invalid
    m.showBackgroundImage = false
    m.limitOpacity = 0.5
    __initConfig()
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if m.top.itemContent.title <> invalid and m.top.itemContent.title <> "" then 
        m.programTitle.text = m.top.itemContent.title

        if (m.top.itemContent.imageURL = invalid) or (m.top.itemContent.imageURL <> invalid and  m.top.itemContent.imageURL <> "" and m.imageItem.uri <> m.top.itemContent.imageURL) then 
            m.programTitleByError.visible = true
        end if
    end if

    if m.top.itemContent.programTime <> invalid and m.top.itemContent.programTime <> "" then
        m.programTime.text = m.top.itemContent.programTime
        m.programTime.color = m.whiteColor

        if (m.top.itemContent.isNow) then m.programTime.color = m.liveColor
    end if


    if m.top.itemContent.imageURL <> invalid and m.top.itemContent.imageURL <> "" then 
        m.imageItem.loadSync = false
        m.showBackgroundImage = false
        m.imageItem.uri = m.top.itemContent.imageURL
    else 
        m.imageItem.loadSync = false
        m.showBackgroundImage = true
        m.imageItem.uri = m.backgroundImage
    end if
end sub

' Se dispara al dibujar en pantalla y define oppiedades del xml del componente
sub currRectChanged()
    m.programTime.width = m.top.itemContent.size[0]
    m.programTime.height = 22

    m.imageItem.translation = [0, m.programTime.height]

    m.imageItem.width = m.top.itemContent.size[0]
    m.imageItem.loadWidth = m.top.itemContent.size[0]
    m.imageItem.height = m.top.itemContent.size[1] - m.programTime.height
    m.imageItem.loadHeight = m.top.itemContent.size[1] - m.programTime.height
    
    m.programTitleByError.translation = [(m.top.itemContent.size[0] / 2), ((m.top.itemContent.size[1] - m.programTime.height) / 2) + m.programTime.height]

    m.programTitle.width = (m.top.itemContent.size[0] - m.padding)
    m.programTitle.height = ((m.top.itemContent.size[1] - m.programTime.height) - m.padding) + m.programTime.height
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.theRect <> invalid then
        if m.top.focusPercent >= m.limitOpacity then
            m.theRect.opacity = m.limitOpacity + (m.top.focusPercent - m.limitOpacity) * (1.0 - m.limitOpacity) / (1.0 - m.limitOpacity)
        else
            m.theRect.opacity = m.limitOpacity
        end if
    end if
end sub

' Se dispara cuando ocurre un cambio de evento al cargar una imagen y define que hacer.
sub onStatusChange()
    if (m.imageItem.loadStatus = "ready") then 
        m.programTitleByError.visible = m.showBackgroundImage
    else 
        m.programTitleByError.visible = true
    end if 
end sub

' Carga la configuracion inicial del componente, escuchando los observable y obteniendo las 
' referencias de compenentes necesarios para su uso
sub __initConfig()
    m.imageItem.loadSync = true 
    m.backgroundImage = getImageError()
    m.imageItem.loadingBitmapUri = m.backgroundImage
    m.imageItem.failedBitmapUri = m.backgroundImage

    
    m.whiteColor = m.global.colors.WHITE
    m.liveColor = m.global.colors.LIVE_CONTENT

    m.imageItem.ObserveField("loadStatus", "onStatusChange")
end sub

