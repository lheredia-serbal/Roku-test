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
  ' Referencia al contenedor donde vive el carrusel de ViewAll.
  m.carouselContainer = m.top.findNode("carouselContainer")
  ' Referencia al indicador de selección del carrusel.
  m.selectedIndicator = m.top.findNode("selectedIndicator")
  ' Cacheamos último foco para restaurarlo tras errores de red/validación.
  m.lastFocusedProgram = invalid
end sub

' Maneja la lógica de foco para la pantalla.
sub initFocus()
  ' Siempre que ViewAll vuelva a estar visible, reposicionamos foco al primer item del primer carrusel.
  if m.top.onFocus then __focusFirstCarousel()
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
  if m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.imageType <> invalid and m.carouselContainer.focusedChild.imageType <> 0 then 
    mainImageTypeId = m.carouselContainer.focusedChild.imageType.ToStr()
  end if 
  ' Generamos identificador de acción para retry tracking.
  requestId = createRequestId() 
  action = { 
    apiSummaryRequestManager: m.apiSummaryRequestManager
    url: urlProgramSummary(m.apiUrl, m.itemfocused.redirectKey, m.itemfocused.redirectId, mainImageTypeId, getCarouselImagesTypes().SCENIC_LANDSCAPE)
    method: "GET" 
    responseMethod: "onProgramSummaryResponse"
    body: invalid 
    token: invalid 
    publicApi: false
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
  if m.top.data = invalid or m.top.data = "" then return
  payload = ParseJson(m.top.data)
  if payload = invalid then return
  m.viewAllPayload = payload
  __applyLayout()
  ' Disparamos el consumo del servicio de ViewAll.
  __getViewAllCarousel() 

  ' Guardamos el log de ingreso
  actionLog = getActionLog({
    actionCode: ActionLogCode().OPEN_PAGE,
    pageUrl: "View All"
  })

  __saveActionLog(actionLog)
end sub

' Reacciona al foco de un item del carrusel y prepara solicitud de Program Summary.
sub onFocusItem()
  ' Validamos que el foco pertenezca al carrusel activo.
  if m.carouselContainer = invalid or not m.carouselContainer.isInFocusChain() then return 
  ' Validamos que exista carrusel enfocado.
  if m.carouselContainer.focusedChild = invalid then return 
  newFocus = ParseJson(m.carouselContainer.focusedChild.focused)
  if newFocus = invalid then return
  ' Evitamos llamadas duplicadas para el mismo item.
  if m.itemfocused = invalid or (newFocus.key <> m.itemfocused.key or newFocus.id <> m.itemfocused.id or newFocus.redirectKey <> m.itemfocused.redirectKey or newFocus.redirectId <> m.itemfocused.redirectId) then 
    ' Ocultamos summary mientras se carga el nuevo programa.
    m.programInfo.visible = false 
    ' Limpiamos fondo para evitar mostrar data vieja.
    m.programImageBackground.uri = "" 
    ' Guardamos item enfocado que se usará en la consulta.
    m.itemfocused = newFocus 
    m.carouselContainer.focusedChild.focused = invalid
    clearTimer(m.programTimer)
    m.programTimer.ObserveField("fire", "getProgramInfo")
    m.programTimer.control = "start"
  end if
end sub

' Procesa navegación vertical para mover foco entre filas de carruseles en ViewAll.
function onKeyEvent(key as string, press as boolean) as boolean
  handled = false
  if key = KeyButtons().UP then
    ' Validamos que exista una fila superior navegable.
    if press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.focusUp <> invalid then 
      ' Obtenemos la lista interna del carrusel de arriba para transferir foco.
      focusItem = m.carouselContainer.focusedChild.focusUp.findNode("carouselList") 
      ' Confirmamos que la lista destino sea válida.
      if focusItem <> invalid then 
        ' Aseguramos visibilidad completa del carrusel destino antes de enfocar.
        m.carouselContainer.focusedChild.focusUp.opacity = "1.0" 
        ' Movemos el foco real al carrusel superior.
        focusItem.setFocus(true) 
        ' Ajustamos desplazamiento del contenedor para mantener visible la fila enfocada.
        m.carouselContainer.translation = [0, -(m.carouselContainer.focusedChild.translation[1] - m.yPosition)] 
        ' Sincronizamos el indicador con el tamaño del carrusel recién enfocado.
        m.selectedIndicator.size = m.carouselContainer.focusedChild.size 
      end if
    end if
    handled = true 
  else if key = KeyButtons().DOWN then
    ' Validamos que exista una fila inferior navegable.
    if press and m.carouselContainer <> invalid and m.carouselContainer.isInFocusChain() and m.carouselContainer.focusedChild <> invalid and m.carouselContainer.focusedChild.focusDown <> invalid then
      ' Obtenemos la lista interna del carrusel de abajo para transferir foco.
      focusItem = m.carouselContainer.focusedChild.focusDown.findNode("carouselList") 
      ' Confirmamos que la lista destino sea válida.
      if focusItem <> invalid then 
        ' Atenuamos la fila saliente para evitar superposición visual durante el desplazamiento.
        m.carouselContainer.focusedChild.opacity = "0.0" 
        ' Movemos el foco real al carrusel inferior.
        focusItem.setFocus(true) 
        ' Ajustamos desplazamiento del contenedor para mantener visible la fila enfocada.
        m.carouselContainer.translation = [0, -(m.carouselContainer.focusedChild.translation[1] - m.yPosition)] 
        ' Sincronizamos el indicador con el tamaño del carrusel recién enfocado.
        m.selectedIndicator.size = m.carouselContainer.focusedChild.size 
      end if
    end if
    handled = true
  end if
  return handled
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
      if m.carouselContainer <> invalid and m.carouselContainer.focusedChild <> invalid then 
        m.carouselContainer.focusedChild.updateNode = FormatJson(m.program) 
      end if
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

' Toma la selección del item enfocado y decide si abre Player o Detalle, igual que MainScreen.
sub onSelectItem()
  ' Validamos que exista un carrusel activo con foco.
  if m.carouselContainer = invalid or not m.carouselContainer.isInFocusChain() or m.carouselContainer.focusedChild = invalid then return 
  ' Leemos payload del item seleccionado desde Carousel.
  m.itemSelected = ParseJson(m.carouselContainer.focusedChild.selected) 
  ' Limpiamos el campo selected para evitar reprocesar la misma selección.
  m.carouselContainer.focusedChild.selected = invalid 
  ' Cortamos si el payload no pudo parsearse
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
        apiRequestManager: m.apiRequestManager
        url: urlWatchValidate(m.apiUrl, watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
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
      ' Ejecutamos acción con retries centralizados.
      runAction(requestId, action, ApiType().CLIENTS_API_URL)
      m.apiRequestManager = action.apiRequestManager
    else
      ' Limpiamos cualquier request pendiente antes de navegar a detalle.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Emitimos detalle para que MainScene abra ProgramDetailScreen.
      m.top.detail = FormatJson(m.itemSelected) 
      ' Ocultamos loading porque la navegación ya fue emitida.
      if m.top.loading <> invalid then m.top.loading.visible = false
    end if
  end if
end sub

' Procesa callback del modal PIN reutilizando lógica de MainScreen.
sub onPinDialogLoad()
  ' Leo respuesta del PIN ingresado por el usuario.
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  ' Creo requestId para la validación del PIN.
  requestId = createRequestId()
  ' Si se confirma botón OK con PIN de 4 dígitos, valido contra backend.
  if (resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4) then 
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
      run: function() as object
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

' Procesa la respuesta de la validacion del PIN
sub onParentalControlResponse()
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
          apiRequestManager: m.apiRequestManager
          url: urlWatchValidate(m.apiUrl, watchSessionId, m.itemSelected.redirectKey, m.itemSelected.redirectId)
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
          
          runAction(requestId, action, ApiType().CLIENTS_API_URL)
          m.apiRequestManager = action.apiRequestManager
        else
          m.top.loading.visible = false
          __markLastFocus() 
          m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onDialogClosedFocusContainer")
      end if
    else     
      m.top.loading.visible = false
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

  option = clearDialogAndGetOption(m.top, m.dialog)
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
         ' Ocultamos loading al no recibir data reproducible.
        if m.top.loading <> invalid then m.top.loading.visible = false
         ' Devolvemos foco al elemento previo para continuidad de UX.
        __restoreLastFocus()
        printError("Streamings Empty ViewAll:", m.apiRequestManager.response)
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      end if
    else
      if m.top.loading <> invalid then m.top.loading.visible = false
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
    viewAllItems = invalid 
    ' Priorizamos data.carousels cuando viene en la respuesta.
    if resp <> invalid and resp.data <> invalid and resp.data.carousels <> invalid and resp.data.carousels.count() > 0 then viewAllItems = resp.data.carousels 
    ' Usamos data.items como fallback cuando carousels no existe.
    if viewAllItems = invalid and resp <> invalid and resp.data <> invalid and resp.data.items <> invalid and resp.data.items.count() > 0 then viewAllItems = resp.data.items 
    ' Reutilizamos la misma lógica de resolución para evitar duplicación.
    viewAllItems = __getViewAllSourceItems(resp.data) 
    ' Validamos que exista una colección de items para pintar.
    if viewAllItems.count() > 0 then 
      m.carousel = resp.data
      ' Renderizamos carrusel con datos de ViewAll.
      __populateViewAllCarousel(resp.data) 
    else
      ' Limpiamos UI cuando la API no trae items.
      __clearViewAllCarousel() 
    end if
  else
    error = m.apiRequestManager.errorResponse
    statusCode = m.apiRequestManager.statusCode
    if m.apiRequestManager.serverError then
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      ' Limpiamos acción pendiente no reintentable.
      removePendingAction(m.apiRequestManager.requestId) 
      printError("ViewAllCarousel:", error)

      ' Guardar el log de Error
      actionLog = createLogError(generateErrorDescription(error), generateErrorPageUrl("getCarousel", "ViewAllComponent"), getServerErrorStack(error))
      __saveActionLog(actionLog)

      ' Validamos si el error requiere forzar logout.
      if validateLogout(statusCode, m.top) then 
        m.apiRequestManager = clearApiRequest(m.apiRequestManager)
        if m.top.loading <> invalid then m.top.loading.visible = false
        return
      end if
    end if
  end if
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  if m.top.loading <> invalid then m.top.loading.visible = false
end sub

' Procesa la respuesta de WatchValidate para decidir si continúa a streaming, igual que MainScreen.
sub onWatchValidateResponse()
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
        ' Actualizamos watchSessionId vigente.
        setWatchSessionId(resp.watchSessionId) 
        ' Actualizamos watchToken vigente.
        setWatchToken(resp.watchToken) 
        if m.itemSelected <> invalid then
          ' Solicitamos streaming del item canal seleccionado.
          m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.itemSelected.redirectKey, m.itemSelected.redirectId), "GET", "onStreamingsResponse") 
        end if
      else
        ' Ocultamos loading porque no se podrá reproducir.
        if m.top.loading <> invalid then m.top.loading.visible = false 
        ' Limpiamos request manager al cortar el flujo.
        m.apiRequestManager = clearApiRequest(m.apiRequestManager) 
        ' Reutilizamos manejo de errores funcionales de MainScreen.
        __validateError(0) 
        printError("WatchValidate ResultCode ViewAll:", resp.resultCode)
      end if
    else
      ' Ocultamos loading por error HTTP.
      if m.top.loading <> invalid then m.top.loading.visible = false 
      statusCode = m.apiRequestManager.statusCode
      errorResponse = m.apiRequestManager.errorResponse
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Delegamos el handling de error común.
      __validateError(statusCode) 
      printError("WatchValidate Status ViewAll:", statusCode.toStr() + " " + errorResponse)
    end if
  end if
end sub

' Restaura foco al último carrusel activo (o al primero disponible) al volver a ViewAll.
sub restoreFocus()
  if m.carouselContainer = invalid then return ' Evitamos operar si el contenedor todavía no está listo.

  targetCarousel = invalid 
  ' Priorizamos el último carrusel usado antes de salir.
  if m.lastFocusedProgram <> invalid then targetCarousel = m.lastFocusedProgram 
  ' Fallback al carrusel que conserve foco interno.
  if targetCarousel = invalid and m.carouselContainer.focusedChild <> invalid then targetCarousel = m.carouselContainer.focusedChild
  ' Último fallback: primer carrusel renderizado.
  if targetCarousel = invalid and m.carouselContainer.getChildCount() > 0 then targetCarousel = m.carouselContainer.getChild(0) 
  if targetCarousel = invalid then return 

  ' Buscamos la lista interna que realmente recibe eventos de control remoto.
  focusItem = targetCarousel.findNode("carouselList")
  ' Cortamos si no existe lista para enfocar.
  if focusItem = invalid then return 

  ' Garantizamos que la fila objetivo quede visible al restaurar foco.
  targetCarousel.opacity = "1.0" 
  focusItem.setFocus(true)
  m.selectedIndicator.size = targetCarousel.size 
  m.selectedIndicator.visible = true
  ' Reposicionamos contenedor para dejar visible la fila recuperada.
  m.carouselContainer.translation = [0, -(targetCarousel.translation[1] - m.yPosition)] 
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
  m.programInfo.translation = [safeX + scaleValue(60, m.scaleInfo), safeY ]
  ' Aplicamos posición inicial del bloque de carruseles usando los valores cacheados.
  m.carouselContainer.translation = [0, m.yPosition] 
  m.selectedIndicator.translation = [safeX + scaleValue(5, m.scaleInfo), safeY + scaleValue(148, m.scaleInfo)]
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

' Limpia el carrusel actual de ViewAll y resetea estado visual asociado.
sub __clearViewAllCarousel()
  if m.carouselContainer = invalid then return
  while m.carouselContainer.getChildCount() > 0 
    child = m.carouselContainer.getChild(0)
    child.unobserveField("focused")
    child.unobserveField("selected")
    m.carouselContainer.removeChild(child)
  end while
  ' Ocultamos indicador al no existir carrusel renderizado.
  m.selectedIndicator.visible = false 
   ' Ocultamos summary al limpiar contenido.
  m.programInfo.visible = false
  ' Limpiamos imagen de fondo del programa previo.
  m.programImageBackground.uri = "" 
end sub

' Carga la configuracion inicial de la ViewAll.
sub __configMain()
  m.programInfo.width = (m.scaleInfo.width - scaleValue(300, m.scaleInfo))
  m.programInfo.initConfig = true
end sub

' Posiciona el foco en el primer item del primer carrusel y resetea el desplazamiento vertical.
sub __focusFirstCarousel()
  ' Salimos si todavía no hay carruseles renderizados.
  if m.carouselContainer = invalid or m.carouselContainer.getChildCount() = 0 then return 

  ' Tomamos el primer carrusel del listado.
  firstCarousel = m.carouselContainer.getChild(0) 
  if firstCarousel = invalid then return

  ' Obtenemos la lista interna para controlar el item enfocado.
  firstList = firstCarousel.findNode("carouselList") 
  if firstList = invalid then return

  ' Forzamos el foco sobre el primer item del carrusel.
  firstList.jumpToItem = 0 
  ' Garantizamos que la fila inicial quede completamente visible.
  firstCarousel.opacity = "1.0" 
  ' Aplicamos foco real al carrusel inicial.
  firstList.setFocus(true) 
  ' Sincronizamos indicador con la primera fila.
  m.selectedIndicator.size = firstCarousel.size 
  ' Mostramos indicador al tener foco activo.
  m.selectedIndicator.visible = true 
  ' Restauramos el contenedor a su posición inicial al reingresar.
  m.carouselContainer.translation = [0, m.yPosition]
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

' Devuelve la cantidad máxima de ítems por fila según el estilo del carrusel.
function __getMaxItemsPerRow(style as integer) as integer
  if style = getCarouselStyles().PORTRAIT_FEATURED then return 6
  if style = getCarouselStyles().LANDSCAPE_STANDARD then return 5
  if style = getCarouselStyles().LANDSCAPE_FEATURED then return 4
  if style = getCarouselStyles().SQUARE_STANDARD then return 10
  if style = getCarouselStyles().SQUARE_FEATURED then return 6
  if style = -1 then return 12 
  return 8
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
    apiRequestManager: m.apiRequestManager
    url: requestConfig.url
    method: requestConfig.method
    responseMethod: "onViewAllCarouselResponse"
    body: requestConfig.body
    token: invalid
    publicApi: false
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
    url: urlSearchById(m.apiUrl, m.viewAllPayload.carouselId) 
    method: "POST"
    body: __buildSearchBody(m.viewAllPayload.contentViewId)
  }
  ' Evitamos llamar ViewAll tradicional sin menuSelectedItemId.
  if m.viewAllPayload.menuSelectedItemId = invalid then return invalid 
  ' Mantenemos el flujo original para ViewAll cuando no aplica SearchById.
  return { 
    url: urlViewAllCarousels(m.apiUrl, m.viewAllPayload.menuSelectedItemId, m.viewAllPayload.carouselId) 
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
  if m.carouselContainer <> invalid then m.lastFocusedProgram = m.carouselContainer.focusedChild 
end sub

' Crea y configura el listado de carruseles inferior usando un flujo equivalente a populateCarousels de MainScreen.
sub __populateViewAllCarousel(data as Object)
  if m.carouselContainer = invalid then return
  yPosition = 0
  previousCarousel = invalid
  ' Limpiamos carruseles previos antes de repintar contenido.
  __clearViewAllCarousel() 
  ' Reutilizamos la misma normalización de estructura para carousels/items.
  sourceItems = __getViewAllSourceItems(data) 
  ' Recorremos cada carrusel para crearlo igual que MainScreen.
  for each carouselData in sourceItems 
    ' Calculamos cuántos ítems entran en pantalla sin scroll horizontal.
    itemsPerRow = __getMaxItemsPerRow(carouselData.style) 
    ' Inicializamos índice de fila para distribuir items de izquierda a derecha y luego hacia abajo.
    rowIndex = 0 
    ' Inicializamos cursor para particionar items del carrusel en filas.
    startIndex = 0 
    ' Particionamos items del carrusel para evitar scroll lateral.
    while carouselData.items <> invalid and startIndex < carouselData.items.count() 
      rowItems = []
      ' Definimos límite superior de la fila actual.
      endExclusive = startIndex + itemsPerRow 
      ' Ajustamos límite al total disponible.
      if endExclusive > carouselData.items.count() then endExclusive = carouselData.items.count() 
      ' Copiamos items de esta fila.
      for i = startIndex to endExclusive - 1
        rowItems.push(carouselData.items[i])
      end for

      ' Creamos una instancia del componente Carousel.
      newCarousel = m.carouselContainer.createChild("Carousel") 
      ' Inicializamos id base para evitar colisiones entre filas generadas.
      carouselRowId = 0 
      ' Reservamos bloque de ids por carrusel para cada fila.
      if carouselData.id <> invalid then carouselRowId = carouselData.id * 1000 
      ' Asignamos id único por fila derivado del carrusel original.
      newCarousel.id = carouselRowId + rowIndex 
      newCarousel.contentType = carouselData.contentType
      newCarousel.style = carouselData.style
      ' Mostramos título sólo en la primera fila.
      if rowIndex = 0 then newCarousel.title = carouselData.title else newCarousel.title = "" 
      ' Construimos tags sólo para la primera fila donde se renderiza el título del carrusel.
      if rowIndex = 0 then newCarousel.titleTagsText = __buildCarouselTitleTagsText(carouselData.titleTags) else newCarousel.titleTagsText = "" 
      newCarousel.code = carouselData.code
      newCarousel.imageType = carouselData.imageType
      newCarousel.redirectType = carouselData.redirectType
      newCarousel.items = rowItems
      ' Posicionamos carrusel en eje Y acumulado.
      newCarousel.translation = [0, yPosition] 
      newCarousel.ObserveField("focused", "onFocusItem")
      newCarousel.ObserveField("selected", "onSelectItem")
       ' Enlazamos foco hacia abajo desde carrusel anterior.
      if previousCarousel <> invalid then previousCarousel.focusDown = newCarousel
      ' Enlazamos foco hacia arriba hacia carrusel anterior.
      if previousCarousel <> invalid then newCarousel.focusUp = previousCarousel 
      ' Actualizamos referencia para la próxima iteración.
      previousCarousel = newCarousel 
      ' Avanzamos separación vertical como en MainScreen.
      yPosition = yPosition + newCarousel.height + scaleValue(20, m.scaleInfo) 

      ' Avanzamos a la siguiente fila visual.
      rowIndex = rowIndex + 1 
      ' Continuamos con los siguientes items del carrusel.
      startIndex = endExclusive 
    end while
  end for
  if m.carouselContainer.getChildCount() > 0 then
    ' Si la pantalla está visible, forzamos foco al primer item del primer carrusel.
    if m.top.onFocus then __focusFirstCarousel() 
  else
    ' Ocultamos indicador cuando no hay carruseles válidos.
    m.selectedIndicator.visible = false 
  end if
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogsToken(m.apiUrl), "GET", "onActionLogTokenResponse", invalid, invalid, invalid, false, FormatJson(actionLog))
  else
      __sendActionLog(actionLog)
  end if
end sub

' Restaura foco del carrusel previamente guardado cuando una acción falla.
sub __restoreLastFocus()
  ' Devolvemos foco al último carrusel recordado.
  if m.lastFocusedProgram <> invalid then m.lastFocusedProgram.setFocus(true) 
end sub


' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    m.apiLogRequestManager = sendApiRequest(m.apiLogRequestManager, urlActionLogs(m.beaconUrl), "POST", "onActionLogResponse", invalid, FormatJson(actionLog), beaconToken, false)
  end if
end sub

' Reutiliza validación de errores estándar para resolver logout cuando aplica.
sub __validateError(statusCode as integer)
  ' Si el error implica logout, delegamos y detenemos el flujo local.
  if validateLogout(statusCode, m.top) then return 
end sub