' Inicialización del componente (parte del ciclo de vida de Roku)
sub init()
    m.theRect  = m.top.findNode("theRect")
    m.progressContainer = m.top.findNode("progressContainer")
    m.imageItem = m.top.findNode("imageItem")
    m.metadataGroup = m.top.findNode("metadataGroup")
    m.metadataGradient = m.top.findNode("metadataGradient")
    m.metadataLabels = m.top.findNode("metadataLabels")
    m.title = m.top.findNode("title")
    m.category = m.top.findNode("category")
    m.dateTime = m.top.findNode("dateTime")
    m.progressLeft = m.top.findNode("progressLeft")
    m.progressRight = m.top.findNode("progressRight")
    m.opacityLayout = m.top.findNode("opacityLayout")
    m.programTitleByError = m.top.findNode("programTitleByError")
    m.programTitle = m.top.findNode("programTitle")
    
    m.scaleInfo = m.global.scaleInfo
    
    m.padding = scaleValue(10, m.scaleInfo)
    m.backgroundImage = invalid
    m.showBackgroundImage = false
    m.showMetadataGroup = false
    m.isSearchScreenContext = false
    __initConfig()
end sub

' Carga los datos de Node en el compoente
sub itemContentChanged()
    if (m.top.itemContent.showSeeMore <> invalid and m.top.itemContent.showSeeMore = true) or (m.top.itemContent.goToGuide <> invalid and m.top.itemContent.goToGuide = true) then
        m.programTitle.text = m.top.itemContent.title
        m.programTitle.font = "font:MediumSystemFont"
        m.imageItem.loadingBitmapUri = ""
        m.imageItem.failedBitmapUri = ""
        m.programTitleByError.visible = true

        m.showBackgroundImage = false
        m.imageItem.uri = ""

        m.progressLeft.width = 0
        m.progressRight.width = 0
        ' Oculta metadatos en tarjetas "Ver más/Guía".
        if m.metadataGroup <> invalid then m.metadataGroup.visible = false 
        return
    else
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

    end if

    __updateMetadataVisibility() 

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
    imageWidth = scaledSize[0]
    imageHeight = scaledSize[1]
    imageX = 0
    imageY = 0

    m.theRect.width = scaledCurrRect.width
    m.theRect.height = scaledCurrRect.height

    if imageWidth = 0 or imageHeight = 0 then
        imageWidth = scaledCurrRect.width
        imageHeight = scaledCurrRect.height
    end if

    if scaledCurrRect.width > imageWidth then
        imageX = (scaledCurrRect.width - imageWidth) / 2
    end if

    if scaledCurrRect.height > imageHeight then
        imageY = (scaledCurrRect.height - imageHeight) / 2
    end if

    m.imageItem.width = imageWidth
    m.imageItem.height = imageHeight
    m.imageItem.translation = [imageX, imageY]

    m.opacityLayout.width = imageWidth
    m.opacityLayout.height = imageHeight
    m.opacityLayout.translation = [imageX, imageY]

    m.programTitleByError.translation = [imageX + (imageWidth / 2), imageY + (imageHeight / 2)]

    m.programTitle.width = (imageWidth - m.padding)
    m.programTitle.height = (imageHeight - m.padding)

    ' Calcula ancho útil del bloque de metadatos.
    metadataWidth = imageWidth - (m.padding * 2) 
    if metadataWidth < 0 then metadataWidth = 0
    ' Padding interno horizontal para separar labels del borde del gradiente.
    metadataHorizontalPadding = scaleValue(8, m.scaleInfo)
    ' Padding interno vertical para separar labels del borde del gradiente.
    metadataVerticalPadding = scaleValue(6, m.scaleInfo) 
    ' Espacio entre metadataGroup y progressContainer.
    metadataBottomSpacing = scaleValue(4, m.scaleInfo)
    ' Ajusta ancho del título al área interna del gradiente. 
    m.title.width = metadataWidth - (metadataHorizontalPadding * 2) 
    ' Ajusta ancho de categoría al área interna del gradiente.
    m.category.width = metadataWidth - (metadataHorizontalPadding * 2) 
    ' Ajusta ancho de fecha/hora al área interna del gradiente.
    m.dateTime.width = metadataWidth - (metadataHorizontalPadding * 2) 
    if m.title.width < 0 then m.title.width = 0
    if m.category.width < 0 then m.category.width = 0 
    if m.dateTime.width < 0 then m.dateTime.width = 0
    ' Altura acumulada de labels para ubicar el bloque justo sobre la barra de progreso.
    metadataLabelsHeight = 0
    ' Obtiene altura real del contenido textual.
    if m.metadataLabels <> invalid then metadataLabelsHeight = m.metadataLabels.boundingRect().height 
    ' Incluye padding superior/inferior en la altura total del bloque.
    metadataGroupHeight = metadataLabelsHeight + (metadataVerticalPadding * 2)
    ' Desplaza levemente labels hacia abajo para acercarlos al borde inferior.
    metadataLabelsBottomOffset = scaleValue(6, m.scaleInfo)
    metadataLabelsY = imageHeight - scaleValue(40, m.scaleInfo) - metadataBottomSpacing + metadataVerticalPadding + metadataLabelsBottomOffset
    if metadataLabelsY < 0 then metadataLabelsY = 0
    ' Posiciona labels en la parte inferior para mantener el mismo layout de metadata.
    if m.metadataLabels <> invalid then m.metadataLabels.translation = [m.padding + metadataHorizontalPadding, metadataLabelsY]
    ' Hace que metadataGroup cubra todo el componente para que su gradiente ocupe ancho/alto completos.
    if m.metadataGroup <> invalid then m.metadataGroup.translation = [imageX, imageY]
    ' Hace que el gradiente cubra todo el ancho del componente.
    if m.metadataGradient <> invalid then m.metadataGradient.width = imageWidth
    ' Hace que el gradiente cubra toda la altura del componente.
    if m.metadataGradient <> invalid then m.metadataGradient.height = imageHeight

    m.progressContainer.translation = [m.padding , scaledCurrRect.height - scaleValue(15, m.scaleInfo)]
end sub

' Define el estilo de foco del componente y como se comporta al tener o no el foco
sub focusPercentChanged()
    if m.opacityLayout <> invalid then
        m.opacityLayout.opacity = 0.3 * (1.0 - m.top.focusPercent) 
    end if

    ' Reevalúa visibilidad de metadatos al cambiar foco.
    __applyMetadataGroupVisibility() 
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

    m.category.color = m.global.colors.LIGHT_GRAY 
    m.dateTime.color = m.global.colors.LIVE_CONTENT 

    m.imageItem.ObserveField("loadStatus", "onStatusChange")
end sub

function getScaledItemSize() as object
    if m.top.itemContent <> invalid and m.top.itemContent.size <> invalid then
       return m.top.itemContent.size
    end if

    return [0, 0]
end function

' Replica la lógica de SquareFeaturedItem para limpiar/mostrar title-category-dateTime de forma consistente.
 sub __updateMetadataVisibility()
    'Reinicia el estado antes de recalcular visibilidad.
    m.showMetadataGroup = false 

    m.title.visible = true 
    m.category.visible = false
    m.dateTime.visible = true

    if m.top.itemContent.title <> invalid and m.top.itemContent.title <> "" then
        m.title.text = m.top.itemContent.title
        m.title.visible = true
        m.showMetadataGroup = true
    end if

    if m.top.itemContent.category <> invalid and m.top.itemContent.category <> "" then
        m.category.text = m.top.itemContent.category
        m.category.visible = true
        m.showMetadataGroup = true
    end if

    if m.top.itemContent.formattedDuration <> invalid and m.top.itemContent.daformattedDurationte <> "" then
        m.dateTime.text = m.top.itemContent.formattedDuration
        m.dateTime.visible = true
        m.showMetadataGroup = true
    end if

    __applyMetadataGroupVisibility()
end sub

' NUEVO: Determina si este item vive dentro de SearchScreen recorriendo el árbol de padres.
function __isSearchScreenContext() as boolean
    currentNode = m.top
    ' Recorre padres hasta llegar a la raíz.
    while currentNode <> invalid 
        ' Confirma contexto de SearchScreen cuando encuentra el subtipo.
        if currentNode.subtype() = "SearchScreen" then return true 
        ' Avanza al siguiente padre en la jerarquía.
        currentNode = currentNode.getParent() 
    end while
    return false
end function

' Unifica la condición final de visibilidad para metadataGroup.
sub __applyMetadataGroupVisibility()
    hasItemFocus = false
    hasCarouselFocus = false
    ' Actualiza contexto dinámicamente porque el árbol de padres puede no estar completo en init().
    m.isSearchScreenContext = __isSearchScreenContext()

    ' Detecta el item actualmente seleccionado del carrusel.
    if m.top.focusPercent <> invalid and m.top.focusPercent >= 0.95 then hasItemFocus = true
    ' Detecta si el carrusel que contiene el item tiene foco activo.
    if m.top.groupHasFocus <> invalid and m.top.groupHasFocus = true then hasCarouselFocus = true

    if m.metadataGroup <> invalid then
        ' En SearchScreen solo mostramos metadata cuando el item y su carrusel tienen foco.
        if m.isSearchScreenContext then
            m.metadataGroup.visible = (m.showMetadataGroup and hasItemFocus and hasCarouselFocus)
        else
            ' Fuera de SearchScreen mantenemos el comportamiento estándar.
            m.metadataGroup.visible = m.showMetadataGroup
        end if
    end if
end sub

' Obtiene el rectángulo escalado actual.
function getScaledCurrRect() as object
    scaledWidth = m.top.currRect.width
    scaledHeight = m.top.currRect.height

    if m.top.currRect.width <> invalid and m.top.currRect.height <> invalid then
        scaledWidth = m.top.currRect.width
        scaledHeight = m.top.currRect.height
    end if

    return {
        width: scaledWidth,
        height: scaledHeight
    }
end function