' Inicializa referencias y renderiza el estado inicial del componente.
sub init()
    ' Referencia al poster de fondo principal.
    m.backgroundImage = m.top.findNode("backgroundImage")
    ' Referencia al poster secundario usado para el item entrante en la animación.
    m.incomingBackgroundImage = m.top.findNode("incomingBackgroundImage")
    ' Referencia a la capa oscura que mejora legibilidad sobre la imagen.
    m.overlay = m.top.findNode("overlay")
    ' Referencia al label interno que muestra el título de la noticia actual.
    m.newsTitle = m.top.findNode("newsTitle")

    ' Referencia al bloque de acción de detalle.
    m.detailActionGroup = m.top.findNode("detailActionGroup")
    ' Referencia al label del bloque de acción.
    m.detailActionLabel = m.top.findNode("detailActionLabel")
    ' Referencia al ícono del bloque de acción.
    m.detailActionIcon = m.top.findNode("detailActionIcon")
    ' Referencia al fondo del bloque de acción.
    m.detailActionBackground = m.top.findNode("detailActionBackground")
    ' Referencia a los bordes
    m.borderDetailAction = m.top.findNode("borderDetailAction")

    ' Guarda escala global de la app para cálculo responsive.
    m.scaleInfo = m.global.scaleInfo

    ' Control de animación horizontal entre elementos de News.
    m.slideTimer = m.top.findNode("slideTimer")
    ' Define 10 frames para slide principal: 10 * 0.05s = 0.5 segundos.
    m.slideTotalFrames = 10
    ' Inicializa frame actual de la animación.
    m.slideCurrentFrame = 0
    ' Inicializa dirección horizontal del slide (1 derecha / -1 izquierda).
    m.slideDirection = 0
    ' Inicializa posición inicial del item entrante.
    m.incomingStartX = 0
    ' Inicializa posición final del item saliente.
    m.outgoingEndX = 0
    ' Inicializa estado de animación en reposo.
    m.isSliding = false

    ' Registra callback del timer para avanzar frame a frame.
    if m.slideTimer <> invalid then
        ' Elimina observador previo para evitar dobles disparos.
        m.slideTimer.unobserveField("fire")
        ' Asocia el evento fire al handler de animación.
        m.slideTimer.observeField("fire", "onSlideFrame")
    end if

    ' Ajusta layout base a pantalla completa y dibuja contenido inicial.
    updateLayoutForResolution()
    ' Renderiza el primer item disponible.
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
    ' Si hay animación en curso, evita re-render inmediato para no romper el slide dual.
    if m.isSliding then return
    ' Actualiza imagen/título visibles cuando no hay animación.
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
    ' Usa base 1280x720 para que el escalado lleve el fondo al tamaño real de pantalla.
    baseScreenWidth = 1280
    baseScreenHeight = 720

    ' Hace que la imagen de fondo ocupe el ancho completo del display.
    m.backgroundImage.width = scaleValue(baseScreenWidth, m.scaleInfo)
    ' Aplica el alto efectivo del bloque de noticias a la imagen de fondo.
    m.backgroundImage.height = scaleValue(baseScreenHeight, m.scaleInfo)
    ' Mantiene el fondo anclado en el origen.
    m.backgroundImage.translation = scaleSize([0, 0], m.scaleInfo)

    ' Hace que la imagen entrante tenga el mismo tamaño que el fondo principal.
    if m.incomingBackgroundImage <> invalid then
        ' Copia el ancho escalado para el item entrante.
        m.incomingBackgroundImage.width = scaleValue(baseScreenWidth, m.scaleInfo)
        ' Copia el alto escalado para el item entrante.
        m.incomingBackgroundImage.height = scaleValue(baseScreenHeight, m.scaleInfo)
        ' Mantiene el item entrante anclado al origen en reposo.
        m.incomingBackgroundImage.translation = scaleSize([0, 0], m.scaleInfo)
    end if

    ' Ajusta el overlay para que cubra exactamente el bloque visible de noticias.
    if m.overlay <> invalid then
        ' Aplica ancho completo del bloque de noticias al overlay.
        m.overlay.width = scaleValue(baseScreenWidth, m.scaleInfo)
        ' Aplica el alto efectivo del bloque de noticias al overlay.
        m.overlay.height = scaleValue(baseScreenHeight, m.scaleInfo)
        ' Mantiene el overlay anclado en el origen.
        m.overlay.translation = scaleSize([0, 0], m.scaleInfo)
    end if
    ' Ajusta el label de título para ubicarlo abajo a la izquierda del bloque de News.
    if m.newsTitle <> invalid then
        ' Configura ancho máximo del título para permitir hasta tres líneas legibles.
        m.newsTitle.width = scaleValue(760, m.scaleInfo)
        ' Configura alto del título para evitar recorte del texto.
        m.newsTitle.height = scaleValue(190, m.scaleInfo)
        ' Posiciona el título en la esquina inferior izquierda del hero de News.
        m.newsTitle.translation = scaleSize([140, 300], m.scaleInfo)
        ' Asegura que el texto sea visible sobre el fondo.
        m.newsTitle.visible = true
    end if

    if m.borderDetailAction <> invalid then
        m.borderDetailAction.size = scaleSize([238, 58], m.scaleInfo)
    end if

    if m.detailActionGroup <> invalid then
        m.detailActionGroup.translation = scaleSize([950, 440], m.scaleInfo)
    end if

    if m.detailActionBackground <> invalid then
        m.detailActionBackground.width = scaleValue(241, m.scaleInfo)
        m.detailActionBackground.height = scaleValue(61, m.scaleInfo)
        m.detailActionBackground.color = m.global.colors.PRIMARY
    end if

    if m.detailActionLabel <> invalid then
        m.detailActionLabel.translation = scaleSize([25, 25], m.scaleInfo)
    end if

    if m.detailActionIcon <> invalid then
        m.detailActionIcon.width = scaleValue(23, m.scaleInfo)
        m.detailActionIcon.height = scaleValue(23, m.scaleInfo)
        m.detailActionIcon.translation = scaleSize([190, 20], m.scaleInfo)
    end if
end sub


' Dibuja contenido del item activo (imagen + título).
sub renderCurrentItem()
    ' Obtiene item activo según currentIndex.
    currentItem = getCurrentItem()

    ' Si no hay item válido, no hay cambios visuales internos adicionales.
    if currentItem = invalid then
        ' Limpia el texto cuando no hay item activo para evitar títulos residuales.
        if m.newsTitle <> invalid then m.newsTitle.text = ""
        ' Corta el flujo porque no hay contenido para renderizar.
        return
    end if
    ' Resuelve uri de imagen para el item actual.
    currentImageUri = getItemImageUri(currentItem)
    ' Si existe una imagen válida, la aplica al fondo principal.
    if currentImageUri <> invalid then
        ' Asigna imagen proveniente del item.
        m.backgroundImage.uri = currentImageUri
    end if
    ' Actualiza el texto del título con la noticia activa o el fallback del carrusel.
    updateNewsTitle(currentItem)

    ' Actualiza visibilidad y contenido del CTA según redirectKey.
    updateDetailActionCTA(currentItem)
end sub

' Actualiza el label interno de News con el título correspondiente al item actual.
sub updateNewsTitle(currentItem as dynamic)
    ' Sale temprano si el nodo del título no existe en el árbol visual.
    if m.newsTitle = invalid then return
    ' Inicializa el título con el fallback de carrusel cuando exista.
    resolvedTitle = m.top.title
    ' Si el item actual trae título válido, lo prioriza sobre el fallback.
    if currentItem <> invalid and currentItem.title <> invalid and currentItem.title <> "" then resolvedTitle = currentItem.title
    ' Limpia cualquier valor inválido para no mostrar texto incorrecto en pantalla.
    if resolvedTitle = invalid then resolvedTitle = ""
    ' Aplica el título resuelto al label interno de NewsItem.
    m.newsTitle.text = resolvedTitle
end sub

' Actualiza el CTA de detalle/reproducción según redirectKey del item activo.
sub updateDetailActionCTA(currentItem as dynamic)
    ' Si no existen los nodos del CTA, no hay nada para actualizar.
    if m.detailActionGroup = invalid or m.detailActionLabel = invalid or m.detailActionIcon = invalid then return

    ' Obtiene redirectKey del item actual cuando existe.
    redirectKey = invalid
    if currentItem <> invalid and currentItem.redirectKey <> invalid then
        redirectKey = currentItem.redirectKey
    end if

    ' Si redirectKey es inválido, oculta el CTA y corta el flujo.
    if redirectKey = invalid then
        m.detailActionGroup.visible = false
        return
    end if

    ' Normaliza redirectKey para comparación sin sensibilidad a mayúsculas.
    redirectKeyValue = LCase(redirectKey.ToStr())

    ' Si redirectKey apunta a canal, muestra acción de reproducción.
    if redirectKeyValue = "channelid" then
        m.detailActionLabel.text = i18n_t(m.global.i18n, "content.contentPage.watchNow")
        m.detailActionIcon.uri = "pkg:/images/shared/play.png"
        m.detailActionGroup.visible = true
        return
    else
        m.detailActionLabel.text = i18n_t(m.global.i18n, "content.contentPage.seeDetail")
        m.detailActionIcon.uri = "pkg:/images/shared/more_info.png"
        m.detailActionGroup.visible = true
        return
    end if

    ' Para cualquier otro redirectKey, oculta el CTA.
    m.detailActionGroup.visible = false
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
            ' Al ir a la derecha, el actual sale a la izquierda y el siguiente entra desde la derecha.
            startSlideTransition(m.top.currentIndex + 1, 1)
        end if
        return true
    else if key = KeyButtons().LEFT then
        if m.top.currentIndex > 0 then
            ' Al ir a la izquierda, el actual sale a la derecha y el anterior entra desde la izquierda.
            startSlideTransition(m.top.currentIndex - 1, -1)
            return true
        end if

        ' En el primer elemento, no consume LEFT para permitir que MainScreen abra el menú.
        return false
    end if

    return false
end function

' Inicia una transición horizontal y actualiza el item activo.
sub startSlideTransition(newIndex as integer, direction as integer)
    ' Evita iniciar otra transición mientras una está en curso.
    if m.isSliding then return

    ' Obtiene el item que será mostrado al finalizar el slide.
    incomingItem = m.top.items[newIndex]
    ' Resuelve uri del item entrante.
    incomingImageUri = getItemImageUri(incomingItem)
    ' Si no hay imagen entrante, evita una animación inconsistente.
    if incomingImageUri = invalid then return

    ' Marca que la animación comenzó.
    m.isSliding = true
    ' Reinicia contador de frame.
    m.slideCurrentFrame = 0
    ' Guarda dirección solicitada del slide.
    m.slideDirection = direction
    ' Actualiza índice al arrancar el slide para sincronizar dots/título externos.
    m.top.currentIndex = __getTargetIndex()
    ' Obtiene el item actualizado para sincronizar inmediatamente el CTA durante el slide.
    currentItem = getCurrentItem()
    ' Refresca de inmediato el título visible para que cambie durante el slide.
    updateNewsTitle(currentItem)
    ' Refresca visibilidad/contenido del detailActionGroup con el nuevo item activo.
    updateDetailActionCTA(currentItem)
    ' Calcula ancho de referencia para desplazar un panel completo.
    slideWidth = m.backgroundImage.width

    ' Define dónde comienza el panel entrante según la dirección.
    if direction = 1 then
        ' Para RIGHT: item entrante inicia fuera de pantalla por la derecha.
        m.incomingStartX = slideWidth
        ' Para RIGHT: item saliente termina fuera de pantalla por la izquierda.
        m.outgoingEndX = -slideWidth
    else
        ' Para LEFT: item entrante inicia fuera de pantalla por la izquierda.
        m.incomingStartX = -slideWidth
        ' Para LEFT: item saliente termina fuera de pantalla por la derecha.
        m.outgoingEndX = slideWidth
    end if

    ' Carga imagen entrante en el poster secundario.
    if m.incomingBackgroundImage <> invalid then
        ' Asigna la uri del item entrante.
        m.incomingBackgroundImage.uri = incomingImageUri
        ' Posiciona el poster entrante fuera de pantalla para iniciar el slide.
        m.incomingBackgroundImage.translation = [m.incomingStartX, 0]
        ' Hace visible el poster entrante durante la animación.
        m.incomingBackgroundImage.visible = true
    end if

    ' Asegura que el poster saliente comience en el centro.
    m.backgroundImage.translation = [0, 0]

    ' Inicia timer de animación slide.
    if m.slideTimer <> invalid then
        m.slideTimer.control = "start"
    else
        finalizeSlideTransition()
    end if
end sub

' Avanza un frame de la animación horizontal.
sub onSlideFrame()
    ' Si no hay animación activa, ignora evento de timer.
    if not m.isSliding then return

    ' Incrementa el frame actual.
    m.slideCurrentFrame = m.slideCurrentFrame + 1

    ' Anima desplazamiento horizontal entre item saliente y entrante.
    __animateSlideFrame()

end sub

' Anima un frame de la fase de slide horizontal.
sub __animateSlideFrame()
    ' Calcula progreso normalizado de 0 a 1 del slide.
    progress = __getPhaseProgress(m.slideTotalFrames)
    ' Interpola posición X del item saliente hacia su destino final.
    outgoingX = int(m.outgoingEndX * progress)
    ' Interpola posición X del item entrante desde fuera de pantalla hasta 0.
    incomingX = int(m.incomingStartX * (1 - progress))

    ' Aplica desplazamiento al item saliente.
    m.backgroundImage.translation = [outgoingX, 0]
    ' Aplica desplazamiento al item entrante.
    if m.incomingBackgroundImage <> invalid then m.incomingBackgroundImage.translation = [incomingX, 0]

    ' Si llegó al último frame del slide, consolida imagen y finaliza transición.
    if m.slideCurrentFrame >= m.slideTotalFrames then
        ' Obtiene item ya seleccionado para consolidar la imagen final.
        currentItem = getCurrentItem()
        ' Resuelve uri final del item seleccionado.
        finalImageUri = getItemImageUri(currentItem)
        ' Si hay uri válida, la aplica al poster principal.
        if finalImageUri <> invalid then m.backgroundImage.uri = finalImageUri
        ' Restablece posición base del poster principal.
        m.backgroundImage.translation = [0, 0]
        ' Oculta poster entrante luego del cambio de item.
        if m.incomingBackgroundImage <> invalid then m.incomingBackgroundImage.visible = false
        ' Reinicia traslación del poster entrante.
        if m.incomingBackgroundImage <> invalid then m.incomingBackgroundImage.translation = [0, 0]
        ' Finaliza transición al completar el desplazamiento horizontal.
        finalizeSlideTransition()
    end if
end sub

' Cierra la transición y restablece posiciones base.
sub finalizeSlideTransition()
    ' Detiene timer para evitar nuevos ticks.
    if m.slideTimer <> invalid then m.slideTimer.control = "stop"

    ' Devuelve poster principal al origen.
    m.backgroundImage.translation = [0, 0]
    ' Oculta y resetea poster entrante tras finalizar animación.
    if m.incomingBackgroundImage <> invalid then
        ' Esconde el poster secundario al terminar.
        m.incomingBackgroundImage.visible = false
        ' Limpia su traslación para próximas animaciones.
        m.incomingBackgroundImage.translation = [0, 0]
    end if

    ' Restablece estado interno de animación.
    m.isSliding = false
    ' Restablece frame actual a cero.
    m.slideCurrentFrame = 0
end sub

' Devuelve progreso de una fase entre 0 y 1 con easing suave.
function __getPhaseProgress(totalFrames as integer) as float
    ' Si no hay frames configurados, considera progreso completado.
    if totalFrames <= 0 then return 1

    ' Calcula progreso lineal del frame actual.
    progress = m.slideCurrentFrame / totalFrames
    ' Asegura límite inferior de progreso.
    if progress < 0 then progress = 0
    ' Asegura límite superior de progreso.
    if progress > 1 then progress = 1

    ' Aplica curva ease-in-out para movimiento más fluido.
    return progress * progress * (3 - (2 * progress))
end function

' Obtiene índice objetivo en función de la dirección de slide.
function __getTargetIndex() as integer
    ' Obtiene índice actual al momento de confirmar cambio.
    currentIndex = m.top.currentIndex
    ' Si dirección es hacia la derecha visual (tecla RIGHT), avanza uno.
    if m.slideDirection = 1 then return currentIndex + 1
    ' Si dirección es hacia la izquierda visual (tecla LEFT), retrocede uno.
    return currentIndex - 1
end function

' Obtiene la uri de imagen renderizable para un item de News.
function getItemImageUri(item as dynamic) as dynamic
    ' Si el item es inválido, no hay uri para devolver.
    if item = invalid then return invalid
    ' Si el item trae imagen, transforma al formato final de CDN.
    if item.image <> invalid then return getImageUrl(item.image)
    ' Si no trae imagen, no hay uri para renderizar.
    return invalid
end function