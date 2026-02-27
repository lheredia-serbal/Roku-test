' Inicialización del componente SearchScreen.
sub init()
  ' Referencio el nodo del input de búsqueda principal.
  m.searchInput = m.top.findNode("searchInput")
  ' Referencio el nodo del teclado en pantalla.
  m.searchKeyboard = m.top.findNode("searchKeyboard")

  ' Referencio el timer para debounce de búsqueda.
  m.searchDebounceTimer = m.top.findNode("searchDebounceTimer")
  ' Referencio el contenedor del carrusel de programas de ErrorPage.
  m.relatedContainer = m.top.findNode("relatedContainer")
  ' Referencio el carrusel reutilizado desde la lógica de ProgramDetail.
  m.related = m.top.findNode("related")
  ' Referencio el indicador visual de selección del carrusel.
  m.selectedIndicator = m.top.findNode("selectedIndicator")

  ' Referencio el contenedor de múltiples carruseles para resultados de búsqueda.
  m.searchCarousels = m.top.findNode("searchCarousels")
  ' Referencio el contenedor donde se crearán dinámicamente los carruseles de búsqueda.
  m.carouselContainer = m.top.findNode("carouselContainer")
  ' Referencio indicador de selección de la sección de carruseles de búsqueda.
  m.searchSelectedIndicator = m.top.findNode("searchSelectedIndicator")

  ' Referencio el label de estado sin resultados de búsqueda.
  m.noResultsLabel = m.top.findNode("noResultsLabel")

  ' Referencio la animación que muestra el teclado.
  m.keyboardShowAnimation = m.top.findNode("keyboardShowAnimation")
  ' Referencio la animación que oculta el teclado.
  m.keyboardHideAnimation = m.top.findNode("keyboardHideAnimation")
  ' Referencio el interpolador de traducción para mostrar teclado.
  m.keyboardShowTranslationInterpolator = m.top.findNode("keyboardShowTranslationInterpolator")
  ' Referencio el interpolador de traducción para ocultar teclado.
  m.keyboardHideTranslationInterpolator = m.top.findNode("keyboardHideTranslationInterpolator")

  ' Obtengo la información de escala global de la app.
  m.scaleInfo = m.global.scaleInfo

  ' Seteo el ancho del input para ocupar todo el ancho de pantalla.
  m.searchInput.width = m.scaleInfo.width - 150
  ' Seteo la posición del input en la esquina superior izquierda.
  m.searchInput.translation = scaleSize([50, 50], m.scaleInfo)
  ' Defino el largo máximo de texto permitido en el input.
  m.searchInput.maxTextLength = 255
  ' Defino el color del texto de ayuda del input.
  m.searchInput.hintTextColor = m.global.colors.LIGHT_GRAY

  ' Configuro label de no resultados centrado y debajo del input.
  if m.noResultsLabel <> invalid then
    m.noResultsLabel.width = m.scaleInfo.width
    m.noResultsLabel.translation = scaleSize([0, 150], m.scaleInfo)
    m.noResultsLabel.color = m.global.colors.WHITE
    m.noResultsLabel.visible = false
  end if

  ' Defino un ancho por defecto para el teclado si no hay medidas reales aún.
  m.keyboardDefaultWidth = scaleValue(1120, m.scaleInfo)
  ' Defino una altura por defecto para el teclado si no hay medidas reales aún.
  m.keyboardDefaultHeight = scaleValue(320, m.scaleInfo)

   m.relatedContainer.translation = scaleSize([0, 30], m.scaleInfo)

  ' Posiciono inicialmente el teclado fuera de pantalla (debajo).
  m.searchKeyboard.translation = [0, m.scaleInfo.height]
  ' Inicio el teclado totalmente transparente.
  m.searchKeyboard.opacity = 0.0
  ' Inicio el teclado invisible.
  m.searchKeyboard.visible = false
  ' Evito que el teclado dibuje su propio TextEditBox interno.
  m.searchKeyboard.showTextEditBox = false

  ' Observo cambios de foco del input para mostrar/ocultar teclado.
  m.searchInput.observeField("hasFocus", "onSearchInputFocusChanged")
  ' Observo cambios del TextEditBox interno del teclado para sincronizar texto.
  m.searchKeyboard.observeField("textEditBox", "onKeyboardTextChanged")
  ' Observo el estado de animación de ocultar teclado para limpiar estado final.
  m.keyboardHideAnimation.observeField("state", "onKeyboardHideAnimationStateChanged")

  ' Observo cuando vence el debounce para disparar el servicio de búsqueda.
  if m.searchDebounceTimer <> invalid then m.searchDebounceTimer.observeField("fire", "onSearchDebounceTimerFire")

  ' Indico que la primera vez que el input tome foco no debe abrir teclado automáticamente.
  m.skipKeyboardOnFirstFocus = true

  ' Inicializo bandera para evitar recargar ErrorPage múltiples veces innecesariamente.
  m.hasLoadedErrorPage = false

  ' Si existe el nodo global, observo cambio de API activa para reiniciar caché.
  if m.global <> invalid then
    ' Reacciono a cambios de host API para volver a consultar ErrorPage.
    m.global.observeField("activeApiUrl", "onActiveApiUrlChanged")
  end if

  ' Configuro posiciones del carrusel para que quede debajo del input de búsqueda.
  __configSearchScreen()
end sub

' Inicializa foco cuando la pantalla se vuelve activa.
sub initFocus()
  ' Si la pantalla recibió foco.
  if m.top.onFocus then
    ' Aplico textos traducidos del input.
    __applyTranslations()
    ' Aseguro foco en el nodo top para cadena de foco correcta.
    m.top.setFocus(true)
    ' Enfoco el input para disparar la lógica de teclado.
    m.searchInput.setFocus(true)
    ' Disparo la carga del endpoint ErrorPage al entrar en la pantalla.
    __getErrorPage()
  else
    ' Si pierde foco, detengo debounce pendiente para evitar búsquedas fuera de pantalla.
    if m.searchDebounceTimer <> invalid then m.searchDebounceTimer.control = "stop"
    ' Si pierde foco, oculto teclado sin animación.
    __hideKeyboard(false)
  end if
end sub

' Muestra/oculta teclado cuando cambia el foco del input.
sub onSearchInputFocusChanged()
  ' Si el input no existe, no hago nada.
  if m.searchInput = invalid then return

 ' Si el input tiene foco, muestro teclado (excepto en el primer ingreso).
  if m.searchInput.hasFocus() then
    ' En el primer foco inicial solo dejo foco en input sin desplegar teclado.
    if m.skipKeyboardOnFirstFocus then
      ' Consumo esta excepción para que aplique solo una vez por ciclo de vida del componente.
      m.skipKeyboardOnFirstFocus = false
      ' Salgo sin mostrar teclado en el primer ingreso.
      return
    end if
    ' Muestro teclado animado.
    __showKeyboard()
  else
    ' Si el input pierde foco, oculto teclado animado.
    __hideKeyboard(true)
  end if
end sub

' Vincula observers directos al TextEditBox interno del teclado para detectar tipeo.
sub __observeKeyboardTextEditBox()
  ' Si falta teclado o textEditBox interno, no puedo observar cambios.
  if m.searchKeyboard = invalid or m.searchKeyboard.textEditBox = invalid then return

  ' Evito observers duplicados antes de volver a observar.
  m.searchKeyboard.textEditBox.unobserveField("text")
  m.searchKeyboard.textEditBox.observeField("text", "onKeyboardTextChanged")

  m.searchKeyboard.textEditBox.unobserveField("cursorPosition")
  m.searchKeyboard.textEditBox.observeField("cursorPosition", "onKeyboardTextChanged")
end sub

' Sincroniza el texto y cursor del teclado con el input visible.
sub onKeyboardTextChanged()
  ' Si falta teclado o input, salgo.
  if m.searchKeyboard = invalid or m.searchInput = invalid then return

  ' Copio la posición de cursor desde el TextEditBox interno del teclado.
  m.searchInput.cursorPosition = m.searchKeyboard.textEditBox.cursorPosition
  ' Copio el texto desde el TextEditBox interno del teclado.
  m.searchInput.text = m.searchKeyboard.textEditBox.text
  ' Copio el estado activo del TextEditBox interno del teclado.
  m.searchInput.active = m.searchKeyboard.textEditBox.active

  ' Programo llamada al servicio cuando dejan de escribir por 3 segundos.
  __scheduleSearchRequest()
end sub

' Reinicia el debounce de búsqueda para disparar consulta al dejar de tipear.
sub __scheduleSearchRequest()
    ' Si la pantalla no está activa, no programo búsquedas.
  if not m.top.onFocus then return
  ' Si no existe el timer, no se puede debouncear.
  if m.searchDebounceTimer = invalid then return

  ' Reinicio el timer en cada tecla para contar 3 segundos desde la última edición.
  m.searchDebounceTimer.control = "stop"
  m.searchDebounceTimer.control = "start"
end sub

' Se ejecuta cuando pasan 3 segundos sin cambios en el input.
sub onSearchDebounceTimerFire()
    ' Solo proceso debounce si la pantalla Search está activa/en foco.
  if not m.top.onFocus then return
  ' Si no hay input disponible, no realizo consulta.
  if m.searchInput = invalid then return

  ' Tomo y limpio el texto para evitar consultas con espacios.
  query = m.searchInput.text.trim()
  ' Si no hay término de búsqueda, recargo carrusel de ErrorPage.
  if query = "" then
    m.hasLoadedErrorPage = false
    __getErrorPage()
    return
  end if

  ' Disparo request al endpoint de búsqueda.
  __getSearchPrograms(query)
end sub

' Ejecuta la consulta de programas para el texto ingresado.
sub __getSearchPrograms(query as String)
  ' Si no hay API URL cacheada, la obtengo de la configuración global.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)

  ' Genero requestId para trazabilidad/retry.
  requestId = createRequestId()
  ' Construyo la acción HTTP de búsqueda.
  action = {
    ' Reutilizo request manager del componente.
    apiRequestManager: m.apiRequestManager
    ' URL del endpoint Search.
    url: urlSearch(m.apiUrl)
    ' Método HTTP de consulta.
    method: "POST"
    ' Callback al resolver la respuesta.
    responseMethod: "onGetSearchProgramsResponse"
    ' GET sin body.
    body: FormatJson({ "searchText": query.trim() })
    ' Token no explícito (flujo interno existente).
    token: invalid
    ' Se consume API privada de clientes.
    publicApi: false
    ' Sin datos auxiliares.
    dataAux: invalid
    ' Asocio el requestId de la acción.
    requestId: requestId
    ' Función ejecutora del envío HTTP.
    run: function() as Object
      ' Disparo request con helper estándar del proyecto.
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      ' Retorno resultado esperado por runAction.
      return { success: true, error: invalid }
    end function
  }

  ' Registro acción para retry/failover centralizado.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  ' Persisto el manager actualizado luego del runAction.
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa la respuesta de búsqueda.
sub onGetSearchProgramsResponse()
  ' Si no hay manager disponible, no puedo procesar respuesta.
  if m.apiRequestManager = invalid then return

  ' Si el status HTTP es válido, proceso resultado de búsqueda.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    removePendingAction(m.apiRequestManager.requestId)
    resp = ParseJson(m.apiRequestManager.response)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)

    if resp <> invalid and resp.data <> invalid and resp.data.carousels <> invalid and resp.data.carousels.count() > 0 then
      ' Pinto carruseles dinámicos de resultados de búsqueda.
      __loadSearchCarousels(resp.data.carousels)
      ' Oculto mensaje de no resultados porque hay contenido para mostrar.
      __loadRelatedCarousel(invalid)
      __showSearchNoResults(false)
    else
      ' Limpio carruseles de búsqueda cuando no hay resultados.
      __loadSearchCarousels(invalid)
      __loadRelatedCarousel(invalid)
      ' Muestro feedback de no resultados al usuario.
      __showSearchNoResults(true)
    end if
  else
    ' Obtengo status para flujo de error/reintento.
    statusCode = m.apiRequestManager.statusCode

    ' Si es error de servidor, sigo la misma estrategia de retry global.
    if m.apiRequestManager.serverError then
      setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      removePendingAction(m.apiRequestManager.requestId)
      if validateLogout(statusCode, m.top) then return
    end if

    ' Limpio manager tras error.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  end if
end sub

' Maneja eventos de control remoto para navegación/foco.
function onKeyEvent(key as String, press as Boolean) as Boolean

  ' Si presionan BACK con teclado visible, cierro teclado y retorno foco al input.
  if key = KeyButtons().BACK and m.searchKeyboard <> invalid and m.searchKeyboard.visible and press then
    ' Oculto teclado con animación.
    __hideKeyboard(true)
    ' Retorno foco al input.
    m.searchInput.setFocus(true)
    ' Al volver al input, aseguro que el carrusel de ErrorPage esté cargado.
    __getErrorPage()
    ' Indico que el evento fue manejado.
    return true
  end if

  ' Si el usuario baja desde el input, intento enviar foco a resultados visibles.
  if key = KeyButtons().DOWN and press and m.searchInput <> invalid and m.searchInput.isInFocusChain() then
    ' Prioridad 1: carruseles de búsqueda (cuando hay resultados de search).
    if m.searchCarousels <> invalid and m.searchCarousels.visible and m.carouselContainer <> invalid and m.carouselContainer.getChildCount() > 0 then
      firstCarousel = m.carouselContainer.getChild(0)
      firstList = firstCarousel.findNode("carouselList")
      if firstList <> invalid then
        firstList.setFocus(true)
        m.searchSelectedIndicator.size = firstCarousel.size
        m.searchSelectedIndicator.visible = true
        return true
      end if
    else if m.relatedContainer <> invalid and m.relatedContainer.visible and m.related <> invalid then
      ' Prioridad 2: bloque recomendado (fallback cuando no hay carousels de search).
      m.related.findNode("carouselList").setFocus(true)
      m.selectedIndicator.size = m.related.size
      m.selectedIndicator.visible = true
      return true
    end if
  end if

  ' Navegación hacia arriba: entre carruseles o regreso al input según contexto.
  if key = KeyButtons().UP and press then
    if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
      if m.carouselContainer.focusedChild.focusUp <> invalid then
        focusItem = m.carouselContainer.focusedChild.focusUp.findNode("carouselList")
        if focusItem <> invalid then
          m.carouselContainer.focusedChild.focusUp.opacity = "1.0"
          focusItem.setFocus(true)
          m.carouselContainer.translation = [m.carouselXPosition, -(m.carouselContainer.focusedChild.translation[1] - m.carouselYPosition)]
          m.searchSelectedIndicator.size = m.carouselContainer.focusedChild.size
        end if
      else
        m.searchInput.setFocus(true)
        m.searchSelectedIndicator.visible = false
      end if
      return true
    else if m.related <> invalid and m.related.isInFocusChain() then
      m.searchInput.setFocus(true)
      m.selectedIndicator.visible = false
      return true
    end if
  end if

  ' Navegación hacia abajo entre carruseles de búsqueda enlazados con focusDown.
  if key = KeyButtons().DOWN and press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    if m.carouselContainer.focusedChild.focusDown <> invalid then
      focusItem = m.carouselContainer.focusedChild.focusDown.findNode("carouselList")
      if focusItem <> invalid then
        m.carouselContainer.focusedChild.opacity = "0.0"
        focusItem.setFocus(true)
        m.carouselContainer.translation = [m.carouselXPosition, -(m.carouselContainer.focusedChild.translation[1] - m.carouselYPosition)]
        m.searchSelectedIndicator.size = m.carouselContainer.focusedChild.size
      end if
    end if
    return true
  end if

  if m.searchInput <> invalid and m.searchInput.isInFocusChain() and key = KeyButtons().OK and press then
    __showKeyboard()
    return true
  end if

  if key = KeyButtons().DOWN and m.related <> invalid and m.related.isInFocusChain() then
    return true
  end if

  return false
end function

' Calcula posición final del teclado centrado y pegado al borde inferior.
sub __updateKeyboardTranslations()
  ' Inicio ancho con valor por defecto.
  keyboardWidth = m.keyboardDefaultWidth
  ' Inicio alto con valor por defecto.
  keyboardHeight = m.keyboardDefaultHeight

  ' Leo bounds reales del teclado para posicionamiento preciso.
  keyboardBounds = m.searchKeyboard.boundingRect()
  ' Si hay bounds válidos.
  if keyboardBounds <> invalid then
    ' Si width de bounds es válido y positivo, uso ese ancho real.
    if keyboardBounds.width <> invalid and keyboardBounds.width > 0 then keyboardWidth = keyboardBounds.width
    ' Si height de bounds es válido y positivo, uso ese alto real.
    if keyboardBounds.height <> invalid and keyboardBounds.height > 0 then keyboardHeight = keyboardBounds.height
  end if

  ' Calculo coordenada X para centrar teclado horizontalmente.
  keyboardX = int((m.scaleInfo.width - keyboardWidth) / 2)
  ' Evito X negativa.
  if keyboardX < 0 then keyboardX = 0

  ' Calculo coordenada Y para pegar teclado al borde inferior.
  keyboardY = m.scaleInfo.height - keyboardHeight
  ' Evito Y negativa.
  if keyboardY < 0 then keyboardY = 0

  ' Defino posición visible final del teclado.
  m.keyboardVisibleTranslation = [keyboardX, keyboardY]
  ' Defino posición oculta del teclado fuera de pantalla hacia abajo.
  m.keyboardHiddenTranslation = [keyboardX, m.scaleInfo.height]

  ' Aplico estas posiciones a los keyframes de animación.
  __configureKeyboardAnimations()
end sub

' Configura los keyframes de animación del teclado.
sub __configureKeyboardAnimations()
  ' Si existe interpolador de mostrar.
  if m.keyboardShowTranslationInterpolator <> invalid then
    ' Seteo keyframes para subir teclado desde oculto hasta visible.
    m.keyboardShowTranslationInterpolator.keyValue = [m.keyboardHiddenTranslation, m.keyboardVisibleTranslation]
  end if

  ' Si existe interpolador de ocultar.
  if m.keyboardHideTranslationInterpolator <> invalid then
    ' Seteo keyframes para bajar teclado desde visible hasta oculto.
    m.keyboardHideTranslationInterpolator.keyValue = [m.keyboardVisibleTranslation, m.keyboardHiddenTranslation]
  end if
end sub

' Muestra el teclado con animación ascendente.
sub __showKeyboard()
  ' Si teclado no existe, salgo.
  if m.searchKeyboard = invalid then return

  ' Detengo animación de ocultado por seguridad.
  m.keyboardHideAnimation.control = "stop"
  ' Hago visible el teclado antes de animar.
  m.searchKeyboard.visible = true
  ' Recalculo posiciones por si cambió tamaño real del teclado.
  __updateKeyboardTranslations()

  ' Ubico teclado en posición oculta inicial para animar entrada.
  m.searchKeyboard.translation = m.keyboardHiddenTranslation

' Refuerzo observers del TextEditBox al abrir teclado.
  __observeKeyboardTextEditBox()
  ' Inicio teclado transparente para fade in.
  m.searchKeyboard.opacity = 0.0

  ' Sincronizo texto actual del input al teclado.
  m.searchKeyboard.textEditBox.text = m.searchInput.text
  ' Sincronizo cursor actual del input al teclado.
  m.searchKeyboard.textEditBox.cursorPosition = m.searchInput.cursorPosition

  ' Inicio animación de mostrar.
  m.keyboardShowAnimation.control = "start"
  ' Paso foco al teclado para escribir inmediatamente.
  m.searchKeyboard.setFocus(true)
end sub

' Oculta el teclado con animación descendente.
sub __hideKeyboard(withAnimation as Boolean)
  ' Si teclado no existe, salgo.
  if m.searchKeyboard = invalid then return

  ' Detengo animación de mostrar por seguridad.
  m.keyboardShowAnimation.control = "stop"

  ' Si hay que ocultar animado.
  if withAnimation then
    ' Solo arranco animación si teclado está visible.
    if m.searchKeyboard.visible then
      ' Inicio animación de ocultar.
      m.keyboardHideAnimation.control = "start"
    end if
  else
    ' Si no hay animación, detengo ocultado.
    m.keyboardHideAnimation.control = "stop"
    ' Marco teclado invisible.
    m.searchKeyboard.visible = false
    ' Reubico teclado debajo de pantalla.
    m.searchKeyboard.translation = [0, m.scaleInfo.height]
    ' Dejo teclado transparente.
    m.searchKeyboard.opacity = 0.0
  end if
end sub

' Al finalizar la animación de ocultar, deja el teclado invisible.
sub onKeyboardHideAnimationStateChanged()
  ' Si faltan nodos necesarios, salgo.
  if m.keyboardHideAnimation = invalid or m.searchKeyboard = invalid then return

  ' Cuando la animación termina.
  if m.keyboardHideAnimation.state = "stopped" then
    ' Oculto teclado definitivamente.
    m.searchKeyboard.visible = false
    ' Lo dejo fuera de pantalla abajo.
    m.searchKeyboard.translation = [0, m.scaleInfo.height]
    ' Lo dejo transparente.
    m.searchKeyboard.opacity = 0.0
  end if
end sub

' Aplica traducciones del placeholder del input.
sub __applyTranslations()
  ' Si no hay diccionario i18n, salgo.
  if m.global.i18n = invalid then return

  ' Aplico hint text usando la clave solicitada por negocio.
  m.searchInput.hintText = i18n_t(m.global.i18n, "search.noResultsDefaultSearch")

    ' Aplico traducción del mensaje cuando la búsqueda no devuelve resultados.
  if m.noResultsLabel <> invalid then m.noResultsLabel.text = i18n_t(m.global.i18n, "search.noResultsRecomendations")
end sub

' Muestra u oculta el mensaje de búsqueda sin resultados.
sub __showSearchNoResults(show as Boolean)
  if m.noResultsLabel = invalid then return
  m.noResultsLabel.visible = show
end sub

sub onActiveApiUrlChanged()
  ' Limpio API actual para que se recalcule desde configuración cuando cambie el dominio.
  m.apiUrl = invalid
  ' Reinicio bandera de carga para permitir nueva consulta con la nueva API.
  m.hasLoadedErrorPage = false
  ' Si la pantalla está activa, disparo nuevamente la carga de ErrorPage.
  if m.top.onFocus then __getErrorPage()
end sub

sub onGetErrorPageResponse()
  ' Si no hay manager disponible, no puedo procesar respuesta.
  if m.apiRequestManager = invalid then
    ' Salgo sin hacer cambios.
    return
  else
    ' Si el status HTTP es válido, proceso respuesta normal.
    if validateStatusCode(m.apiRequestManager.statusCode) then
      ' Quito la acción de la cola de pendientes.
      removePendingAction(m.apiRequestManager.requestId)
      ' Parseo el payload JSON recibido.
      resp = ParseJson(m.apiRequestManager.response)
      ' Limpio el request manager para próximas operaciones.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Marco que la carga de ErrorPage ya se realizó.
      m.hasLoadedErrorPage = true

      ' Al refrescar carrusel base, oculto mensaje de no resultados de búsqueda.
      __showSearchNoResults(false)

      ' Si la API devuelve data, cargo el carrusel.
      if resp.data <> invalid then
        ' Pinto items en el carrusel de relacionados.
        __loadRelatedCarousel(resp.data)
      else
        ' Si no hay data, oculto limpiamente el carrusel.
        __loadRelatedCarousel(invalid)
      end if
    else
      ' Obtengo status para flujo de error/reintento.
      statusCode = m.apiRequestManager.statusCode
      ' Obtengo cuerpo de error para logging.
      errorResponse = m.apiRequestManager.errorResponse

      ' Si es error de servidor, sigo la misma estrategia de retry global.
      if m.apiRequestManager.serverError then
        ' Guardo código CDN según status para telemetría/failover.
        setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
        ' Marco la acción como error para reintentos centralizados.
        changeStatusAction(m.apiRequestManager.requestId, "error")
        ' Disparo reintentos pendientes.
        retryAll()
      else
        ' Remuevo la acción pendiente si no es serverError.
        removePendingAction(m.apiRequestManager.requestId)

        ' Si el status implica logout, corto el flujo aquí.
        if validateLogout(statusCode, m.top) then return

        ' Registro error para diagnóstico.
        printError("ErrorPage:", errorResponse)
      end if

      ' Limpio manager tras error.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Ante error, oculto carrusel para no mostrar estado inconsistente.
      __loadRelatedCarousel(invalid)
    end if
  end if
end sub

sub onSelectItem()
  ' Si hay foco en carrusel, limpio valor de selected luego de la selección.
  if m.related <> invalid and m.related.isInFocusChain() then
    ' Evito retriggers dejando selected en invalid.
    m.related.selected = invalid
  end if
end sub

sub __getErrorPage()
  ' Evito pedir nuevamente el endpoint si ya fue cargado en la sesión de pantalla.
  if m.hasLoadedErrorPage then return

  ' Si no hay API URL cacheada, la obtengo de la configuración global.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)

    ' Oculto mensaje previo de no resultados mientras se procesa una nueva búsqueda.
  __showSearchNoResults(false)

  ' Genero requestId para trazabilidad/retry.
  requestId = createRequestId()
  ' Construyo la acción HTTP con el mismo patrón de ProgramDetail.
  action = {
    ' Reutilizo request manager del componente.
    apiRequestManager: m.apiRequestManager
    ' URL del endpoint ErrorPage.
    url: urlErrorPage(m.apiUrl)
    ' Método HTTP de consulta.
    method: "GET"
    ' Callback al resolver la respuesta.
    responseMethod: "onGetErrorPageResponse"
    ' GET sin body.
    body: invalid
    ' Token no explícito (flujo interno existente).
    token: invalid
    ' Se consume API privada de clientes.
    publicApi: false
    ' Sin datos auxiliares.
    dataAux: invalid
    ' Asocio el requestId de la acción.
    requestId: requestId
    ' Función ejecutora del envío HTTP.
    run: function() as Object
      ' Disparo request con helper estándar del proyecto.
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      ' Retorno resultado esperado por runAction.
      return { success: true, error: invalid }
    end function
  }

  ' Registro acción para retry/failover centralizado.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  ' Persisto el manager actualizado luego del runAction.
  m.apiRequestManager = action.apiRequestManager
end sub

' Crea y muestra carruseles de búsqueda usando la misma estrategia base de MainScreen.
sub __loadSearchCarousels(carousels)
  ' Si falta estructura visual, no hay nada que renderizar.
  if m.carouselContainer = invalid or m.searchCarousels = invalid then return

  ' Limpio carruseles previos para evitar duplicados tras nuevas búsquedas.
  if m.carouselContainer.getChildCount() > 0 then m.carouselContainer.removeChildrenIndex(m.carouselContainer.getChildCount(), 0)
  ' Posición base del contenedor para el cálculo de desplazamiento vertical al navegar.
  m.carouselContainer.translation = [scaleValue(55, m.scaleInfo), scaleValue(20, m.scaleInfo)]
  m.carouselXPosition = m.carouselContainer.translation[0]
  m.carouselYPosition = m.carouselContainer.translation[1]

  ' Variables auxiliares para posicionamiento y encadenamiento vertical de foco.
  yPosition = 0
  previousCarousel = invalid

  if carousels <> invalid and carousels.count() > 0 then
    for each carouselData in carousels
      ' Reutilizo solo carruseles válidos y omito NEWS (como en MainScreen).
      if carouselData <> invalid and carouselData.items <> invalid and carouselData.items.count() > 0 and carouselData.style <> getCarouselStyles().NEWS then
        ' Creo instancia de Carousel y copio metadata necesaria para render.
        newCarousel = m.carouselContainer.createChild("Carousel")
        newCarousel.id = carouselData.id
        newCarousel.contentType = carouselData.contentType
        newCarousel.style = carouselData.style
        newCarousel.title = carouselData.title
        newCarousel.code = carouselData.code
        newCarousel.imageType = carouselData.imageType
        newCarousel.redirectType = carouselData.redirectType
        newCarousel.items = carouselData.items

        ' Ubico verticalmente este carrusel dentro del stack.
        newCarousel.translation = [0, yPosition]
        ' Observo selección para limpiar estado selected y evitar retriggers.
        newCarousel.ObserveField("selected", "onSearchCarouselSelectItem")

        ' Enlazo foco vertical entre carruseles (arriba/abajo).
        if previousCarousel <> invalid then
          previousCarousel.focusDown = newCarousel
          newCarousel.focusUp = previousCarousel
        end if
        previousCarousel = newCarousel

        ' Avanzo Y según altura real del carrusel + separación visual.
        yPosition = yPosition + newCarousel.height + scaleValue(20, m.scaleInfo)
      end if
    end for
  end if

  ' Determino si finalmente hay carruseles visibles para alternar bloques UI.
  hasSearchCarousels = m.carouselContainer.getChildCount() > 0
  m.searchCarousels.visible = hasSearchCarousels

  if hasSearchCarousels then
    ' Si hay carruseles de búsqueda, oculto recomendados y su indicador.
    m.relatedContainer.visible = false
    m.selectedIndicator.visible = false
    firstCarousel = m.carouselContainer.getChild(0)
    m.searchSelectedIndicator.size = firstCarousel.size
    m.searchSelectedIndicator.visible = false
  else
    ' Si no hay carruseles, dejo indicador oculto.
    m.searchSelectedIndicator.visible = false
  end if
end sub

' Limpia selected del carrusel enfocado para evitar reaperturas por notificaciones repetidas.
sub onSearchCarouselSelectItem()
  if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    m.carouselContainer.focusedChild.selected = invalid
  end if
end sub

sub __loadRelatedCarousel(carouselData)
  ' Si hay items válidos, configuro y muestro el carrusel.
  if carouselData <> invalid and carouselData.items <> invalid and carouselData.items.count() > 0 then
    ' Seteo id lógico del carrusel.
    m.related.id = carouselData.id
    ' Seteo estilo visual del carrusel.
    m.related.style = carouselData.style
    ' Seteo título del carrusel.
    m.related.title = carouselData.title
    ' Seteo código de negocio asociado.
    m.related.code = carouselData.code
    ' Seteo tipo de contenido para renderizado.
    m.related.contentType = carouselData.contentType
    ' Seteo tipo de imagen para las tarjetas.
    m.related.imageType = carouselData.imageType
    ' Seteo tipo de redirección de las tarjetas.
    m.related.redirectType = carouselData.redirectType
    ' Inyecto items recibidos desde API.
    m.related.items = carouselData.items

    ' Observo selección de item para limpiar selected tras click.
    m.related.ObserveField("selected", "onSelectItem")
    ' Muestro el contenedor una vez cargado.
    m.relatedContainer.visible = true
  else
    ' Si no hay datos, oculto el contenedor del carrusel.
    m.relatedContainer.visible = false
    ' Oculto indicador de selección asociado.
    m.selectedIndicator.visible = false
    ' Limpio items previamente cargados.
    m.related.items = invalid
    ' Quito observer de selección para evitar callbacks innecesarios.
    m.related.unobserveField("selected")
  end if
end sub

sub __configSearchScreen()
  ' Posiciono el carrusel en origen relativo del contenedor.
  m.related.translation = scaleSize([0, 0], m.scaleInfo)
  ' Alineo indicador de selección con la geometría del carrusel.
  m.selectedIndicator.translation = scaleSize([68, 130], m.scaleInfo)
end sub