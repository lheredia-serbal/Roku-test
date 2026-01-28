' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect  = m.top.findNode("theRect")
    m.contentGroup = m.top.findNode("contentGroup")
    m.progressGroup = m.top.findNode("progressGroup")
    m.title = m.top.findNode("title")
    m.category = m.top.findNode("category")
    m.dateTime = m.top.findNode("dateTime")
    m.imageItem = m.top.findNode("imageItem")
    m.progressLeft = m.top.findNode("progressLeft")
    m.progressRight = m.top.findNode("progressRight")
    m.opacityLayout = m.top.findNode("opacityLayout")
    
    m.scaleInfo = m.global.scaleInfo

    m.padding = scaleValue(12, m.scaleInfo)
    m.totalProgress = scaleValue(310, m.scaleInfo) - (m.padding * 2)
    m.backgroundImage = invalid 
    m.programContentType = false
    __initColors()
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if (m.top.itemContent.contentType = getCarouselContentType().PROGRAMS) then 
        m.totalProgress = scaleValue(300 - (m.padding * 2) - 70, m.scaleInfo)

        m.imageItem.loadSync = true 
        m.backgroundImage = getImageError()
        m.imageItem.loadingBitmapUri = m.backgroundImage
        m.imageItem.failedBitmapUri = m.backgroundImage
        m.programContentType = true
    end if

    if m.top.itemContent.title <> invalid then 
        m.title.text = m.top.itemContent.title
        m.title.visible = true
    end if

    if m.top.itemContent.category <> invalid then 
        m.category.text = m.top.itemContent.category
        m.category.visible = true
    end if

    if m.top.itemContent.date <> invalid then 
        m.dateTime.text = m.top.itemContent.date
        m.dateTime.visible = true
    end if

    if m.top.itemContent.percentageElapsed <> invalid and m.top.itemContent.percentageElapsed > 0 then
        widthLeft = (m.top.itemContent.percentageElapsed * m.totalProgress) / 100
        m.progressLeft.width = widthLeft
        m.progressRight.width = (m.totalProgress - widthLeft) 
    else
        m.progressLeft.width = 0
        m.progressRight.width = m.totalProgress
    end if

    if m.top.itemContent.imageURL <> invalid and m.top.itemContent.imageURL <> "" then 
        m.imageItem.loadSync = false
        m.imageItem.uri = m.top.itemContent.imageURL
    else if m.programContentType then
        m.imageItem.loadSync = false
        m.imageItem.uri = m.backgroundImage
    end if 
end sub

' Se dispara al dibujar en pantalla y define oppiedades del xml del componente
sub currRectChanged()
    paddingX = scaleValue(12, m.scaleInfo)
    paddingY = scaleValue(14, m.scaleInfo)
    paddingPorgressY = scaleValue(25, m.scaleInfo)
    labelWidth = scaleValue(220, m.scaleInfo)
    imageSize = scaleValue(60, m.scaleInfo)

    m.theRect.width = m.top.currRect.width
    m.theRect.height = m.top.currRect.height

    if (m.contentGroup <> invalid) then
        m.contentGroup.translation = [paddingX, paddingY]
    end if
    m.title.width = labelWidth
    m.category.width = labelWidth
    m.dateTime.width = labelWidth

    if m.programContentType then 
        m.imageItem.height = m.theRect.height
        m.imageItem.width = scaleValue(80, m.scaleInfo)
    else
        m.imageItem.height = imageSize
        m.imageItem.width = imageSize
    end if

    m.imageItem.translation = [m.theRect.width - m.imageItem.width, 0]

    m.opacityLayout.width = m.top.itemContent.size[0]
    m.opacityLayout.height = m.top.itemContent.size[1]
    
    m.progressGroup.translation = [0, m.top.itemContent.size[1] - paddingPorgressY]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.opacityLayout <> invalid then
        m.opacityLayout.opacity = 0.3 * (1.0 - m.top.focusPercent) 
    end if
end sub

' Define los colores iniciales del componente
sub __initColors()
    m.category.color = m.global.colors.LIGHT_GRAY
    m.dateTime.color = m.global.colors.LIVE_CONTENT
    m.progressLeft.color = m.global.colors.PROGRESS
    m.progressRight.color = m.global.colors.PROGRESS_BG
end sub