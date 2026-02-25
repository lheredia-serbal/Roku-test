' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect  = m.top.findNode("theRect")
    m.itemTitle = m.top.findNode("itemTitle")
    m.itemImage = m.top.findNode("itemImage")
    m.opacityLayout = m.top.findNode("opacityLayout")
    
    m.scaleInfo = m.global.scaleInfo
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if (m.top.itemContent.showSeeMore <> invalid and m.top.itemContent.showSeeMore = true) or (m.top.itemContent.goToGuide <> invalid and m.top.itemContent.goToGuide = true) then
        m.itemTitle.text = m.top.itemContent.title
        m.itemImage.uri = ""
        return
    end if

    m.itemTitle.text = m.top.itemContent.title
    if m.top.itemContent.imageURL <> invalid then m.itemImage.uri = m.top.itemContent.imageURL
end sub

' Se dispara al dibujar en pantalla y define oppiedades del xml del componente
sub currRectChanged()
    scaledSize = m.top.itemContent.size
    scaledCurrRect = m.top.itemContent.size

    m.theRect.width = scaledCurrRect[0]
    m.theRect.height = scaledCurrRect[1]

    m.itemImage.width = scaleValue(60, m.scaleInfo)
    m.itemImage.height = scaleValue(60, m.scaleInfo)
    m.itemImage.translation = scaleSize([30, 16], m.scaleInfo) 

    m.itemTitle.width = scaleValue(110, m.scaleInfo)
    m.itemTitle.height = scaleValue(48, m.scaleInfo)
    m.itemTitle.translation = scaleSize([5, 72], m.scaleInfo)

    m.opacityLayout.width = scaledSize[0]
    m.opacityLayout.height = scaledSize[1]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.opacityLayout <> invalid then
        m.opacityLayout.opacity = 0.3 * (1.0 - m.top.focusPercent) 
    end if
end sub