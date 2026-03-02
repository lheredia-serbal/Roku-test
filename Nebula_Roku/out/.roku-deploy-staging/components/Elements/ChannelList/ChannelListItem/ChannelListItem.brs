' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect  = m.top.findNode("theRect")
    m.channelInfo = m.top.findNode("channelInfo")
    m.programInfo = m.top.findNode("programInfo")
    m.programTime = m.top.findNode("programTime")
    m.channelImage = m.top.findNode("channelImage")
    m.progressLeft = m.top.findNode("progressLeft")
    m.progressRight = m.top.findNode("progressRight")
    m.progressGroup = m.top.findNode("progressGroup")
    m.contentGroup = m.top.findNode("contentGroup")
    
    m.scaleInfo = m.global.scaleInfo

    m.paddingX = scaleValue(12, m.scaleInfo)
    m.paddingY = scaleValue(14, m.scaleInfo)
    m.paddingPorgressY = scaleValue(30, m.scaleInfo)
    m.totalProgress = scaleValue(280, m.scaleInfo) - (m.paddingX * 2)
    m.limitOpacity = 0.6
    __initColors()
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if m.top.itemContent.channelTitle <> invalid then 
        m.channelInfo.text = m.top.itemContent.channelTitle
        m.channelInfo.visible = true
    end if

    if m.top.itemContent.programTitle <> invalid then 
        m.programInfo.text = m.top.itemContent.programTitle
        m.programInfo.visible = true
    end if

    if m.top.itemContent.date <> invalid then 
        m.programTime.text = m.top.itemContent.date
        m.programTime.visible = true
    end if

    if m.top.itemContent.percentageElapsed <> invalid and m.top.itemContent.percentageElapsed > 0 then
        widthLeft = (m.top.itemContent.percentageElapsed * m.totalProgress) / 100
        m.progressLeft.width = widthLeft
        m.progressRight.width = (m.totalProgress - widthLeft) 
    else
        m.progressLeft.width = 0
        m.progressRight.width = m.totalProgress
    end if

    if m.top.itemContent.imageURL <> invalid then m.channelImage.uri = m.top.itemContent.imageURL
end sub

' Se dispara al dibujar en pantalla y define oppiedades del xml del componente
sub currRectChanged()
    m.theRect.width = m.top.currRect.width 'Ya fue cambiado en el componente padre
    m.theRect.height = m.top.currRect.height 'Ya fue cambiado en el componente padre

    m.channelInfo.width = scaleValue(190, m.scaleInfo)
    m.programInfo.width = scaleValue(190, m.scaleInfo)
    m.programTime.width = scaleValue(190, m.scaleInfo)

    m.channelImage.width = scaleValue(60, m.scaleInfo)
    m.channelImage.height = scaleValue(60, m.scaleInfo)

    m.contentGroup.translation = [m.paddingX, m.paddingY]
    m.progressGroup.translation = [0, m.top.currRect.height - m.paddingPorgressY]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.theRect <> invalid  and  m.top.itemContent <> invalid then
        if m.top.focusPercent >= m.limitOpacity then
            m.theRect.opacity = m.limitOpacity + (m.top.focusPercent - m.limitOpacity) * (1.0 - m.limitOpacity) / (1.0 - m.limitOpacity)
        else
            m.theRect.opacity = m.limitOpacity
        end if
    end if
end sub

' Define los colores iniciales del componente
sub __initColors()
    m.programInfo.color = m.global.colors.LIGHT_GRAY
    m.programTime.color = m.global.colors.LIVE_CONTENT
    m.progressLeft.color = m.global.colors.PROGRESS
    m.progressRight.color = m.global.colors.PROGRESS_BG
end sub
