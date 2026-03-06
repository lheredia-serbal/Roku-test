' Inicializa referencias y renderiza el estado inicial del componente.
sub init()
    ' Referencia al poster de fondo.
    m.backgroundImage = m.top.findNode("backgroundImage")
    ' Referencia a la capa oscura que mejora legibilidad sobre la imagen.
    m.overlay = m.top.findNode("overlay")

    ' Opacidad por defecto para dots inactivos.
    m.inactiveDotOpacity = 0.45
    ' Opacidad para dot activo.
    m.activeDotOpacity = 1.0
    ' Tamaño de cada dot.
    m.dotSize = 12

    m.scaleInfo = m.global.scaleInfo

    ' Control de animación horizontal entre elementos de News.
    m.slideTimer = m.top.findNode("slideTimer")
    m.slideTotalFrames = 6
    m.slideCurrentFrame = 0
    m.slideOffset = 0
    m.slideStep = 0
    m.isSliding = false

    if m.slideTimer <> invalid then
        m.slideTimer.unobserveField("fire")
        m.slideTimer.observeField("fire", "onSlideFrame")
    end if


    ' Ajusta layout base a pantalla completa y dibuja contenido inicial.
    updateLayoutForResolution()
    renderCurrentItem()
end sub

' Reacciona a cambios en la lista de items.
sub itemsChanged()
    ' Normaliza índice cuando cambia el dataset.
    normalizeCurrentIndex()
    ' Redibuja item actual con la nueva data.
    renderCurrentItem()
end sub

' Reacciona al cambio de índice actual.
sub currentIndexChanged()
    ' Garantiza que el índice esté en rango.
    normalizeCurrentIndex()
    ' Actualiza imagen/título visibles.
    renderCurrentItem()
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
end sub

' Dibuja contenido del item activo (imagen + título).
sub renderCurrentItem()
    ' Obtiene item activo según currentIndex.
    currentItem = getCurrentItem()

    ' Si no hay item válido, no hay cambios visuales internos adicionales.
    if currentItem = invalid then return
    ' Aplica imagen final (o fallback del campo público imageURL).
    if currentItem.image <> invalid then
        ' Asigna imagen proveniente del item.
        m.backgroundImage.uri = getImageUrl(currentItem.image)
    end if
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

' Maneja navegación horizontal del News hero.
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    totalItems = getItemsCount()
    if totalItems <= 0 then return false

    if key = KeyButtons().RIGHT then
        if m.top.currentIndex < (totalItems - 1) then
            startSlideTransition(m.top.currentIndex + 1, 0)
        end if
        return true
    else if key = KeyButtons().LEFT then
        if m.top.currentIndex > 0 then
            startSlideTransition(m.top.currentIndex - 1, 1)
            return true
        end if

        ' En el primer elemento, no consume LEFT para permitir que MainScreen abra el menú.
        return false
    end if

    return false
end function

' Inicia una transición horizontal y actualiza el item activo.
sub startSlideTransition(newIndex as integer, direction as integer)
    if m.isSliding then return

    m.isSliding = true
    m.slideCurrentFrame = 0
    m.slideOffset = int(m.backgroundImage.width * 0.22) * direction

    m.backgroundImage.translation = [m.slideOffset, 0]
    if m.overlay <> invalid then m.overlay.translation = [m.slideOffset, 0]

    m.top.currentIndex = newIndex

    if m.slideTimer <> invalid then
        m.slideTimer.control = "start"
    else
        finalizeSlideTransition()
    end if
end sub

' Avanza un frame de la animación horizontal.
sub onSlideFrame()
    if not m.isSliding then return

    m.slideCurrentFrame = m.slideCurrentFrame + 1

    newOffset = __getSlideOffsetForFrame()

    m.backgroundImage.translation = [newOffset, 0]
    if m.overlay <> invalid then m.overlay.translation = [newOffset, 0]

    if m.slideCurrentFrame >= m.slideTotalFrames then
        finalizeSlideTransition()
    end if
end sub

' Cierra la transición y restablece posiciones base.
sub finalizeSlideTransition()
    if m.slideTimer <> invalid then m.slideTimer.control = "stop"

    m.isSliding = false
    m.slideCurrentFrame = 0
    m.slideOffset = 0

    m.backgroundImage.translation = [0, 0]
    if m.overlay <> invalid then m.overlay.translation = [0, 0]
end sub


' Devuelve el desplazamiento horizontal interpolado para el frame actual (ease-out).
function __getSlideOffsetForFrame() as integer
    if m.slideTotalFrames <= 0 then return 0

    progress = m.slideCurrentFrame / m.slideTotalFrames
    if progress < 0 then progress = 0
    if progress > 1 then progress = 1

    easedProgress = 1 - ((1 - progress) * (1 - progress))
    return int(m.slideOffset * (1 - easedProgress))
end function