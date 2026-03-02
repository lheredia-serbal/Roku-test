' Inicialización del componente SearchScreen.
sub init()
  ' Referencio el nodo del input de búsqueda principal.
  m.searchInput = m.top.findNode("searchInput")
  ' Referencio el nodo del teclado en pantalla.
  m.searchKeyboard = m.top.findNode("searchKeyboard")

  ' Referencio el fondo opaco que acompaña al teclado.
  m.searchKeyboardBackground = m.top.findNode("searchKeyboardBackground")
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

  ' Referencio interpoladores de traducción del fondo del teclado.
  m.keyboardBackgroundShowTranslationInterpolator = m.top.findNode("keyboardBackgroundShowTranslationInterpolator")
  m.keyboardBackgroundHideTranslationInterpolator = m.top.findNode("keyboardBackgroundHideTranslationInterpolator")

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

   m.relatedContainer.translation = scaleSize([0, 25], m.scaleInfo)

  ' Posiciono inicialmente el teclado fuera de pantalla (debajo).
  m.searchKeyboard.translation = [0, m.scaleInfo.height]
  ' Inicio el teclado totalmente transparente.
  m.searchKeyboard.opacity = 0.0
  ' Inicio el teclado invisible.
  m.searchKeyboard.visible = false
  ' Evito que el teclado dibuje su propio TextEditBox interno.
  m.searchKeyboard.showTextEditBox = false

' Configuro fondo opaco para que el teclado no se vea transparente sobre carruseles.
  if m.searchKeyboardBackground <> invalid then
    m.searchKeyboardBackground.width = m.scaleInfo.width
    m.searchKeyboardBackground.height = m.keyboardDefaultHeight
    m.searchKeyboardBackground.translation = [0, m.scaleInfo.height]
    m.searchKeyboardBackground.opacity = 0.0
  end if

  ' Observo cambios de foco del input para mostrar/ocultar teclado.
  m.searchInput.observeField("hasFocus", "onSearchInputFocusChanged")
  ' Observo el estado de animación de ocultar teclado para limpiar estado final.
  m.keyboardHideAnimation.observeField("state", "onKeyboardHideAnimationStateChanged")

  ' Observo cuando vence el debounce para disparar el servicio de búsqueda.
  if m.searchDebounceTimer <> invalid then m.searchDebounceTimer.observeField("fire", "onSearchDebounceTimerFire")

  ' Indico que la primera vez que el input tome foco no debe abrir teclado automáticamente.
  m.skipKeyboardOnFirstFocus = true

  ' Inicializo bandera para evitar recargar ErrorPage múltiples veces innecesariamente.
  m.hasLoadedErrorPage = false
  ' Cacheo URL base de API para flujos de detalle/streaming.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Mantengo referencia al último carrusel enfocado para restaurar UX tras errores.
  m.lastFocusedNode = invalid
  ' Cacheo URL base de API para flujos de detalle/streaming.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Mantengo referencia al último carrusel enfocado para restaurar UX tras errores.
  m.lastFocusedNode = invalid
  ' Cacheo URL base de API para flujos de detalle/streaming.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Mantengo referencia al último carrusel enfocado para restaurar UX tras errores.
  m.lastFocusedNode = invalid
  ' Mantengo una copia del texto de búsqueda para evitar que se limpie al perder foco.
  m.currentSearchText = m.searchInput.text

  ' Si existe el nodo global, observo cambio de API activa para reiniciar caché.
  if m.global <> invalid then
    ' Reacciono a cambios de host API para volver a consultar ErrorPage.
    m.global.observeField("activeApiUrl", "onActiveApiUrlChanged")
  end if

  ' Configuro posiciones del carrusel para que quede debajo del input de búsqueda.
  __configSearchScreen()
end sub

' Limpia input y variables de estado de búsqueda al entrar a SearchScreen.
sub __resetSearchState()
  ' Detengo debounce previo para evitar requests rezagados.
  if m.searchDebounceTimer <> invalid then m.searchDebounceTimer.control = "stop"

  ' Limpio texto y cursor del input principal.
  if m.searchInput <> invalid then
    m.searchInput.text = ""
    m.searchInput.cursorPosition = 0
  end if

  ' Limpio texto/cursor del teclado interno si ya está creado.
  if m.searchKeyboard <> invalid and m.searchKeyboard.textEditBox <> invalid then
    m.searchKeyboard.textEditBox.text = ""
    m.searchKeyboard.textEditBox.cursorPosition = 0
  end if

  ' Reinicio variable persistida de texto de búsqueda.
  m.currentSearchText = ""
  ' Permito recargar ErrorPage en cada ingreso al componente.
  m.hasLoadedErrorPage = false

  ' Limpio estado visual de resultados e indicadores.
  __showSearchNoResults(false)
  __loadRelatedCarousel(invalid)
  __loadSearchCarousels(invalid)
  if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
  if m.searchSelectedIndicator <> invalid then m.searchSelectedIndicator.visible = false

  ' Limpio referencias auxiliares de selección/foco previas.
  m.itemSelected = invalid
  m.carouselIndex = invalid
  m.lastFocusedNode = invalid

  ' Reinicio flags de navegación para que la entrada siempre parta limpia.
  m.top.returnFromProgramDetail = false
  m.top.enterFromMainScreen = false
end sub

' Inicializa foco cuando la pantalla se vuelve activa.
sub initFocus()
  ' Si la pantalla recibió foco.
  if m.top.onFocus then
    ' Aplico textos traducidos del input.
    __applyTranslations()
    ' Aseguro foco en el nodo top para cadena de foco correcta.
    m.top.setFocus(true)

    ' Al entrar a Search, limpio input y estado para iniciar siempre desde cero.
    __resetSearchState()
    ' Enfoco el input para iniciar una nueva búsqueda.
    m.searchInput.setFocus(true)

    ' Si Search se abrió desde MainScreen, fuerzo foco en input y refresh de ErrorPage.
    if m.top.enterFromMainScreen then
      m.top.enterFromMainScreen = false
      m.top.returnFromProgramDetail = false
      m.hasLoadedErrorPage = false
      m.searchInput.setFocus(true)
      __loadRelatedCarousel(invalid)
      __loadSearchCarousels(invalid)
      __getErrorPage()
      return
    end if

    ' Si vuelvo desde ProgramDetail, intento restaurar foco en el último item.
    if m.top.returnFromProgramDetail then
      m.top.returnFromProgramDetail = false
      __restoreFocusFromProgramDetail()
    else
      ' Enfoco el input para disparar la lógica de teclado.
      m.searchInput.setFocus(true)
    end if

    ' Disparo la carga del endpoint ErrorPage al entrar en la pantalla.
    __loadRelatedCarousel(invalid)
      __loadSearchCarousels(invalid)
    __getErrorPage()
  else
    ' Si pierde foco, detengo debounce pendiente para evitar búsquedas fuera de pantalla.
    if m.searchDebounceTimer <> invalid then m.searchDebounceTimer.control = "stop"
    ' Si pierde foco, recompongo el texto persistido en el input.
    __restoreSearchInputText()
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
    ' Si el input pierde foco, restauro texto persistido y oculto teclado animado.
    __restoreSearchInputText()
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
end sub

' Sincroniza el texto y cursor del teclado con el input visible.
sub onKeyboardTextChanged()
  ' Si falta teclado o input, salgo.
  if m.searchKeyboard = invalid or m.searchInput = invalid then return
    ' Si aún no existe el TextEditBox interno, no hay nada para sincronizar.
  if m.searchKeyboard.textEditBox = invalid then return
  ' Solo sincronizo cambios cuando el foco está realmente dentro del teclado.
  if not m.searchKeyboard.isInFocusChain() then return


  ' Copio la posición de cursor desde el TextEditBox interno del teclado.
  m.searchInput.cursorPosition = m.searchKeyboard.textEditBox.cursorPosition
  ' Copio el texto desde el TextEditBox interno del teclado.
  print "Keyboard text " ; m.searchKeyboard.textEditBox.text
  m.currentSearchText = m.searchKeyboard.textEditBox.text
  m.searchInput.text = m.currentSearchText
  ' Copio el estado activo del TextEditBox interno del teclado.

  ' Fuerzo cursor al final del texto para que nuevos caracteres se agreguen al final.
  cursorAtEnd = m.currentSearchText.len()
  m.searchInput.cursorPosition = cursorAtEnd
  m.searchKeyboard.textEditBox.cursorPosition = cursorAtEnd
  m.searchInput.active = m.searchKeyboard.textEditBox.active

  ' Programo llamada al servicio cuando dejan de escribir por 2 segundos.
  __scheduleSearchRequest()
end sub

' Reinicia el debounce de búsqueda para disparar consulta al dejar de tipear.
sub __scheduleSearchRequest()
    ' Si la pantalla no está activa, no programo búsquedas.
  if not m.top.onFocus then return
  ' Si no existe el timer, no se puede debouncear.
  if m.searchDebounceTimer = invalid then return

  ' Reinicio el timer en cada tecla para contar 2 segundos desde la última edición.
  m.searchDebounceTimer.control = "stop"
  m.searchDebounceTimer.control = "start"
end sub

' Se ejecuta cuando pasan 2 segundos sin cambios en el input.
sub onSearchDebounceTimerFire()
    ' Solo proceso debounce si la pantalla Search está activa/en foco.
  if not m.top.onFocus then return
  ' Si no hay input disponible, no realizo consulta.
  if m.searchInput = invalid then return

  ' Tomo y limpio el texto para evitar consultas con espacios.
  query = m.currentSearchText.trim()
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
  if m.apiRequestManager = invalid then
    ' Si el manager no existe, cierro loading para evitar spinner colgado.
    if m.top.loading <> invalid then m.top.loading.visible = false
    return
  end if

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
      ' Sin resultados, regreso el foco al input para facilitar nueva búsqueda.
      if m.searchInput <> invalid then m.searchInput.setFocus(true)
      ' Oculto indicadores de selección al no existir listas navegables.
      if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
      if m.searchSelectedIndicator <> invalid then m.searchSelectedIndicator.visible = false
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

  ' Cierro loading al finalizar la consulta (éxito o error) de búsqueda.
  if m.top.loading <> invalid then m.top.loading.visible = false
end sub

' Maneja eventos de control remoto para navegación/foco.
function onKeyEvent(key as String, press as Boolean) as Boolean

  ' Si presionan BACK con teclado visible, cierro teclado y retorno foco al input.
  if key = KeyButtons().BACK and m.searchKeyboard <> invalid and m.searchKeyboard.visible and press then
    ' Oculto teclado con animación.
    __hideKeyboard(true)
    ' Retorno foco al input.
    m.searchInput.setFocus(true)
    ' Indico que el evento fue manejado.
    return true
  end if

  ' Si el usuario baja desde el input, intento enviar foco a resultados visibles.
  if key = KeyButtons().DOWN and m.searchInput <> invalid and m.searchInput.isInFocusChain() then

    __restoreSearchInputText()
    
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

  ' Defino posiciones del fondo opaco del teclado (siempre ancho completo).
  m.keyboardBackgroundVisibleTranslation = [0, keyboardY]
  m.keyboardBackgroundHiddenTranslation = [0, m.scaleInfo.height]

  ' Si existe fondo, ajusto su alto al alto real del teclado.
  if m.searchKeyboardBackground <> invalid then m.searchKeyboardBackground.height = keyboardHeight

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

    ' Si existe interpolador de mostrar del fondo del teclado.
  if m.keyboardBackgroundShowTranslationInterpolator <> invalid then
    m.keyboardBackgroundShowTranslationInterpolator.keyValue = [m.keyboardBackgroundHiddenTranslation, m.keyboardBackgroundVisibleTranslation]
  end if

  ' Si existe interpolador de ocultar del fondo del teclado.
  if m.keyboardBackgroundHideTranslationInterpolator <> invalid then
    m.keyboardBackgroundHideTranslationInterpolator.keyValue = [m.keyboardBackgroundVisibleTranslation, m.keyboardBackgroundHiddenTranslation]
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

    ' Ubico fondo en posición oculta inicial para animar junto al teclado.
  if m.searchKeyboardBackground <> invalid then
    m.searchKeyboardBackground.translation = m.keyboardBackgroundHiddenTranslation
    m.searchKeyboardBackground.opacity = 0.0
  end if

' Refuerzo observers del TextEditBox al abrir teclado.
  __observeKeyboardTextEditBox()
  ' Inicio teclado transparente para fade in.
  m.searchKeyboard.opacity = 0.0

  ' Sincronizo texto persistido al teclado para recuperar valor aunque el input haya perdido foco.
  m.searchKeyboard.textEditBox.text = m.currentSearchText
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

  m.searchKeyboard.textEditBox.unobserveField("text")

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

    __restoreSearchInputText()
    ' Reubico teclado debajo de pantalla.
    m.searchKeyboard.translation = [0, m.scaleInfo.height]
    ' Dejo teclado transparente.
    m.searchKeyboard.opacity = 0.0

    ' Oculto fondo opaco del teclado sin animación.
    if m.searchKeyboardBackground <> invalid then
      m.searchKeyboardBackground.translation = [0, m.scaleInfo.height]
      m.searchKeyboardBackground.opacity = 0.0
    end if
  end if
  
end sub

' Al finalizar la animación de ocultar, deja el teclado invisible.
sub onKeyboardHideAnimationStateChanged()
  ' Si faltan nodos necesarios, salgo.
  if m.keyboardHideAnimation = invalid or m.searchKeyboard = invalid then return
  __restoreSearchInputText()

  ' Cuando la animación termina.
  if m.keyboardHideAnimation.state = "stopped" then
    ' Oculto teclado definitivamente.
    m.searchKeyboard.visible = false
    ' Lo dejo fuera de pantalla abajo.
    m.searchKeyboard.translation = [0, m.scaleInfo.height]
    ' Lo dejo transparente.
    m.searchKeyboard.opacity = 0.0
    ' Al terminar, también oculto el fondo opaco del teclado.
    if m.searchKeyboardBackground <> invalid then
      m.searchKeyboardBackground.translation = [0, m.scaleInfo.height]
      m.searchKeyboardBackground.opacity = 0.0
    end if
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

' Recompone el texto visible del input ante pérdidas de foco que vacían el valor.
sub __restoreSearchInputText()
  if m.searchInput = invalid then return
  if m.currentSearchText = invalid then m.currentSearchText = ""

  m.searchInput.text = m.currentSearchText
  m.searchInput.cursorPosition = m.currentSearchText.len()
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

      __loadSearchCarousels(invalid)
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
  ' Inicializo variable local para almacenar el item parseado.
  itemSelected = invalid

  ' Si hay foco en recomendados, tomo selección desde ese carrusel.
  if m.related <> invalid and m.related.isInFocusChain() then
    itemSelected = ParseJson(m.related.selected)
    ' Evito retriggers dejando selected en invalid.
    m.related.selected = invalid
  else if m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid then
    ' Si el foco está en carruseles de búsqueda, tomo la selección del carrusel enfocado.
    itemSelected = ParseJson(m.carouselContainer.focusedChild.selected)
    m.carouselContainer.focusedChild.selected = invalid
  end if

  ' Si no hay item parseable, no continúo con navegación.
  if itemSelected = invalid then return

  ' Persisto item seleccionado para reutilizarlo en callbacks asíncronos.
  m.itemSelected = itemSelected
  ' Guardo el foco actual para restaurarlo si el flujo falla.
  __markLastFocus()
  ' Obtengo índice del carrusel enfocado para lógica de style/viewall.
  m.carouselIndex = __getFocusedCarouselIndex()

  ' Si no hay API URL cacheada, la obtengo antes de consumir servicios.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)

  ' Muestro loading global mientras resuelvo la navegación del item.
  if m.top.loading <> invalid then m.top.loading.visible = true

  ' Si es item navegable distinto de creditId, aplico validación centralizada.
  if m.itemSelected.key <> invalid and LCase(m.itemSelected.key) <> "creditid" and m.itemSelected.id <> 0 then
    ' Delego navegación/validación por tipo de item.
    __validateCarouselItem(m.itemSelected)
    return
  end if

  ' Si es carrusel de estilo 7, rehago búsqueda usando el title del item seleccionado.
  if m.carouselIndex <> invalid and m.carousels <> invalid and m.carouselIndex >= 0 and m.carouselIndex < m.carousels.count() and m.carousels[m.carouselIndex] <> invalid and m.carousels[m.carouselIndex].style = 7 then
    ' Mantengo texto actual con el título del item para coherencia visual.
    m.currentSearchText = m.itemSelected.title
    ' Reflejo texto en input para que el usuario vea la nueva query aplicada.
    if m.searchInput <> invalid then m.searchInput.text = m.currentSearchText
    ' Disparo request de búsqueda con el title del elemento seleccionado.
    __getSearchPrograms(m.itemSelected.title)
    return
  end if

  ' Si es item de acción (sin key/id), resuelvo guide o viewall.
  if m.itemSelected.key = invalid and m.itemSelected.id = 0 then
    ' Si la redirección es guide, replico flujo de MainScreen.
    if m.itemSelected.redirectKey = "guide" then
      ' Disparo consulta de último canal visto para abrir Player con guía.
      __requestGuideLastWatched()
      return
    else if m.itemSelected.redirectKey = "viewall" then
      ' Armo payload para abrir ViewAllScreen con id del carrusel enfocado.
      if m.carouselIndex <> invalid and m.carousels <> invalid and m.carouselIndex >= 0 and m.carouselIndex < m.carousels.count() and m.carousels[m.carouselIndex] <> invalid then
        m.top.viewAll = FormatJson({ carouselId: m.carousels[m.carouselIndex].id })
      end if
      ' Oculto loading al terminar navegación local.
      if m.top.loading <> invalid then m.top.loading.visible = false
      return
    end if
  end if

  ' Si no cayó en ningún caso navegable, oculto loading y restauro foco.
  if m.top.loading <> invalid then m.top.loading.visible = false
  __restoreLastFocus()
end sub

' Valida control parental y resuelve navegación a player o detalle según redirectKey.
sub __validateCarouselItem(carouselItem)
  ' Si requiere control parental para canal, pido PIN reutilizando flujo de MainScreen.
  if carouselItem.parentalControl <> invalid and carouselItem.parentalControl = true and carouselItem.redirectKey = "ChannelId" then
    ' Muestro modal de PIN con mismo callback y textos usados en MainScreen.
    m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
    return
  end if

  ' Si no requiere PIN, navego según tipo de destino.
  __navigateToSelectedItem(carouselItem)
end sub

' Navega al player o al detalle según redirectKey del item recibido.
sub __navigateToSelectedItem(carouselItem)
  ' Si el destino es canal, valido watch para luego pedir streamings.
  if carouselItem.redirectKey = "ChannelId" then
    ' Obtengo watchSessionId actual para validar reproducción.
    watchSessionId = getWatchSessionId()
    ' Creo requestId para trazabilidad/retry del validate watch.
    requestId = createRequestId()
    ' Construyo acción HTTP para validar sesión de reproducción.
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlWatchValidate(m.apiUrl, watchSessionId, carouselItem.redirectKey, carouselItem.redirectId)
      method: "GET"
      responseMethod: "onWatchValidateResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    ' Registro la acción en el gestor de reintentos global.
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    ' Persisto manager actualizado por runAction.
    m.apiRequestManager = action.apiRequestManager
  else
    ' Si no es canal, redirecciono al detalle del programa con key/id.
    m.top.detail = FormatJson({ key: carouselItem.redirectKey, id: carouselItem.redirectId })
    ' Oculto loading al finalizar navegación por evento de detail.
    if m.top.loading <> invalid then m.top.loading.visible = false
  end if
end sub

' Retorna el índice del carrusel enfocado dentro del contenedor de búsqueda.
function __getFocusedCarouselIndex() as dynamic
  ' Si no hay carrusel enfocado, no puedo resolver índice.
  if m.carouselContainer = invalid or m.carouselContainer.focusedChild = invalid then return invalid
  ' Recorro hijos para ubicar posición del carrusel activo.
  for index = 0 to m.carouselContainer.getChildCount() - 1
    ' Comparo id del hijo con id del carrusel enfocado.
    if m.carouselContainer.getChild(index).id = m.carouselContainer.focusedChild.id then return index
  end for
  ' Si no coincide ninguno, retorno invalid.
  return invalid
end function

' Reutiliza flujo de MainScreen para abrir guía con último canal visto.
sub __requestGuideLastWatched()
  ' Activo bandera de abrir guía en PlayerScreen.
  m.top.openGuide = true
  ' Creo requestId para trazabilidad de consulta last watched.
  requestId = createRequestId()
  ' Construyo acción HTTP de últimos canales vistos.
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlChannelsLastWatched(m.apiUrl)
    method: "GET"
    responseMethod: "onLastWatchedResponse"
    body: invalid
    token: invalid
    publicApi: false
    dataAux: invalid
    requestId: requestId
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  ' Registro acción para retry/failover estándar.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  ' Persisto manager actualizado luego del envío.
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa respuesta de último canal visto para abrir player con guía.
sub onLastWatchedResponse()
  ' Si no hay manager activo, rehago selección para recuperar flujo.
  if m.apiRequestManager = invalid then
    onSelectItem()
    return
  end if
  ' Si status HTTP es válido, parseo payload de canales.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Remuevo acción pendiente al resolver correctamente.
    removePendingAction(m.apiRequestManager.requestId)
    ' Parseo respuesta JSON para extraer data.
    resp = ParseJson(m.apiRequestManager.response)
    ' Limpio manager luego de parsear respuesta.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    ' Si hay al menos un canal, preparo streaming mínimo para PlayerScreen.
    if resp <> invalid and resp.data <> invalid and resp.data.count() > 0 then
      m.top.streaming = FormatJson({ key: "ChannelId", id: resp.data[0].id })
    else
      ' Si no hay data, oculto loading y restauro foco navegable.
      if m.top.loading <> invalid then m.top.loading.visible = false
      __restoreLastFocus()
    end if
  else
    ' Si falla HTTP, oculto loading y limpio estado.
    if m.top.loading <> invalid then m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    removePendingAction(m.apiRequestManager.requestId)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    __restoreLastFocus()
    printError("LastWatched Search:", statusCode.toStr() + " " + errorResponse)
  end if
end sub

' Procesa callback del modal PIN reutilizando lógica de MainScreen.
sub onPinDialogLoad()
  ' Leo respuesta del PIN ingresado por el usuario.
  resp = m.pinDialog.response
  ' Creo requestId para la validación del PIN.
  requestId = createRequestId()
  ' Si se confirma botón OK con PIN de 4 dígitos, valido contra backend.
  if resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4 then
    if m.top.loading <> invalid then m.top.loading.visible = true
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlParentalControlPin(m.apiUrl, resp.pin)
      method: "GET"
      responseMethod: "onParentalControlResponse"
      body: invalid
      token: invalid
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else
    ' Si se cancela o PIN inválido en formato, cierro loading y restauro foco.
    if m.top.loading <> invalid then m.top.loading.visible = false
    __restoreLastFocus()
  end if
end sub

' Procesa la validación de PIN y navega si es correcta.
sub onParentalControlResponse()
  ' Si no hay manager, reproceso callback del dialog para recuperarme.
  if m.apiRequestManager = invalid then
    onPinDialogLoad()
    return
  end if
  ' Si status HTTP es válido, evaluo data booleana de PIN.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    resp = ParseJson(m.apiRequestManager.response)
    if resp <> invalid and resp.data <> invalid and resp.data then
      ' Si PIN es válido, limpio acción pendiente y navego al destino del item.
      removePendingAction(m.apiRequestManager.requestId)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      __navigateToSelectedItem(m.itemSelected)
    else
      ' Si PIN es incorrecto, oculto loading y muestro dialog de error.
      if m.top.loading <> invalid then m.top.loading.visible = false
      __markLastFocus()
      m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedLastFocus")
    end if
  else
    ' Si falla HTTP de parental control, limpio estado y devuelvo foco.
    if m.top.loading <> invalid then m.top.loading.visible = false
    statusCode = m.apiRequestManager.statusCode
    errorResponse = m.apiRequestManager.errorResponse
    removePendingAction(m.apiRequestManager.requestId)
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    __restoreLastFocus()
    printError("ParentalControl Search:", statusCode.toStr() + " " + errorResponse)
  end if
end sub

sub onWatchValidateResponse()
  ' Si no hay manager activo, reintento desde la selección actual.
  if m.apiRequestManager = invalid then
    onSelectItem()
    return
  end if

  ' Si status HTTP es correcto, analizo resultCode funcional.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Parseo la data de validación de watch.
    resp = ParseJson(m.apiRequestManager.response).data

    ' Si resultCode es 200, habilito reproducción y pido streamings.
    if resp.resultCode = 200 then
      ' Guardo watchSessionId devuelto por backend.
      setWatchSessionId(resp.watchSessionId)
      ' Guardo watchToken actualizado para requests posteriores.
      setWatchToken(resp.watchToken)
      if m.itemSelected <> invalid then
        ' Solicito URL de reproducción para el canal elegido.
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.itemSelected.redirectKey, m.itemSelected.redirectId), "GET", "onStreamingsResponse")
      end if
    else
      ' Oculto loading cuando backend rechaza la validación funcional.
      if m.top.loading <> invalid then m.top.loading.visible = false
      ' Limpio manager al abortar el flujo de reproducción.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Restaura foco al item previo para continuidad de UX.
      __restoreLastFocus()
      ' Logueo resultCode para diagnóstico.
      printError("WatchValidate ResultCode Search:", resp.resultCode)
    end if
  else
    ' Oculto loading ante error HTTP de validación.
    if m.top.loading <> invalid then m.top.loading.visible = false
    ' Obtengo status HTTP fallido para logging.
    statusCode = m.apiRequestManager.statusCode
    ' Obtengo cuerpo de error para logging.
    errorResponse = m.apiRequestManager.errorResponse
    ' Limpio manager al finalizar flujo con error.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    ' Restauro foco al último nodo para no perder navegabilidad.
    __restoreLastFocus()
    ' Registro error de status para diagnóstico.
    printError("WatchValidate Status Search:", statusCode.toStr() + " " + errorResponse)
  end if
end sub

sub onStreamingsResponse()
  ' Si el manager se limpió, reingreso al flujo previo de validación.
  if m.apiRequestManager = invalid then
    onWatchValidateResponse()
    return
  end if

  ' Si status HTTP de streaming es válido, proceso payload.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Remuevo request del pool de acciones pendientes.
    removePendingAction(m.apiRequestManager.requestId)
    ' Parseo respuesta de streamings.
    resp = ParseJson(m.apiRequestManager.response)
    if resp.data <> invalid then
      ' Limpio manager al tener respuesta útil.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Copio objeto de streaming retornado por API.
      streaming = resp.data
      ' Adjuntamos clave original seleccionada.
      streaming.key = m.itemSelected.redirectKey
      ' Adjuntamos id original seleccionado.
      streaming.id = m.itemSelected.redirectId
      ' Definimos tipo de streaming por defecto.
      streaming.streamingType = getStreamingType().DEFAULT
      ' Emitimos evento para que MainScene abra Player.
      m.top.streaming = FormatJson(streaming)
    else
      ' Oculto loading cuando no llega data reproducible.
      if m.top.loading <> invalid then m.top.loading.visible = false
      ' Restauro foco para permitir nueva selección.
      __restoreLastFocus()
      ' Logueo respuesta vacía para diagnóstico.
      printError("Streamings Empty Search:", m.apiRequestManager.response)
      ' Limpio manager al cerrar flujo.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    end if
  else
    ' Oculto loading ante error HTTP en streamings.
    if m.top.loading <> invalid then m.top.loading.visible = false
    ' Guardo status HTTP para telemetría/log.
    statusCode = m.apiRequestManager.statusCode
    ' Guardo error HTTP textual para logging.
    errorResponse = m.apiRequestManager.errorResponse
    ' Remuevo acción fallida del pool de pendientes.
    removePendingAction(m.apiRequestManager.requestId)
    ' Limpio manager al finalizar con error.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    ' Restaura foco al elemento previamente activo.
    __restoreLastFocus()
    ' Registro error de streamings para diagnóstico.
    printError("Streamings Search:", statusCode.toStr() + " " + errorResponse)
  end if
end sub

' Cierra dialog de error y devuelve foco al último carrusel seleccionado.
sub onDialogClosedLastFocus()
  ' Si existe dialog abierto, lo cerramos explícitamente.
  if m.dialog <> invalid then m.dialog.close = true
  ' Restauramos foco para continuar navegación en Search.
  __restoreLastFocus()
end sub

sub __markLastFocus()
  ' Si hay carrusel de búsqueda enfocado, lo guardo como último foco válido.
  if m.carouselContainer <> invalid and m.carouselContainer.focusedChild <> invalid then
    m.lastFocusedNode = m.carouselContainer.focusedChild
  else if m.related <> invalid and m.related.isInFocusChain() then
    ' Si no, guardo foco en carrusel de recomendados.
    m.lastFocusedNode = m.related
  end if
end sub

sub __restoreLastFocus()
  ' Si no hay nodo cacheado, no hay foco para restaurar.
  if m.lastFocusedNode = invalid then return

  ' Si el último foco fue recomendados, enfoco su lista interna.
  if m.lastFocusedNode.id = m.related.id then
    focusItem = m.related.findNode("carouselList")
    ' Si existe lista interna, reaplico foco directo.
    if focusItem <> invalid then focusItem.setFocus(true)
    ' Muestro indicador de recomendados tras restaurar foco.
    m.selectedIndicator.visible = true
    return
  end if

  ' Busco lista interna del último carrusel de búsqueda enfocado.
  focusItem = m.lastFocusedNode.findNode("carouselList")
  if focusItem <> invalid then
    ' Aseguro opacidad visible de la fila restaurada.
    m.lastFocusedNode.opacity = "1.0"
    ' Reaplico foco sobre la lista del carrusel objetivo.
    focusItem.setFocus(true)
    ' Sincronizo tamaño del indicador con el carrusel restaurado.
    m.searchSelectedIndicator.size = m.lastFocusedNode.size
    ' Muestro indicador de selección de búsqueda.
    m.searchSelectedIndicator.visible = true
    ' Reposiciono contenedor vertical para dejar visible la fila.
    m.carouselContainer.translation = [m.carouselXPosition, -(m.lastFocusedNode.translation[1] - m.carouselYPosition)]
  end if
end sub

' Restaura foco al último item seleccionado al volver desde otras pantallas.
sub restoreFocus()
  ' Si existe un nodo previamente enfocado, lo restauro.
  if m.lastFocusedNode <> invalid then
    __restoreLastFocus()
  else if m.searchInput <> invalid then
    ' Fallback: si no hay historial de foco, regreso al input.
    m.searchInput.setFocus(true)
  end if
end sub

' Fuerza restaurar foco al volver desde ProgramDetail priorizando resultados/recomendados.
sub __restoreFocusFromProgramDetail()
  ' Prioridad 1: último foco conocido en resultados/recomendados.
  if m.lastFocusedNode <> invalid then
    __restoreLastFocus()
    return
  end if

  ' Prioridad 2: primer carrusel de resultados de búsqueda.
  if m.carouselContainer <> invalid and m.carouselContainer.getChildCount() > 0 then
    firstCarousel = m.carouselContainer.getChild(0)
    firstList = firstCarousel.findNode("carouselList")
    if firstList <> invalid then
      m.lastFocusedNode = firstCarousel
      firstList.setFocus(true)
      m.searchSelectedIndicator.size = firstCarousel.size
      m.searchSelectedIndicator.visible = true
      return
    end if
  end if

  ' Prioridad 3: carrusel de recomendados (ErrorPage).
  if m.related <> invalid then
    relatedList = m.related.findNode("carouselList")
    if relatedList <> invalid then
      relatedList.setFocus(true)
      m.selectedIndicator.size = m.related.size
      m.selectedIndicator.visible = true
      return
    end if
  end if

  ' Fallback final para no dejar pantalla sin foco navegable.
  if m.searchInput <> invalid then m.searchInput.setFocus(true)
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
  ' Cacheo los carruseles actuales para lógicas de style/viewall por índice.
  m.carousels = carousels
  ' Si falta estructura visual, no hay nada que renderizar.
  if m.carouselContainer = invalid or m.searchCarousels = invalid then return

  ' Limpio carruseles previos para evitar duplicados tras nuevas búsquedas.
  if m.carouselContainer.getChildCount() > 0 then m.carouselContainer.removeChildrenIndex(m.carouselContainer.getChildCount(), 0)
  ' Posición base del contenedor para el cálculo de desplazamiento vertical al navegar.
  m.carouselContainer.translation = scaleSize([0, -63], m.scaleInfo)
  m.searchSelectedIndicator.translation = scaleSize([68, 65], m.scaleInfo)
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
onSelectItem()
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