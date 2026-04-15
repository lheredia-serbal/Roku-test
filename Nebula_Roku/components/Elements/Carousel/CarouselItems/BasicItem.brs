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
    m.showMetadataGroup = false ' NUEVO: Estado para mostrar/ocultar el bloque de metadatos como unidad.
    m.isSearchScreenContext = __isSearchScreenContext() ' NUEVO: Cachea si el item pertenece al árbol de SearchScreen.
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
        if m.metadataGroup <> invalid then m.metadataGroup.visible = false ' Oculta metadatos en tarjetas "Ver más/Guía".
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
    ' Posiciona los labels por encima del gradiente con padding.
    if m.metadataLabels <> invalid then m.metadataLabels.translation = [metadataHorizontalPadding, metadataVerticalPadding] 
     ' Altura acumulada de labels para ubicar el bloque justo sobre la barra de progreso.
    metadataLabelsHeight = 0
    ' Obtiene altura real del contenido textual.
    if m.metadataLabels <> invalid then metadataLabelsHeight = m.metadataLabels.boundingRect().height 
    ' Incluye padding superior/inferior en la altura total del bloque.
    metadataGroupHeight = metadataLabelsHeight + (metadataVerticalPadding * 2) 
    ' Coloca metadataGroup justo arriba de progressContainer.
    if m.metadataGroup <> invalid then m.metadataGroup.translation = [imageX + m.padding, imageY + imageHeight - metadataGroupHeight - scaleValue(15, m.scaleInfo) - metadataBottomSpacing] 
    ' Hace que el gradiente cubra todo el ancho del bloque de metadatos.
    if m.metadataGradient <> invalid then m.metadataGradient.width = metadataWidth 
    ' Hace que el gradiente cubra toda la altura del bloque de metadatos.
    if m.metadataGradient <> invalid then m.metadataGradient.height = metadataGroupHeight 

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

' NUEVO: Replica la lógica de SquareFeaturedItem para limpiar/mostrar title-category-dateTime de forma consistente.
sub __updateMetadataVisibility()
    m.showMetadataGroup = false ' NUEVO: Reinicia el estado antes de recalcular visibilidad.

    m.title.visible = false ' NUEVO: Limpia estado previo del título para evitar artefactos por reciclado de celdas.
    m.category.visible = false ' NUEVO: Limpia estado previo de categoría para evitar artefactos por reciclado de celdas.
    m.dateTime.visible = false ' NUEVO: Limpia estado previo de fecha/hora para evitar artefactos por reciclado de celdas.

    if m.top.itemContent.title <> invalid and m.top.itemContent.title <> "" then ' NUEVO: Muestra título solo si viene informado.
        m.title.text = m.top.itemContent.title ' NUEVO: Asigna el título al label de metadatos.
        m.title.visible = true ' NUEVO: Habilita renderizado de título.
        m.showMetadataGroup = true ' NUEVO: Marca el grupo para mostrarse porque hay información útil.
    end if

    if m.top.itemContent.category <> invalid and m.top.itemContent.category <> "" then ' NUEVO: Muestra categoría solo si viene informada.
        m.category.text = m.top.itemContent.category ' NUEVO: Asigna la categoría al label de metadatos.
        m.category.visible = true ' NUEVO: Habilita renderizado de categoría.
        m.showMetadataGroup = true ' NUEVO: Mantiene visible el grupo al tener información útil.
    end if

    if m.top.itemContent.date <> invalid and m.top.itemContent.date <> "" then ' NUEVO: Muestra fecha/hora solo si viene informada.
        m.dateTime.text = m.top.itemContent.date ' NUEVO: Asigna la fecha/hora al label de metadatos.
        m.dateTime.visible = true ' NUEVO: Habilita renderizado de fecha/hora.
        m.showMetadataGroup = true ' NUEVO: Mantiene visible el grupo al tener información útil.
    end if

    __applyMetadataGroupVisibility() ' NUEVO: Aplica la regla final (SearchScreen + foco + datos disponibles).
end sub

' NUEVO: Determina si este item vive dentro de SearchScreen recorriendo el árbol de padres.
function __isSearchScreenContext() as boolean
    currentNode = m.top ' NUEVO: Inicia el recorrido desde el nodo actual del item.
    while currentNode <> invalid ' NUEVO: Recorre padres hasta llegar a la raíz.
        if currentNode.subtype() = "SearchScreen" then return true ' NUEVO: Confirma contexto de SearchScreen cuando encuentra el subtipo.
        currentNode = currentNode.getParent() ' NUEVO: Avanza al siguiente padre en la jerarquía.
    end while
    return false ' NUEVO: Si no encontró SearchScreen, no debe mostrarse metadataGroup.
end function

' NUEVO: Unifica la condición final de visibilidad para metadataGroup.
sub __applyMetadataGroupVisibility()
    hasFocus = false ' NUEVO: Estado por defecto sin foco.
    if m.top.groupHasFocus <> invalid then hasFocus = m.top.groupHasFocus ' NUEVO: Usa el flag de foco de grupo cuando esté disponible.
    if m.top.groupHasFocus = invalid and m.top.focusPercent <> invalid and m.top.focusPercent > 0 then hasFocus = true ' NUEVO: Fallback a focusPercent para casos sin groupHasFocus.
    if m.metadataGroup <> invalid then m.metadataGroup.visible = (m.showMetadataGroup and m.isSearchScreenContext and hasFocus) ' NUEVO: Visible solo en SearchScreen + foco + metadata válida.
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
