' ****** Funciones Públicas ******

' Inicializa referencias internas del componente ViewAllScreen.
sub init()
  ' Guardamos información de escala para posicionamiento responsive.
  m.scaleInfo = m.global.scaleInfo
  ' Referencia al timer que difiere el summary al mover foco.
  m.programTimer = m.top.findNode("programTimer")
  ' Referencia al componente visual de Program Summary.
  m.programInfo = m.top.findNode("programInfo")
  ' Referencia al gradiente superior como en MainScreen.
  m.infoGradient = m.top.findNode("infoGradient")
  ' Referencia al poster de fondo dinámico.
  m.programImageBackground = m.top.findNode("programImageBackground")
  ' Bloque grilla nativa: referencia al PosterGrid de ViewAll.
  m.posterGrid = m.top.findNode("posterGrid")
  ' Referencia al título del carrusel mostrado sobre la grilla.
  m.carouselTitle = m.top.findNode("carouselTitle")
  ' Referencia al mensaje mostrado cuando ViewAll no tiene contenido.
  m.noResultsLabel = m.top.findNode("noResultsLabel")
  ' Cacheamos último foco para restaurarlo tras errores de red/validación.
  m.lastFocusedProgram = invalid
end sub

' Maneja la lógica de foco para la pantalla.
sub initFocus()
  ' Siempre que ViewAll vuelva a estar visible, reposicionamos foco al primer item del primer carrusel.
  if m.top.onFocus then __focusPosterGrid()
end sub

' Solicita Program Summary del item enfocado, emulando el flujo de MainScreen.
sub getProgramInfo()
  clearTimer(m.programTimer)
  if m.itemfocused = invalid then return
  ' Reutilizamos cache si ya tenemos ese summary.
  if m.program <> invalid and m.program.infoKey = m.itemfocused.redirectKey and m.program.infoId = m.itemfocused.redirectId then
     ' Mostramos summary sin usar la API nuevamente.
    m.programInfo.visible = true
    return
  end if
  if m.apiSummaryRequestManager <> invalid then
    m.programTimer.ObserveField("fire", "getProgramInfo")
    m.programTimer.control = "start"
    return
  end if
  ' Recuperamos API URL si aún no existe en memoria.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Cortamos si la app no tiene URL de API disponible.
  if m.apiUrl = invalid then return
  ' Inicializamos tipo de imagen principal por defecto.
  mainImageTypeId = getCarouselImagesTypes().NONE.toStr()
  ' Usamos imageType del carrusel cuando está presente.
  ' Bloque Program Summary: PosterGrid no expone imageType por fila, usamos tipo base.
  if m.viewAllImageType <> invalid and m.viewAllImageType <> 0 then mainImageTypeId = m.viewAllImageType.ToStr()
  ' Generamos identificador de acción para retry tracking.
  requestId = createRequestId()
  action = {
    node: m.top
    apiSummaryRequestManager: m.apiSummaryRequestManager
    url: urlProgramSummary(m.itemfocused.redirectKey, m.itemfocused.redirectId, mainImageTypeId, getCarouselImagesTypes().SCENIC_LANDSCAPE)
    method: "GET"
    responseMethod: "onProgramSummaryResponse"
    body: invalid
    token: invalid
    publicApi: false
    methodName: "getProgramInfo"
    parameter: invalid
    dataAux: invalid
    requestId: requestId
    run: function() as Object
      m.apiSummaryRequestManager = sendApiRequest(m.apiSummaryRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  ' Ejecutamos acción con soporte de reintentos.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  m.apiSummaryRequestManager = action.apiSummaryRequestManager
end sub

' Obtener el beacon token
sub onActionLogTokenResponse()

  resp = ParseJson(m.apiLogRequestManager.response)
  actionLog = ParseJson(m.apiLogRequestManager.dataAux)

  setBeaconToken(resp.actionsLogToken)

  now = CreateObject("roDateTime")
  now.ToLocalTime()
  m.global.beaconTokenExpiresIn = now.asSeconds() + ((resp.expiresIn - 60) * 1000)

  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
  __sendActionLog(actionLog)
end sub

' Limpiar la llamada del log
sub onActionLogResponse()
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub

' Procesa el payload enviado desde MainScreen para cargar el carrusel completo.
sub onDataChange()
  __configMain()
   if m.top.data = invalid or m.top.data = "" then
    ' Al salir de ViewAll, MainScene invalida data; limpiamos el listado para no mostrar carruseles viejos al reingresar.
    m.viewAllPayload = invalid
    __clearViewAllCarousel()
    return
  end if
  payload = ParseJson(m.top.data)
  if payload = invalid then return
  m.viewAllPayload = payload
  m.viewAllCarouselStyle = invalid
  if payload.carouselStyle <> invalid then
    m.viewAllCarouselStyle = payload.carouselStyle
  else if payload.style <> invalid then
    m.viewAllCarouselStyle = payload.style
  end if
  __applyLayout()
  __applyCarouselTitle()
  __applyTranslations()
  ' Ocultamos cualquier estado vacío anterior mientras se carga el nuevo contenido.
  __showNoResults(false)
  ' Disparamos el consumo del servicio de ViewAll.
  __getViewAllCarousel()

  ' Guardamos el log de ingreso
  actionLog = getActionLog({
    actionCode: ActionLogCode().OPEN_PAGE,
    pageUrl: "View All"
  })

  __saveActionLog(actionLog)
end sub

' Bloque grilla nativa: reacciona al foco de un item del PosterGrid y prepara Program Summary.
sub onFocusItem()
  ' Validamos que el foco pertenezca al PosterGrid activo.
  if m.posterGrid = invalid or not m.posterGrid.isInFocusChain() then return
  focusedIndex = m.posterGrid.itemFocused
  if focusedIndex = invalid or focusedIndex < 0 then return
  if m.viewAllGridItems = invalid or focusedIndex >= m.viewAllGridItems.count() then return
  newFocus = m.viewAllGridItems[focusedIndex]
  if newFocus = invalid then return
  ' Evitamos llamadas duplicadas para el mismo item.
  if m.itemfocused = invalid or (newFocus.key <> m.itemfocused.key or newFocus.id <> m.itemfocused.id or newFocus.redirectKey <> m.itemfocused.redirectKey or newFocus.redirectId <> m.itemfocused.redirectId) then
    ' Ocultamos summary mientras se carga el nuevo programa.
    m.programInfo.visible = false
    ' Limpiamos fondo para evitar mostrar data vieja.
    m.programImageBackground.uri = ""
    ' Guardamos item enfocado que se usará en la consulta.
    m.itemfocused = newFocus
    m.lastFocusedProgramIndex = focusedIndex
    clearTimer(m.programTimer)
    m.programTimer.ObserveField("fire", "getProgramInfo")
    m.programTimer.control = "start"
  end if
end sub

' Procesa navegación vertical para mover foco entre filas de carruseles en ViewAll.
' Bloque grilla nativa: PosterGrid administra navegación direccional, no se interceptan flechas.
function onKeyEvent(key as string, press as boolean) as boolean

  if isPINDialogVisible() then return true
  return false
end function

' Procesa la respuesta de Program Summary para actualizar la franja superior.
sub onProgramSummaryResponse()
  ' Si el manager se limpió, volvemos a intentar desde el foco actual.
  if m.apiSummaryRequestManager = invalid then
    ' Reintentamos solicitar summary del item vigente.
    getProgramInfo()
    return
  end if
  if validateStatusCode(m.apiSummaryRequestManager.statusCode) then
    m.itemfocused = invalid
    resp = ParseJson(m.apiSummaryRequestManager.response)
    if resp <> invalid and resp.data <> invalid then
      removePendingAction(m.apiSummaryRequestManager.requestId)
      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
      ' Guardamos programa actual para reutilización.
      m.program = resp.data
      ' Validamos si el programa trae imagen de fondo.
      if m.program.backgroundImage <> invalid then
        m.programImageBackground.uri = getImageUrl(m.program.backgroundImage)
      else
        m.programImageBackground.uri = ""
      end if
      ' Enviamos summary al componente ProgramSummary.
      m.programInfo.program = FormatJson(m.program)
      ' Actualizamos nodo enfocado con info enriquecida.
      ' Bloque grilla nativa: PosterGrid no requiere actualizar un nodo Carousel custom.
      ' Mostramos bloque superior con la información del programa.
      m.programInfo.visible = true
    else
      ' Ocultamos summary si respuesta llega sin data.
      m.programInfo.visible = false
      m.programImageBackground.uri = ""
      m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
    end if
  else
    statusCode = m.apiSummaryRequestManager.statusCode
    errorResponse = m.apiSummaryRequestManager.errorResponse
    if m.apiSummaryRequestManager.serverError then
      ' Marcamos acción para reintento.
      changeStatusAction(m.apiSummaryRequestManager.requestId, "error")
      ' Ejecutamos reintentos pendientes.
      retryAll()
    else
      ' Limpiamos pending action no reintentable.
      removePendingAction(m.apiSummaryRequestManager.requestId)
      printError("ProgramSummary ViewAll:", errorResponse)
       ' Delegamos si error obliga logout.
      if validateLogout(statusCode, m.top) then return
      m.programInfo.visible = false
      m.programImageBackground.uri = ""
    end if
    m.apiSummaryRequestManager = clearApiRequest(m.apiSummaryRequestManager)
  end if
end sub

' Bloque grilla nativa: toma la selección del PosterGrid y decide si abre Player o Detalle, igual que MainScreen.
sub onSelectItem()
    ' Ocultamos loading porque la navegación ya fue emitida.
    if m.top.loading <> invalid then m.top.loading.visible = false

  ' Validamos que exista un PosterGrid activo con foco.
  if m.posterGrid = invalid or not m.posterGrid.isInFocusChain() then return
  selectedIndex = m.posterGrid.itemSelected
  if selectedIndex = invalid or selectedIndex < 0 then return
  if m.viewAllGridItems = invalid or selectedIndex >= m.viewAllGridItems.count() then return
  ' Leemos payload del item seleccionado desde la colección normalizada de la grilla.
  m.itemSelected = m.viewAllGridItems[selectedIndex]
  ' Cortamos si el payload no pudo resolverse.
  if m.itemSelected = invalid then return

  ' Guardamos referencia del foco para restauración en caso de error.
  __markLastFocus()

  if  m.itemSelected.parentalControl <> invalid and  m.itemSelected.parentalControl = true and  m.itemSelected.redirectKey = "ChannelId" then

     ' Muestro modal de PIN con mismo callback y textos usados en MainScreen.
    m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onPinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
    return
  else

    ' Mostramos loading global mientras resolvemos la acción.
    if m.top.loading <> invalid then m.top.loading.visible = true

    ' Si el item es canal, replicamos flujo WatchValidate + Streaming de MainScreen.
    if m.itemSelected.redirectKey = "ChannelId" then
      ' Recuperamos la sesión de visualización activa.
      watchSessionId = getWatchSessionId()
      ' Creamos requestId para retries del servicio.
      requestId = createRequestId()
      action = {
        node: m.top
        apiRequestManager: m.apiRequestManager
        url: urlWatchValidate(watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
        method: "GET"
        responseMethod: "onWatchValidateResponse"
        body: invalid
        token: invalid
        publicApi: false
        methodName: "onSelectItem"
        parameter: invalid
        dataAux: invalid
        requestId: requestId
        run: function() as Object
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
          return { success: true, error: invalid }
        end function
      }
      ' Ejecutamos acción con retries centralizados.
      runAction(requestId, action, ApiType().CLIENTS_API_URL)
      m.apiRequestManager = action.apiRequestManager
    else
      ' Limpiamos cualquier request pendiente antes de navegar a detalle.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Emitimos detalle para que MainScene abra ProgramDetailScreen.
      m.top.detail = FormatJson(m.itemSelected)
    end if
  end if
end sub

' Procesa callback del modal PIN reutilizando lógica de MainScreen.
sub onPinDialogLoad()
  if m.top.loading <> invalid then m.top.loading.visible = false

  ' Leo respuesta del PIN ingresado por el usuario.
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  ' Creo requestId para la validación del PIN.
  requestId = createRequestId()
  ' Si se confirma botón OK con PIN de 4 dígitos, valido contra backend.
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then
    if m.top.loading <> invalid then m.top.loading.visible = true
    action = {
      node: m.top
      apiRequestManager: m.apiRequestManager
      url: urlParentalControlPin(resp.pin)
      method: "GET"
      responseMethod: "onParentalControlResponse"
      body: invalid
      token: invalid
      publicApi: false
      methodName: "onPinDialogLoad"
      parameter: invalid
      dataAux: invalid
      requestId: requestId
      run: function() as object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    m.apiRequestManager = action.apiRequestManager
  else
    __restoreLastFocus()
  end if
end sub

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
  if m.top.loading <> invalid then m.top.loading.visible = false

  if m.apiRequestManager = invalid then
    onPinDialogLoad()
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      resp = ParseJson(m.apiRequestManager.response)

      if resp <> invalid and resp.data <> invalid and resp.data then
        removePendingAction(m.apiRequestManager.requestId)
        watchSessionId = getWatchSessionId()
        requestId = createRequestId()
        action = {
          node: m.top
          apiRequestManager: m.apiRequestManager
          url: urlWatchValidate(watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
          method: "GET"
          responseMethod: "onWatchValidateResponse"
          body: invalid
          token: invalid
          publicApi: false
          methodName: "onParentalControlResponse"
          parameter: invalid
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
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), i18n_t(m.global.i18n, "shared.parentalControlModal.error.description"), "onDialogClosedFocusContainer")
      end if
    else
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)

      if m.apiRequestManager.serverError then
        __validateError(statusCode)
        changeStatusAction(m.apiRequestManager.requestId, "error")
        retryAll()
      else
        removePendingAction(m.apiRequestManager.requestId)

        printError("ParentalControl:", statusCode.toStr() + " " +  errorResponse)

        if validateLogout(statusCode, m.top) then return

        if (statusCode = 408) then
          __markLastFocus()
          m.dialog = createAndShowDialog(m.top, i18n_t(m.global.i18n, "shared.errorComponent.anErrorOcurred"), i18n_t(m.global.i18n, "shared.errorComponent.serverConnectionProblems"), "onDialogClosedLastFocus", [i18n_t(m.global.i18n, "button.cancel")])
        else
          __validateError(statusCode)
        end if

        actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("valdiatePin", "ParentalControlModalComponent"), getServerErrorStack(errorResponse))
        __saveActionLog(actionLog)
      end if
    end if
  end if
end sub

' Cierra dialog de error y devuelve foco al último carrusel seleccionado.
sub onDialogClosedLastFocus()
  ' Si existe dialog abierto, lo cerramos explícitamente.
  if m.dialog <> invalid then m.dialog.close = true

  clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid
  ' Restauramos foco para continuar navegación en Search.
  __restoreLastFocus()
end sub

' Procesa el cierre de los modales de error para volver a dar foco sobre el elemento que lo
' tenia antes del error
sub onDialogClosedFocusContainer()
  option = clearDialogAndGetOption(m.top, m.dialog)
  m.dialog = invalid

  if option = 0 then __restoreLastFocus()
end sub

' Procesa la respuesta del servicio de streaming y emite salida hacia MainScene para abrir Player.
sub onStreamingsResponse()
  ' Ocultamos loading al no recibir data reproducible.
  if m.top.loading <> invalid then m.top.loading.visible = false

  ' Si no hay manager activo, reintentamos validación.
  if m.apiRequestManager = invalid then
    ' Reingresamos al flujo de validación previo.
    onWatchValidateResponse()
    return
  else
    ' Validamos respuesta exitosa del servicio de streaming.
    if validateStatusCode(m.apiRequestManager.statusCode) then
      ' Quitamos request del pool de acciones pendientes.
      removePendingAction(m.apiRequestManager.requestId)
      ' Parseamos respuesta JSON de streaming.
      resp = ParseJson(m.apiRequestManager.response)
      if resp <> invalid and resp.data <> invalid then
        ' Limpiamos request manager al obtener data válida.
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        streaming = resp.data
        streaming.key = m.itemSelected.redirectKey
        streaming.id = m.itemSelected.redirectId
         ' Indicamos tipo por defecto como en MainScreen.
        streaming.streamingType = getStreamingType().DEFAULT
         ' Emitimos salida para que MainScene abra PlayerScreen.
        m.top.streaming = FormatJson(streaming)
      else
         ' Devolvemos foco al elemento previo para continuidad de UX.
        __restoreLastFocus()
        printError("Streamings Empty ViewAll:", m.apiRequestManager.response)
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      end if
    else
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      removePendingAction(m.apiRequestManager.requestId)
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Recuperamos foco para mantener navegabilidad.
      __restoreLastFocus()
      __validateError(statusCode)
      printError("Streamings ViewAll:", errorResponse)
    end if
  end if
end sub

' Procesa la respuesta del servicio de ViewAll.
sub onViewAllCarouselResponse()
  if m.top.loading <> invalid then m.top.loading.visible = false

  if m.apiRequestManager = invalid then
    ' Re-disparamos la obtención del carrusel.
    __getViewAllCarousel()
    return
  end if
  ' Evaluamos si la respuesta HTTP es correcta.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Quitamos la acción del pool pendiente.
    removePendingAction(m.apiRequestManager.requestId)
    resp = ParseJson(m.apiRequestManager.response)
    viewAllData = invalid
    ' Extraemos data sólo cuando la respuesta parseada es válida.
    if resp <> invalid then viewAllData = resp.data
    ' Reutilizamos la misma lógica de resolución para evitar duplicación.
    viewAllItems = __getViewAllSourceItems(viewAllData)
    ' Validamos que exista una colección de items para pintar.
    if viewAllItems.count() > 0 then
      m.carousel = viewAllData
      ' Renderizamos carrusel con datos de ViewAll.
      __populateViewAllCarousel(viewAllData)
      ' Mostramos estado vacío si las colecciones recibidas no generaron filas con items.
      hasRenderedRows = false
      if m.viewAllGridItems <> invalid then hasRenderedRows = m.viewAllGridItems.count() > 0
      __showNoResults(not hasRenderedRows)
    else
      ' Limpiamos UI y mostramos feedback cuando la API no trae items.
      __clearViewAllCarousel()
      __showNoResults(true)
    end if
  else
    error = m.apiRequestManager.errorResponse
    statusCode = m.apiRequestManager.statusCode
    ' Limpiamos contenido previo y mostramos feedback ante cualquier error.
    __clearViewAllCarousel()
    __showNoResults(true)
    if m.apiRequestManager.serverError then
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      ' Limpiamos acción pendiente no reintentable.
      removePendingAction(m.apiRequestManager.requestId)
      printError("ViewAllCarousel:", error)

      ' Guardar el log de Error
      actionLog = createLogError("", "", invalid)
      __saveActionLog(actionLog)
      ' Validamos si el error requiere forzar logout.
      if validateLogout(statusCode, m.top) then
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        return
      end if
    end if
  end if
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
end sub

' Procesa la respuesta de WatchValidate para decidir si continúa a streaming, igual que MainScreen.
sub onWatchValidateResponse()
  if m.top.loading <> invalid then m.top.loading.visible = false

  ' Si el manager se limpió por retry, reintentamos selección actual.
  if m.apiRequestManager = invalid then
    ' Reintentamos flujo desde el item seleccionado.
    onSelectItem()
    return
  else
    if validateStatusCode(m.apiRequestManager.statusCode) then
      ' Parseamos payload de validación.
      resp = ParseJson(m.apiRequestManager.response).data

      ' Si está autorizado, pedimos URL de streaming.
      if resp.resultCode = 200 then
        setWatchSession(resp)
        if m.itemSelected <> invalid then
          ' Solicitamos streaming del item canal seleccionado.
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.itemSelected.redirectKey, m.itemSelected.redirectId), "GET", "onStreamingsResponse")
        end if
      else
        ' Limpiamos request manager al cortar el flujo.
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        ' Reutilizamos manejo de errores funcionales de MainScreen.
        __validateError(0)
        printError("WatchValidate ResultCode ViewAll:", resp.resultCode)
      end if
    else
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Delegamos el handling de error común.
      __validateError(statusCode)
      printError("WatchValidate Status ViewAll:", statusCode.toStr() + " " + errorResponse)
    end if
  end if
end sub

' Bloque grilla nativa: restaura foco al último item activo (o al primero disponible) al volver a ViewAll.
sub restoreFocus()
  __focusPosterGrid()
end sub

' ****** Funciones privadas ******

' Configura posiciones y tamaños principales igual que MainScreen.
sub __applyLayout()
  if m.scaleInfo = invalid then return
  safeX = m.scaleInfo.safeZone.x
  safeY = m.scaleInfo.safeZone.y
  width = m.scaleInfo.width
  height = m.scaleInfo.height
  ' Guardamos X base del contenedor para reutilizarla al navegar entre filas.
  m.xPosition = safeX + scaleValue(0, m.scaleInfo)
  ' Guardamos Y base del contenedor para recalcular desplazamiento vertical al cambiar de carrusel.
  m.yPosition = safeY + scaleValue(20, m.scaleInfo)
  m.infoGradient.width = width
  m.infoGradient.height = height
  m.programImageBackground.width = width
  m.programImageBackground.height = height
  m.programInfo.translation = [safeX + scaleValue(35, m.scaleInfo), safeY ]
    ' Título del carrusel alineado al margen izquierdo de la grilla y ubicado sobre ella.
  if m.carouselTitle <> invalid then
    m.carouselTitle.translation = [safeX + scaleValue(35, m.scaleInfo), safeY + scaleValue(200, m.scaleInfo)]
    m.carouselTitle.width = width - safeX - scaleValue(20, m.scaleInfo)
    m.carouselTitle.height = scaleValue(40, m.scaleInfo)
  end if
  ' Bloque grilla nativa: configuramos medidas base de la grilla en la zona inferior de ViewAll.
  m.posterGrid.translation = [safeX + scaleValue(35, m.scaleInfo), safeY + scaleValue(260, m.scaleInfo)]
  m.posterGrid.itemSize = __applyPosterGridItemLayout(m.viewAllCarouselStyle)
  m.posterGrid.vertFocusAnimationStyle = __applyPosterGridItemVerticalFocus(m.viewAllCarouselStyle)
  m.posterGrid.itemSpacing = scaleSize([22, 34], m.scaleInfo)
  m.posterGrid.itemComponentName = "ViewAllGridItem"
  ' Bloque foco: aplicamos el color primario al borde/bitmap de selección del PosterGrid.
  if m.global.colors <> invalid and m.global.colors.PRIMARY <> invalid then m.posterGrid.focusBitmapBlendColor = m.global.colors.PRIMARY
  ' El ancho completo permite que horizAlign centre el texto en la pantalla.
  if m.noResultsLabel <> invalid then
    m.noResultsLabel.width = width
    m.noResultsLabel.translation = scaleSize([0, safeY + 200], m.scaleInfo)
    m.noResultsLabel.color = m.global.colors.WHITE
  end if
end sub

' Aplica al PosterGrid los mismos tamaños base que usa Carousel según style en MainScreen.
function __applyPosterGridItemLayout(style as Dynamic)
  if m.posterGrid = invalid or m.scaleInfo = invalid then return 0

  itemSize = [180, 270]

  if style = -1 then
    itemSize = [120, 120]
  else if style = getCarouselStyles().PORTRAIT_FEATURED then
    itemSize = [218, 328]
  else if style = getCarouselStyles().LANDSCAPE_STANDARD then
    itemSize = [450, 253]
  else if style = getCarouselStyles().LANDSCAPE_FEATURED then
    itemSize = [450, 253]
  else if style = getCarouselStyles().SQUARE_STANDARD then
    itemSize = [120, 120]
  else if style = getCarouselStyles().SQUARE_FEATURED then
    itemSize = [310, 110]
    return scaleSize(itemSize, m.scaleInfo)
  end if

  return scaleSize(itemSize, m.scaleInfo)
end function

' Aplica al PosterGrid cuales son los filas que puede scrollear
function __applyPosterGridItemVerticalFocus(style as Dynamic)
  carouselStyles = getCarouselStyles()

  if style = carouselStyles.PORTRAIT_STANDARD or style = carouselStyles.PORTRAIT_FEATURED or style = carouselStyles.LANDSCAPE_STANDARD or style = carouselStyles.LANDSCAPE_FEATURED then
    return "fixedFocus"
  end if

  return "floatingFocus"
end function

' Aplica los textos traducidos de ViewAll.
sub __applyTranslations()
  if m.global.i18n = invalid then return
  if m.noResultsLabel <> invalid then m.noResultsLabel.text = i18n_t(m.global.i18n, "viewAll.noResults")
end sub

' Muestra u oculta el mensaje de ViewAll sin resultados.
sub __showNoResults(show as boolean)
  if m.noResultsLabel = invalid then return
  m.noResultsLabel.visible = show
end sub

' Aplica el nombre del carrusel recibido en el payload de navegación.
sub __applyCarouselTitle()
  if m.carouselTitle = invalid then return

  carouselTitleText = ""
  carouselTitleTagsText = ""

  if m.viewAllPayload <> invalid then
    if m.viewAllPayload.title <> invalid then carouselTitleText = m.viewAllPayload.title.toStr().trim()

    if m.viewAllPayload.titleTagsText <> invalid then
      carouselTitleTagsText = m.viewAllPayload.titleTagsText.toStr().trim()
    else if m.viewAllPayload.titleTags <> invalid then
      carouselTitleTagsText = __buildCarouselTitleTagsText(m.viewAllPayload.titleTags)
    end if
  end if

  m.carouselTitle.drawingStyles = {
    "default": { "fontUri": "font:MediumBoldSystemFont", "color": "0xFFFFFFFF" }
    "titleTags": { "fontUri": "font:MediumBoldSystemFont", "color": "0xFFA500FF" }
  }

  if carouselTitleTagsText <> "" then
    m.carouselTitle.text = carouselTitleText + " <titleTags> " + carouselTitleTagsText + "</titleTags>"
  else
    m.carouselTitle.text = carouselTitleText
  end if

  m.carouselTitle.visible = carouselTitleText <> ""
end sub

' Construye el string de tags del título usando formato: "tag" | Tag2 | Tag3.
function __buildCarouselTitleTagsText(titleTags as Dynamic) as String
  ' Si titleTags no existe o no es lista, retornamos vacío para ocultar el texto.
  if titleTags = invalid then return ""
  ' Si el objeto no implementa ifArray, lo tratamos como estructura inválida.
  if GetInterface(titleTags, "ifArray") = invalid then return ""

  formattedTags = []

  for each titleTag in titleTags
    ' Cortamos el proceso al llegar al máximo de 5 tags.
    if formattedTags.count() >= 5 then exit for
    if titleTag = invalid then continue for
    ' Si no existe atributo tag, el elemento no es utilizable.
    if titleTag.tag = invalid then continue for

    ' Convertimos el tag a string y removemos espacios sobrantes.
    tagText = titleTag.tag.toStr().trim()
    ' Si el texto final queda vacío, no se agrega al resultado.
    if tagText = "" then continue for

    ' Si quote viene en true, encerramos el tag entre comillas dobles.
    if titleTag.quote = true then
      ' Aplicamos formato solicitado para tags con quote.
      tagText = Chr(34) + tagText + Chr(34)
    end if

    ' Agregamos el tag válido y formateado al acumulador.
    formattedTags.push(tagText)
  end for

  ' Si no se obtuvo ningún tag válido, devolvemos vacío.
  if formattedTags.count() = 0 then return ""

  ' Inicializamos string final para unir manualmente con separador pipe.
  tagsText = ""
  ' Concatenamos tags en orden respetando el separador requerido.
  for each formattedTag in formattedTags
    ' Primer elemento sin separador prefijo.
    if tagsText = "" then
      tagsText = formattedTag
    else
      ' Resto de elementos con separador " | ".
      tagsText = tagsText + " | " + formattedTag
    end if
  end for

  ' Retornamos string final para renderizar a la derecha del título.
  return tagsText
end function

' Genera body JSON compartido para búsquedas.
function __buildSearchBody(searchText as Dynamic) as string
  safeSearchText = ""
  ' Convertimos a string y limpiamos espacios del texto de búsqueda.
  if searchText <> invalid then safeSearchText = searchText.toStr().trim()
  ' Devolvemos el mismo formato de body usado por urlSearch.
  return FormatJson({ searchText: safeSearchText })
end function

' Bloque grilla nativa: limpia el PosterGrid actual de ViewAll y resetea estado visual asociado.
sub __clearViewAllCarousel()
  ' Reseteamos la colección cacheada para que el componente quede sin contenido al salir.
  m.carousel = []
  m.viewAllGridItems = []
  m.lastFocusedProgram = invalid
  m.lastFocusedProgramIndex = 0
  m.itemfocused = invalid
  if m.carouselTitle <> invalid then
    m.carouselTitle.text = ""
    m.carouselTitle.visible = false
  end if
  if m.posterGrid <> invalid then
    m.posterGrid.unobserveField("itemFocused")
    m.posterGrid.unobserveField("itemSelected")
    m.posterGrid.content = invalid
    m.posterGrid.visible = false
  end if
  ' Ocultamos summary al limpiar contenido.
  m.programInfo.visible = false
  ' Limpiamos imagen de fondo del programa previo.
  m.programImageBackground.uri = ""
  ' Ocultamos el estado vacío; quien limpia por falta de datos lo vuelve a mostrar.
  __showNoResults(false)
end sub

' Carga la configuracion inicial de la ViewAll.
sub __configMain()
  m.programInfo.width = (m.scaleInfo.width - scaleValue(300, m.scaleInfo))
  m.programInfo.initConfig = true
end sub

' Bloque grilla nativa: posiciona el foco en el último item recordado o en el primero del PosterGrid.
sub __focusPosterGrid()
  if m.posterGrid = invalid then return
  if m.viewAllGridItems = invalid or m.viewAllGridItems.count() = 0 then return
  targetIndex = 0
  if m.lastFocusedProgramIndex <> invalid then targetIndex = m.lastFocusedProgramIndex
  if targetIndex >= m.viewAllGridItems.count() then targetIndex = 0
  m.posterGrid.visible = true
  m.posterGrid.jumpToItem = targetIndex
  m.posterGrid.setFocus(true)
end sub

' Bloque grilla nativa: calcula columnas/filas visibles para evitar que PosterGrid quede como una sola fila.
sub __configurePosterGridLayout(totalItems as integer)
  if m.posterGrid = invalid or m.scaleInfo = invalid then return

  itemSize = m.posterGrid.itemSize
  itemSpacing = m.posterGrid.itemSpacing
  if itemSize = invalid or itemSize.count() < 2 then return

  spacingX = 0
  spacingY = 0
  if itemSpacing <> invalid and itemSpacing.count() > 0 then spacingX = itemSpacing[0]
  if itemSpacing <> invalid and itemSpacing.count() > 1 then spacingY = itemSpacing[1]

  gridX = m.posterGrid.translation[0]
  gridY = m.posterGrid.translation[1]
  ' Bloque grilla nativa: extendemos la grilla hasta el borde derecho visual con margen mínimo.
  availableWidth = m.scaleInfo.width - gridX - scaleValue(10, m.scaleInfo)
  availableHeight = scaleValue(500, m.scaleInfo)
  itemWidthWithSpacing = itemSize[0] + spacingX
  itemHeightWithSpacing = itemSize[1] + spacingY

  columns = 1
  if itemWidthWithSpacing > 0 then columns = Int((availableWidth + spacingX) / itemWidthWithSpacing)
  if columns < 1 then columns = 1
  if totalItems > 0 and columns > totalItems then columns = totalItems

  visibleRows = 2

  if itemHeightWithSpacing > 0 then visibleRows = Int((availableHeight + spacingY) / itemHeightWithSpacing)
  if visibleRows < 1 then visibleRows = 1

  if totalItems > 0 then
    totalRows = Int((totalItems + columns - 1) / columns)
    if visibleRows > totalRows then visibleRows = totalRows
    ' MarkupGrid se comporta como carrusel horizontal cuando numRows queda en 1.
    ' Si hay más de una fila de contenido, forzamos al menos 2 filas para mantener navegación/scroll de grilla.
    if visibleRows = 1 and totalRows > 1 then visibleRows = 2
  end if

  m.posterGrid.numColumns = columns
  m.posterGrid.numRows = visibleRows
end sub

' Evalúa si el payload trae contentViewId utilizable.
function __hasValidContentViewId() as boolean
  ' Validamos existencia del campo contentViewId.
  if m.viewAllPayload = invalid or m.viewAllPayload.contentViewId = invalid then return false
  ' Normalizamos el valor recibido para evitar espacios.
  contentViewId = m.viewAllPayload.contentViewId.toStr().trim()
  ' Consideramos válido solo cuando el string no está vacío.
  return contentViewId <> ""
end function

' Solicita el detalle del carrusel seleccionado en la vista "Ver todos".
sub __getViewAllCarousel()
   ' Validamos carouselId porque es requerido en ambos flujos de servicio.
  if m.viewAllPayload = invalid then return
  if m.viewAllPayload.carouselId = invalid then return
  ' Obtenemos API base si aún no está cacheada.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Abortamos si no hay URL de API disponible.
  if m.apiUrl = invalid then return
  ' Mostramos loading durante la llamada.
  if m.top.loading <> invalid and not m.top.loading.visible then m.top.loading.visible = true
  ' Resolvemos configuración del request para reutilizar lógica entre ViewAll y SearchById.
  requestConfig = __getViewAllRequestConfig()
  ' Cortamos si no se pudo construir la configuración del servicio.
  if requestConfig = invalid then return
  ' Creamos id único para registrar acción pendiente.
  requestId = createRequestId()
  action = {
    node: m.top
    apiRequestManager: m.apiRequestManager
    url: requestConfig.url
    method: requestConfig.method
    responseMethod: "onViewAllCarouselResponse"
    body: requestConfig.body
    token: invalid
    publicApi: false
    methodName: "__getViewAllCarousel"
    parameter: invalid
    requestId: requestId
    dataAux: FormatJson(m.viewAllPayload)
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }
  ' Registramos y ejecutamos acción con mecanismo de retry.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  m.apiRequestManager = action.apiRequestManager
end sub

' Construye la configuración HTTP reutilizable según el payload.
function __getViewAllRequestConfig() as Object
  ' Si llega contentViewId válido, priorizamos el flujo SearchById.
  if __hasValidContentViewId() then return {
    url: urlSearchById(m.viewAllPayload.carouselId)
    method: "POST"
    body: __buildSearchBody(m.viewAllPayload.contentViewId)
  }
  ' Evitamos llamar ViewAll tradicional sin menuSelectedItemId.
  if m.viewAllPayload.menuSelectedItemId = invalid then return invalid
  ' Mantenemos el flujo original para ViewAll cuando no aplica SearchById.
  return {
    url: urlViewAllCarousels(m.viewAllPayload.menuSelectedItemId, m.viewAllPayload.carouselId)
    method: "GET"
    body: invalid
  }
end function

' Normaliza la colección de carruseles soportando data.carousels o data.items.
function __getViewAllSourceItems(data as Dynamic) as Object
  sourceItems = []
  ' Priorizamos data.carousels cuando ya viene como lista de carruseles.
  if data <> invalid and data.carousels <> invalid and data.carousels.count() > 0 and data.carousels[0] <> invalid and data.carousels[0].style <> invalid then sourceItems = data.carousels
  ' Usamos data.items cuando expone la misma estructura bajo otro campo.
  if sourceItems.count() = 0 and data <> invalid and data.items <> invalid and data.items.count() > 0 and data.items[0] <> invalid and data.items[0].style <> invalid then sourceItems = data.items
  ' Detectamos payload envuelto donde data representa un único carrusel.
  if sourceItems.count() = 0 and data <> invalid and data.style <> invalid then
    ' Mantenemos compatibilidad con envoltura basada en data.carousels.
    if data.carousels <> invalid and data.carousels.count() > 0 then sourceItems = [data]
    ' Mantenemos compatibilidad con envoltura basada en data.items.
    if sourceItems.count() = 0 and data.items <> invalid and data.items.count() > 0 then sourceItems = [data]
  end if
  ' Devolvemos siempre una lista para evitar chequeos duplicados.
  return sourceItems
end function

' Guarda referencia del último carrusel enfocado para restaurar foco tras errores.
sub __markLastFocus()
  ' Persistimos nodo enfocado actual.
  if m.posterGrid <> invalid then m.lastFocusedProgramIndex = m.posterGrid.itemFocused
end sub

' Bloque grilla nativa: crea y configura el PosterGrid inferior usando los items normalizados de ViewAll.
sub __populateViewAllCarousel(data as Object)
  if m.posterGrid = invalid then return
  ' Limpiamos contenido previo antes de repintar la grilla.
  __clearViewAllCarousel()
  __applyCarouselTitle()
  sourceItems = __getViewAllSourceItems(data)
  if m.viewAllCarouselStyle = invalid and sourceItems.count() > 0 and sourceItems[0] <> invalid and sourceItems[0].style <> invalid then m.viewAllCarouselStyle = sourceItems[0].style
  if m.carouselTitle <> invalid and m.carouselTitle.text = "" and sourceItems.count() > 0 and sourceItems[0] <> invalid and sourceItems[0].title <> invalid then
    m.carouselTitle.text = sourceItems[0].title.toStr().trim()
    m.carouselTitle.visible = m.carouselTitle.text <> ""
  end if
  m.posterGrid.itemSize = __applyPosterGridItemLayout(m.viewAllCarouselStyle)
  contentRoot = createObject("roSGNode", "ContentNode")
  gridItems = []
  startTime = CreateObject("roDateTime")
  endTime = CreateObject("roDateTime")
  ' Bloque de normalización: aplanamos todos los carruseles recibidos en una sola grilla PosterGrid.
  for each carouselData in sourceItems
    if carouselData = invalid then continue for
    if m.viewAllCarouselStyle = invalid and carouselData.style <> invalid then m.viewAllCarouselStyle = carouselData.style
    if carouselData.imageType <> invalid then m.viewAllImageType = carouselData.imageType
    if carouselData.items = invalid then continue for
    for each item in carouselData.items
      if item = invalid then continue for
      gridItem = {
        title: item.title
        key: item.key
        id: item.id
        redirectKey: item.redirectKey
        redirectId: item.redirectId
        parentalControl: item.parentalControl
      }
      gridItems.push(gridItem)
      child = contentRoot.createChild("ContentNode")
      child.title = item.title
      itemDate = ""
      if item.endTime <> invalid then
        endTime.FromISO8601String(item.endTime)
        endTime.ToLocalTime()

        if item.startTime <> invalid then
          startTime.FromISO8601String(item.startTime)
          startTime.ToLocalTime()
          itemDate = dateConverter(startTime, i18n_t(m.global.i18n, "time.formatHours")) + " - " + dateConverter(endTime, i18n_t(m.global.i18n, "time.formatHours"))
        end if
      end if
      itemCategory = ""
      if item.category <> invalid then itemCategory = item.category
      itemPercentageElapsed = 0
      if item.percentageElapsed <> invalid then itemPercentageElapsed = item.percentageElapsed
      child.addFields({
        imageURL: getImageUrl(item.image)
        size: m.posterGrid.itemSize
        style: m.viewAllCarouselStyle
        contentType: carouselData.contentType
        category: itemCategory
        date: itemDate
        percentageElapsed: itemPercentageElapsed
      })
    end for
  end for
  m.viewAllGridItems = gridItems
  ' Bloque layout dinámico: ajustamos columnas y filas visibles según el ancho disponible y cantidad de items.
  __configurePosterGridLayout(gridItems.count())
  m.posterGrid.content = contentRoot
  m.posterGrid.ObserveField("itemFocused", "onFocusItem")
  m.posterGrid.ObserveField("itemSelected", "onSelectItem")
  m.posterGrid.visible = gridItems.count() > 0
  if gridItems.count() > 0 and m.top.onFocus then __focusPosterGrid()
end sub

' Guardar el log cuandos se cambia una opción del menú
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and getEnableLogs() then
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogsToken(), "GET", "onActionLogTokenResponse", invalid, invalid, invalid, false, FormatJson(actionLog))
  else
      __sendActionLog(actionLog)
  end if
end sub

' Restaura foco del carrusel previamente guardado cuando una acción falla.
sub __restoreLastFocus()
  ' Devolvemos foco al último carrusel recordado.
  __focusPosterGrid()
end sub


' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid)
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogs(), "POST", "onActionLogResponse", invalid, FormatJson(actionLog), beaconToken, false)
  end if
end sub

' Reutiliza validación de errores estándar para resolver logout cuando aplica.
sub __validateError(statusCode as integer)
  ' Si el error implica logout, delegamos y detenemos el flujo local.
  if validateLogout(statusCode, m.top) then return
end sub