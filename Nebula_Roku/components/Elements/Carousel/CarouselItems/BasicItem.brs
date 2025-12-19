' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.theRect  = m.top.findNode("theRect")
    m.progressContainer = m.top.findNode("progressContainer")
    m.imageItem = m.top.findNode("imageItem")
    m.progressLeft = m.top.findNode("progressLeft")
    m.progressRight = m.top.findNode("progressRight")
    m.opacityLayout = m.top.findNode("opacityLayout")
    m.programTitleByError = m.top.findNode("programTitleByError")
    m.programTitle = m.top.findNode("programTitle")
    
    m.padding = scaleValue(10, m.scaleInfo)
    m.backgroundImage = invalid
    m.showBackgroundImage = false
    __initConfig()
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if m.top.itemContent.title <> invalid and m.top.itemContent.title <> "" then 
        m.programTitle.text = m.top.itemContent.title
        if m.top.itemContent.style = getCarouselStyles().PORTRAIT_FEATURED then 
            m.programTitle.font = "font:MediumSystemFont"
        else if (m.top.itemContent.style = getCarouselStyles().LANDSCAPE_STANDARD) or (m.top.itemContent.style = getCarouselStyles().LANDSCAPE_FEATURED) then 
            m.programTitle.font = "font:LargeSystemFont"
        else
            m.programTitle.font = "font:SmallSystemFont"
        end if 

        if (m.top.itemContent.imageURL = invalid) or (m.top.itemContent.imageURL <> invalid and  m.top.itemContent.imageURL <> "" and m.imageItem.uri <> m.top.itemContent.imageURL) then 
            m.programTitleByError.visible = true
        end if
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

    scaledSize = getScaledItemSize()

    if m.top.itemContent.percentageElapsed <> invalid and m.top.itemContent.percentageElapsed > 0 then
        widthLeft = (m.top.itemContent.percentageElapsed * (scaledSize[0] - (m.padding*2))) / 100

        m.progressLeft.width = widthLeft
        m.progressRight.width = (scaledSize[0] - (m.padding*2) - widthLeft)
    else
        m.progressLeft.width = 0
        m.progressRight.width = 0
    end if
end sub

' Se dispara al dibujar en pantalla y define propiedades del xml del componente
sub currRectChanged()
    scaledSize = getScaledItemSize()
    scaledCurrRect = getScaledCurrRect()

    m.theRect.width = scaledCurrRect.width
    m.theRect.height = scaledCurrRect.height

    m.imageItem.width = scaledSize[0]
    m.imageItem.height = scaledSize[1]

    m.opacityLayout.width = scaledSize[0]
    m.opacityLayout.height = scaledSize[1]

    m.programTitleByError.translation = [(scaledSize[0] / 2), (scaledSize[1] / 2)]

    m.programTitle.width = (scaledSize[0] - m.padding)
    m.programTitle.height = (scaledSize[1] - m.padding)

    m.progressContainer.translation = [m.padding , scaledCurrRect.height - scaleValue(20, m.scaleInfo)]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.opacityLayout <> invalid then
        m.opacityLayout.opacity = 0.3 * (1.0 - m.top.focusPercent) 
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

    m.progressLeft.color = m.global.colors.PROGRESS
    m.progressRight.color = m.global.colors.PROGRESS_BG

    scaledHeight = scaleValue(3, m.scaleInfo)
    m.progressLeft.height = scaledHeight
    m.progressRight.height = scaledHeight

    m.imageItem.ObserveField("loadStatus", "onStatusChange")
end sub

function getScaledItemSize() as object
    if m.top.itemContent <> invalid and m.top.itemContent.size <> invalid then
        return [scaleValue(m.top.itemContent.size[0], m.scaleInfo), scaleValue(m.top.itemContent.size[1], m.scaleInfo)]
    end if

    return [0, 0]
end function

function getScaledCurrRect() as object
    scaledWidth = m.top.currRect.width
    scaledHeight = m.top.currRect.height

    if m.top.currRect.width <> invalid and m.top.currRect.height <> invalid then
        scaledWidth = scaleValue(m.top.currRect.width, m.scaleInfo)
        scaledHeight = scaleValue(m.top.currRect.height, m.scaleInfo)
    end if

    return {
        width: scaledWidth,
        height: scaledHeight
    }
end function
