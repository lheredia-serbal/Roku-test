' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.scaleInfo = m.global.scaleInfo
    if m.scaleInfo = invalid then
        m.scaleInfo = getScaleInfo()
    end if

    m.theRect  = m.top.findNode("theRect")
    m.itemTitle = m.top.findNode("itemTitle")
    m.itemImage = m.top.findNode("itemImage")
    m.opacityLayout = m.top.findNode("opacityLayout")
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    m.itemTitle.text = m.top.itemContent.title
    if m.top.itemContent.imageURL <> invalid then m.itemImage.uri = m.top.itemContent.imageURL
end sub

' Se dispara al dibujar en pantalla y define oppiedades del xml del componente
sub currRectChanged()
    scaledSize = getScaledItemSize()
    scaledCurrRect = getScaledCurrRect()

    m.theRect.width = scaledCurrRect.width
    m.theRect.height = scaledCurrRect.height

    m.opacityLayout.width = scaledSize[0]
    m.opacityLayout.height = scaledSize[1]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.opacityLayout <> invalid then
        m.opacityLayout.opacity = 0.3 * (1.0 - m.top.focusPercent) 
    end if
end sub

function getScaledItemSize() as object
    if m.top.itemContent <> invalid and m.top.itemContent.size <> invalid then
        return scaleSize(m.top.itemContent.size, m.scaleInfo)
    end if

    return [0, 0]
end function

function getScaledCurrRect() as object
    scaledSize = getScaledItemSize()
    scaledWidth = scaledSize[0]
    scaledHeight = scaledSize[1]

    if m.top.currRect.width <> invalid and m.top.currRect.height <> invalid then
        scaledWidth = scaleValue(m.top.currRect.width, m.scaleInfo)
        scaledHeight = scaleValue(m.top.currRect.height, m.scaleInfo)
    end if

    return {
        width: scaledWidth,
        height: scaledHeight
    }
end function