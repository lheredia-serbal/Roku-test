' Inicializa referencias y renderiza el estado inicial del componente.
sub init()
    ' Referencia al poster de fondo.
    m.backgroundImage = m.top.findNode("backgroundImage")
    ' Referencia al label de título principal.
    m.newsTitle = m.top.findNode("newsTitle")
    ' Referencia al contenedor donde se dibujan los dots.
    m.dotsContainer = m.top.findNode("dotsContainer")
    ' Referencia a la capa oscura que mejora legibilidad sobre la imagen.
    m.overlay = m.top.findNode("overlay")

    ' Color por defecto para dots inactivos (gris claro).
    m.inactiveDotColor = "#CFCFCF"
    ' Color para dot activo (blanco).
    m.activeDotColor = "#FFFFFF"
    ' Tamaño de cada dot.
    m.dotSize = 12

    ' Ajusta layout base a pantalla completa y dibuja contenido inicial.
    updateLayoutForResolution()
    renderCurrentItem()
    renderDots()
end sub

' Reacciona a cambios en la lista de items.
sub itemsChanged()
    ' Normaliza índice cuando cambia el dataset.
    normalizeCurrentIndex()
    ' Redibuja item actual con la nueva data.
    renderCurrentItem()
    ' Redibuja dots según cantidad de items.
    renderDots()
end sub

' Reacciona al cambio de índice actual.
sub currentIndexChanged()
    ' Garantiza que el índice esté en rango.
    normalizeCurrentIndex()
    ' Actualiza imagen/título visibles.
    renderCurrentItem()
    ' Actualiza dot activo.
    renderDots()
end sub

' Reacciona al cambio del título fallback.
sub titleChanged()
    ' Re-renderiza para usar título fallback si aplica.
    renderCurrentItem()
end sub

' Reacciona al cambio de imagen fallback.
sub imageURLChanged()
    ' Re-renderiza para usar imagen fallback si aplica.
    renderCurrentItem()
end sub

' Ajusta tamaños/posiciones para resolución FHD/HD.
sub updateLayoutForResolution()
    ' Lee dimensiones del display actual.
    screenWidth = 1920
    ' Establece alto por defecto FHD.
    screenHeight = 1080

    ' Si hay Scene disponible, usa su tamaño real.
    if m.top.getScene() <> invalid then
        ' Obtiene ancho real de escena.
        if m.top.getScene().currentDesignResolution <> invalid then
            ' Lee resolución de diseño actual.
            screenWidth = m.top.getScene().currentDesignResolution.width
            ' Lee alto de diseño actual.
            screenHeight = m.top.getScene().currentDesignResolution.height
        end if
    end if

    ' Hace que la imagen de fondo ocupe el ancho completo del display.
    m.backgroundImage.width = screenWidth
    ' Aplica el alto efectivo del bloque de noticias a la imagen de fondo.
    m.backgroundImage.height = screenHeight

    ' Ajusta el overlay para que cubra exactamente el bloque visible de noticias.
    if m.overlay <> invalid then
        ' Aplica ancho completo del bloque de noticias al overlay.
        m.overlay.width = screenWidth
        ' Aplica el alto efectivo del bloque de noticias al overlay.
        m.overlay.height = screenHeight
    end if

    ' Ajusta ancho máximo útil del título.
    m.newsTitle.width = int(screenWidth * 0.72)
    ' Mantiene un alto cómodo para hasta 3 líneas grandes.
    m.newsTitle.height = int(screenHeight * 0.30)
    ' Posiciona el título abajo-izquierda con margen dentro del bloque de noticias.
    m.newsTitle.translation = [int(screenWidth * 0.04), int(screenHeight * 0.62)]

    ' Centra los dots cerca del borde inferior del bloque de noticias.
    m.dotsContainer.translation = [int(screenWidth * 0.50), int(screenHeight * 0.92)]
end sub

' Dibuja contenido del item activo (imagen + título).
sub renderCurrentItem()
    ' Obtiene item activo según currentIndex.
    currentItem = getCurrentItem()

    ' Si no hay item válido, usa fallback de campos públicos.
    if currentItem = invalid then
        ' Setea título fallback definido externamente.
        m.newsTitle.text = m.top.title
        return
    end if
    ' Resuelve título del item.
    titleValue = ""
    ' Toma title si existe.
    if currentItem.title <> invalid then titleValue = currentItem.title

    ' Aplica imagen final (o fallback del campo público imageURL).
    if currentItem.image <> invalid then
        ' Asigna imagen proveniente del item.
        m.backgroundImage.uri = getImageUrl(currentItem.image)
    end if

    ' Aplica título final (o fallback del campo público title).
    if titleValue <> "" then
        ' Asigna título proveniente del item.
        m.newsTitle.text = titleValue
    else
        ' Asigna título fallback si item no trae título.
        m.newsTitle.text = m.top.title
    end if
end sub

' Redibuja el listado de dots y marca activo en blanco.
sub renderDots()
    ' Limpia dots previos para reconstruir el indicador.
    m.dotsContainer.removeChildrenIndex(m.dotsContainer.getChildCount(), 0)

    ' Obtiene cantidad de items para saber cuántos dots dibujar.
    totalItems = getItemsCount()

    ' Si no hay items, no dibuja dots.
    if totalItems <= 0 then return

    ' Recorre cada posición de item para crear su dot.
    for i = 0 to totalItems - 1
        ' Crea un rectángulo cuadrado como dot.
        dot = createObject("roSGNode", "Rectangle")
        ' Define ancho del dot.
        dot.width = m.dotSize
        ' Define alto del dot.
        dot.height = m.dotSize

        ' Pinta de blanco el dot activo y gris claro los demás.
        if i = m.top.currentIndex then
            ' Color activo.
            dot.color = m.activeDotColor
        else
            ' Color inactivo.
            dot.color = m.inactiveDotColor
        end if

        ' Agrega el dot al contenedor horizontal.
        m.dotsContainer.appendChild(dot)
    end for
end sub

' Devuelve el item activo actual o invalid.
function getCurrentItem() as dynamic
    ' Si items no es válido, no hay item activo.
    if m.top.items = invalid then return invalid
    ' Si items no tiene elementos, no hay item activo.
    if m.top.items.count() <= 0 then return invalid
    ' Si el índice cae fuera de rango, devuelve invalid.
    if m.top.currentIndex < 0 or m.top.currentIndex >= m.top.items.count() then return invalid
    ' Devuelve el item correspondiente al índice actual.
    return m.top.items[m.top.currentIndex]
end function

' Devuelve cantidad de items en el slider.
function getItemsCount() as integer
    ' Si items no es válido, retorna 0.
    if m.top.items = invalid then return 0
    ' Retorna longitud de items.
    return m.top.items.count()
end function

' Corrige currentIndex para mantenerlo entre 0 y count-1.
sub normalizeCurrentIndex()
    ' Obtiene cantidad total de items.
    totalItems = getItemsCount()

    ' Si no hay items, fuerza índice a 0 y termina.
    if totalItems <= 0 then
        ' Resetea índice sin items.
        m.top.currentIndex = 0
        return
    end if

    ' Si índice es negativo, lo corrige al primero.
    if m.top.currentIndex < 0 then
        ' Corrige al índice inicial.
        m.top.currentIndex = 0
        return
    end if

    ' Si índice supera el máximo, lo corrige al último.
    if m.top.currentIndex >= totalItems then
        ' Corrige al último índice válido.
        m.top.currentIndex = totalItems - 1
    end if
end sub
