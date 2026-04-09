' Inicialización del componente Emissions.
sub init()
  ' Guarda última key recibida para reintento de request.
  m.lastKey = invalid
  ' Guarda último id recibido para reintento de request.
  m.lastId = invalid
    ' Inicializa manager de requests para evitar referencias inválidas.
  m.apiRequestManager = invalid
  ' Referencia al título principal de la pantalla.
  m.emissionsTitle = m.top.findNode("emissionsTitle")
  ' Guarda referencia de la lista visual de episodios.
  m.episodesList = m.top.findNode("episodesList")
  ' Guarda referencia del viewport que recorta la lista bajo el título.
  m.episodesViewport = m.top.findNode("episodesViewport")
  ' Guarda referencia del indicador de selección fijo.
  m.selectedIndicator = m.top.findNode("selectedIndicator")
  ' Cachea el ancho fijo del indicador para reutilizarlo al recalcular su alto dinámico.
  m.selectedIndicatorWidth = scaleValue(1100, m.scaleInfo)
  ' Cachea alto fallback del indicador para usarlo cuando no se pueda medir el EpisodeItem.
  m.selectedIndicatorFallbackHeight = scaleValue(237, m.scaleInfo)
  m.episodesMoveAnimation = m.top.findNode("episodesMoveAnimation")
  m.episodesMoveInterpolator = m.top.findNode("episodesMoveInterpolator")
  ' Índice lógico del episodio actualmente enfocado por la selección.
  m.selectedEpisodeIndex = 0
  ' Alto del separador para incluirlo en el desplazamiento vertical.
  m.episodeSeparatorHeight = 1
  ' Cantidad de episodios renderizados para navegación vertical.
  m.episodesCount = 0
  ' Cachea episodios crudos para resolver selección y abrir player con redirectKey/redirectId.
  m.episodesData = []
  ' Guarda episodio seleccionado para reutilizarlo en watchValidate/streaming.
  m.selectedEpisode = invalid
    ' Guarda referencia del PIN modal para validar control parental antes de reproducir.
  m.pinDialog = invalid
  ' Guarda referencia del diálogo de error para informar PIN inválido.
  m.dialog = invalid
  ' Obtiene scaleInfo global para escalar medidas y posiciones del layout.
  m.scaleInfo = m.global.scaleInfo
  ' Intenta resolver loading desde la escena cuando no viene inyectado.
  if m.top <> invalid and m.top.loading = invalid then
    scene = m.top.getScene()
    if scene <> invalid then m.top.loading = scene.findNode("Loading")
  end if

    ' Inicializa ancho de pantalla con fallback a resolución base.
  m.screenWidth = 1280
  ' Marca si scaleInfo global pudo proveer un ancho válido.
  hasScaleWidth = false
  ' Prioriza ancho calculado por scaleInfo global cuando está disponible.
  if m.global <> invalid and m.global.scaleInfo <> invalid and m.global.scaleInfo.width <> invalid then
    ' Guarda ancho de pantalla reportado por scaleInfo global.
    m.screenWidth = m.global.scaleInfo.width
    ' Indica que ya existe ancho válido proveniente de scaleInfo.
    hasScaleWidth = true
  end if
  ' Usa ancho real de display cuando no existe scaleInfo global.
  if not hasScaleWidth then m.screenWidth = CreateObject("roDeviceInfo").GetDisplaySize().w
  ' Crea scaleInfo de fallback cuando aún no está disponible en globals.
  if m.scaleInfo = invalid then m.scaleInfo = getScaleInfo(CreateObject("roDeviceInfo"))
  ' Aplica tamaños y posiciones escaladas para todos los nodos de emisiones.
  __applyScaledLayout()
end sub

' Aplica medidas escaladas a width y height de los nodos visuales.
sub __applyScaledLayout()
  ' Evita aplicar layout cuando no existe información de escala.
  if m.scaleInfo = invalid then return
  ' Escala ancho del título para respetar resolución del dispositivo.
  ' Escala posición y tamaño de la lista de episodios.

  if m.emissionsTitle <> invalid then
    m.emissionsTitle.translation = scaleSize([80, 40], m.scaleInfo)
  end if

if m.episodesViewport <> invalid and m.episodesList <> invalid then
    ' Calcula el tamaño del viewport que recorta visualmente la lista.
    episodesViewportWidth = scaleValue(1600, m.scaleInfo)
    ' Calcula altura visible de episodios para evitar superposición con el título.
    episodesViewportHeight = scaleValue(860, m.scaleInfo)
    ' Posiciona viewport debajo del título para fijar el área visible.
    m.episodesViewport.translation = scaleSize([80, 100], m.scaleInfo)
    ' Recorta el contenido de episodios al rectángulo visible del viewport.
    m.episodesViewport.clippingRect = [0, 0, episodesViewportWidth, episodesViewportHeight]
    ' Reinicia posición de lista dentro del viewport sin desplazar el viewport.
    __setEpisodesListTranslation([0, 0], false)
  end if

if m.selectedIndicator <> invalid then
    m.selectedIndicator.translation = scaleSize([80, 0], m.scaleInfo)
    ' Actualiza ancho cacheado con el valor escalado vigente para mantener consistencia visual.
    m.selectedIndicatorWidth = scaleValue(1100, m.scaleInfo)
    ' Actualiza alto fallback cacheado con el valor escalado vigente para mantener consistencia visual.
    m.selectedIndicatorFallbackHeight = scaleValue(237, m.scaleInfo)
    ' Mantiene tamaño inicial del indicador antes de poder medir el EpisodeItem enfocado.
    m.selectedIndicator.size = [m.selectedIndicatorWidth, m.selectedIndicatorFallbackHeight]
  end if
end sub


' Maneja foco de pantalla al mostrarse.
sub initFocus()
  ' No requiere comportamiento adicional al tomar foco.
end sub

' Procesa payload de entrada y dispara servicio de episodios.
sub initData()
  ' Evita ejecución cuando no hay payload.
  if m.top.data = invalid or m.top.data = "" then return
  ' Resuelve apiUrl reutilizando la misma lógica del resto de pantallas.
  if m.apiUrl = invalid then m.apiUrl = getConfigVariable(m.global.configVariablesKeys.API_URL)
  ' Limpia episodios anteriores antes de una nueva carga.
  __clearEpisodes()
  ' Parsea payload enviado desde ProgramDetail.
  payload = ParseJson(m.top.data)
  ' Evita request si payload es inválido.
  if payload = invalid then return
  ' Valida key requerida para endpoint de episodios.
  if payload.key = invalid then return
  ' Valida id requerido para endpoint de episodios.
  if payload.id = invalid then return
  ' Ejecuta request de episodios con key e id recibidos.
  __getEpisodes(payload.key, payload.id)

  actionLog = getActionLog({
    actionCode: ActionLogCode().OPEN_PAGE,
    pageUrl: "Emissions"
  })

  __saveActionLog(actionLog)
end sub

' Captura eventos de teclado para volver a la pantalla anterior.
function onKeyEvent(key as string, press as boolean) as boolean
  ' Ignora eventos de liberación de tecla.
  if not press then return false

  ' Intercepta BACK para retornar a ProgramDetail.
  if key = KeyButtons().BACK then
    ' Notifica salida hacia MainScene.
    m.top.onBack = true
    ' Marca evento como manejado.
    return true
  end if

  ' Navega episodio anterior manteniendo fijo el SelectionBox.
  if key = KeyButtons().UP then
    return __moveSelection(-1)
  end if

  ' Navega episodio siguiente manteniendo fijo el SelectionBox.
  if key = KeyButtons().DOWN then
    if m.selectedEpisodeIndex + 1 < m.episodesCount then 
      return __moveSelection(1)
    else 
      return true
    end if
  end if

  ' Intercepta OK para abrir Player cuando el episodio seleccionado tiene play habilitado.
  if key = KeyButtons().OK then
    ' Intenta abrir player con el episodio seleccionado y marca la tecla como manejada cuando aplica.
    return __openSelectedEpisode()
  end if

  ' Deja pasar otros eventos al padre.
  return false
end function

' Ejecuta request al servicio urlEpisodes reutilizando runAction.
sub __getEpisodes(key, id)
  ' Guarda parámetros para posibles reintentos.
  m.lastKey = key
  ' Guarda id para posibles reintentos.
  m.lastId = id
  ' Activa loading compartido mientras se consulta API.
  if m.top.loading <> invalid then m.top.loading.visible = true
  ' Crea identificador de acción para retry manager.
  requestId = createRequestId()

  ' Define request siguiendo el patrón existente del proyecto.
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlEpisodes(m.apiUrl, m.lastKey, m.lastId)
    method: "GET"
    responseMethod: "onEpisodesResponse"
    body: invalid
    token: invalid
    publicApi: false
    requestId: requestId
    dataAux: invalid
    run: function() as Object
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
      return { success: true, error: invalid }
    end function
  }

  ' Ejecuta request con soporte de retry global.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  ' Actualiza referencia local del request manager.
  m.apiRequestManager = action.apiRequestManager
end sub

' Procesa respuesta del servicio de episodios.
sub onEpisodesResponse()
  ' Reintenta automáticamente si el manager quedó inválido.
  if m.apiRequestManager = invalid then
    ' Reintenta usando últimos parámetros válidos.
    __getEpisodes(m.lastKey, m.lastId)
    ' Corta ejecución actual.
    return
  end if

  ' Flujo exitoso HTTP.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Convierte respuesta a objeto para renderizar episodios.
    response = ParseJson(m.apiRequestManager.response)
    ' Obtiene arreglo de episodios desde el nodo data.
    episodes = invalid
    ' Prioriza lista dentro de data cuando exista.
    if response <> invalid and response.data <> invalid then episodes = response.data
    ' Soporta respuesta como arreglo directo si aplica.
    if episodes = invalid and type(response) = "roArray" then episodes = response
    ' Renderiza N EpisodeItem según cantidad recibida por servicio.
    __renderEpisodes(episodes.episodes)
    ' Remueve acción pendiente al completar correctamente.
    removePendingAction(m.apiRequestManager.requestId)
    ' Parsea respuesta para mostrar título en pantalla.
    response = ParseJson(m.apiRequestManager.response)
    if m.emissionsTitle <> invalid then
      if response <> invalid and response.data <> invalid and response.data.title <> invalid then
        m.emissionsTitle.text = response.data.title
      else
        m.emissionsTitle.text = ""
      end if
    end if
  else
    ' Obtiene status para decisiones de error.
    statusCode = m.apiRequestManager.statusCode
    ' Obtiene payload de error para logging.
    errorResponse = m.apiRequestManager.errorResponse
    ' Maneja errores de servidor con estrategia global.
    if m.apiRequestManager.serverError then
      setCdnErrorCodeFromStatus(statusCode, ApiType().CLIENTS_API_URL)
      changeStatusAction(m.apiRequestManager.requestId, "error")
      retryAll()
    else
      ' Remueve acción pendiente no reintentable.
      removePendingAction(m.apiRequestManager.requestId)
      ' Loguea error para soporte.
      printError("Episodes:", errorResponse)
      ' Valida si corresponde logout por sesión expirada.
      if validateLogout(statusCode, m.top) then return
    end if
    ' Guardar el log de Error
    actionLog = createLogError(generateErrorDescription(errorResponse), generateErrorPageUrl("getEmissions", "ProgramEmissionsComponent"), getServerErrorStack(errorResponse), m.lastKey, m.lastId)
    __saveActionLog(actionLog)
  end if

  ' Limpia request manager al finalizar.
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)

  ' Oculta loading al finalizar cualquier resultado.
  if m.top.loading <> invalid then m.top.loading.visible = false
end sub


' Crea visualmente los EpisodeItem según la respuesta del servicio.
sub __renderEpisodes(episodes)
  ' Evita render si el contenedor aún no existe.
  if m.episodesList = invalid then return
  ' Limpia elementos previos antes de pintar nuevos episodios.
  __clearEpisodes()
  ' Corta render cuando la respuesta no contiene lista.
  if episodes = invalid then return
  ' Guarda episodios originales para poder abrir player desde selección actual.
  m.episodesData = episodes
  ' Guarda la cantidad real de EpisodeItem para navegación con separadores.
  m.episodesCount = episodes.count()
  ' Recorre episodios para crear un EpisodeItem por cada uno.
  for i = 0 to episodes.count() - 1
    item = episodes[i]
    ' Crea un nuevo componente reusable EpisodeItem.
    newEpisodeItem = m.episodesList.createChild("EpisodeItem")
    ' Asigna ancho al 100% de la pantalla.
    newEpisodeItem.widthContainer = scaleValue(1500, m.scaleInfo)
    ' Pasa el objeto image para que EpisodeItem use getImageUrl internamente.
    if item <> invalid and item.image <> invalid then newEpisodeItem.image = item.image
    ' Pasa synopsis para setearla en episodeSynopsis dentro de EpisodeItem.
    if item <> invalid and item.synopsis <> invalid then newEpisodeItem.synopsis = item.synopsis
    ' Pasa formattedDuration para setearla en episodeTime dentro de EpisodeItem.
    if item <> invalid and item.formattedDuration <> invalid then newEpisodeItem.formattedDuration = item.formattedDuration
    ' Pasa play normalizado para mostrar u ocultar playImage según reglas de negocio.
    newEpisodeItem.play = __resolveEpisodePlay(item)
    ' Pasa título compuesto con fecha, hora y nombre de canal.
    newEpisodeItem.title = __buildEpisodeTitle(item)

    ' Agrega un separador visual entre episodios autogenerados.
    if i < episodes.count() - 1 then
      episodeSeparator = m.episodesList.createChild("Rectangle")
      episodeSeparator.width = scaleValue(1105, m.scaleInfo)
      episodeSeparator.height = scaleValue(1, m.scaleInfo)
      episodeSeparator.color = "0x7F7F7FFF"
    end if
  end for

  ' Define el índice inicial en el último episodio para abrir la pantalla con foco al final.
  initialSelectionIndex = 0
  ' Reemplaza el índice inicial por el último elemento cuando existe al menos un episodio.
  if m.episodesCount > 0 then initialSelectionIndex = m.episodesCount - 1
  ' Aplica selección inicial para ubicar foco lógico e indicador sobre el último episodio.
  __updateSelection(initialSelectionIndex)
end sub

' Intenta abrir player con el episodio seleccionado cuando playImage está visible.
function __openSelectedEpisode() as boolean
  ' Evita flujo cuando no hay episodios cacheados.
  if m.episodesData = invalid or m.episodesData.count() <= 0 then return false
  ' Evita índices inválidos cuando no existe selección válida.
  if m.selectedEpisodeIndex < 0 or m.selectedEpisodeIndex >= m.episodesData.count() then return false

  ' Obtiene episodio enfocado para evaluar si tiene reproducción habilitada.
  selectedEpisode = m.episodesData[m.selectedEpisodeIndex]
  ' Bloquea apertura cuando el episodio no tiene play habilitado (ícono play oculto).
  if not __resolveEpisodePlay(selectedEpisode) then return true

  ' Resuelve key de navegación priorizando redirectKey cuando existe.
  selectedKey = invalid
  ' Usa redirectKey si el backend ya entrega contrato de navegación.
  if selectedEpisode.redirectKey <> invalid then selectedKey = selectedEpisode.redirectKey
  ' Fallback a key cuando redirectKey no viene informado.
  if selectedKey = invalid and selectedEpisode.key <> invalid then selectedKey = selectedEpisode.key
  ' Resuelve id de navegación priorizando redirectId cuando existe.
  selectedId = invalid
  ' Usa redirectId si el backend ya entrega contrato de navegación.
  if selectedEpisode.redirectId <> invalid then selectedId = selectedEpisode.redirectId
  ' Fallback a id cuando redirectId no viene informado.
  if selectedId = invalid and selectedEpisode.id <> invalid then selectedId = selectedEpisode.id
  ' Valida que exista key requerida para seguir el flujo de MainScreen.
  if selectedKey = invalid then return true
  ' Valida que exista id requerido para seguir el flujo de MainScreen.
  if selectedId = invalid then return true

  ' Cachea el episodio seleccionado para usarlo en callbacks asíncronos.
  m.selectedEpisode = selectedEpisode
  ' Normaliza redirectKey para reutilizar contrato de MainScreen.
  m.selectedEpisode.redirectKey = selectedKey
  ' Normaliza redirectId para reutilizar contrato de MainScreen.
  m.selectedEpisode.redirectId = selectedId

  ' Abre modal de PIN cuando el episodio tiene control parental activo.
  if m.selectedEpisode.parentalControl <> invalid and m.selectedEpisode.parentalControl then
    ' Crea y muestra el modal de PIN replicando el comportamiento de MainScreen.
    m.pinDialog = createAndShowPINDialog(m.top, i18n_t(m.global.i18n, "shared.parentalControlModal.title"), "onEpisodePinDialogLoad", [i18n_t(m.global.i18n, "button.ok"), i18n_t(m.global.i18n, "button.cancel")])
    ' Consume OK porque el flujo continúa desde el callback del modal.
    return true
  end if

  ' Ejecuta validación de visualización cuando no requiere PIN.
  __runEpisodeWatchValidate()
  ' Consume OK para evitar bubbling mientras se procesa la acción.
  return true
end function

' Ejecuta WatchValidate del episodio seleccionado para continuar al player.
sub __runEpisodeWatchValidate()
  ' Evita requests cuando todavía no existe episodio seleccionado.
  if m.selectedEpisode = invalid then return

  ' Muestra loading global mientras se resuelve URL de reproducción.
  if m.top.loading <> invalid then m.top.loading.visible = true
  ' Obtiene watchSessionId para ejecutar WatchValidate como en MainScreen.
  watchSessionId = getWatchSessionId()
  ' Crea requestId para registrar acción reintentable en retry manager.
  requestId = createRequestId()

  ' Construye acción WatchValidate siguiendo el mismo patrón de MainScreen.
  action = {
    apiRequestManager: m.apiRequestManager
    url: urlWatchValidate(m.apiUrl, watchSessionId, m.selectedEpisode.redirectKey, m.selectedEpisode.redirectId)
    method: "GET"
    responseMethod: "onEpisodeWatchValidateResponse"
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

  ' Ejecuta WatchValidate con soporte de retry global.
  runAction(requestId, action, ApiType().CLIENTS_API_URL)
  ' Sincroniza manager local con la acción ejecutada.
  m.apiRequestManager = action.apiRequestManager
end sub

' Se dispara la validación del PIN cargado en el modal de emisiones.
sub onEpisodePinDialogLoad()
  ' Obtiene opción/pin ingresado y limpia referencia del modal de PIN.
  resp = clearPINDialogAndGetOption(m.top, m.pinDialog)
  ' Limpia referencia para evitar reutilización accidental del modal.
  m.pinDialog = invalid
  ' Crea requestId para registrar la validación de PIN en el retry manager.
  requestId = createRequestId()

  ' Continúa solo cuando el usuario confirma y envía un PIN de 4 dígitos.
  if resp.option = 0 and resp.pin <> invalid and Len(resp.pin) = 4 then
    ' Muestra loading global mientras se valida el PIN contra backend.
    if m.top.loading <> invalid then m.top.loading.visible = true
    ' Construye acción para endpoint de validación parental por PIN.
    action = {
      apiRequestManager: m.apiRequestManager
      url: urlParentalControlPin(m.apiUrl, resp.pin)
      method: "GET"
      responseMethod: "onEpisodeParentalControlResponse"
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

    ' Ejecuta validación de PIN con soporte de retry global.
    runAction(requestId, action, ApiType().CLIENTS_API_URL)
    ' Sincroniza manager local con la acción ejecutada.
    m.apiRequestManager = action.apiRequestManager
  end if
end sub

' Procesa respuesta de validación de PIN para habilitar WatchValidate del episodio.
sub onEpisodeParentalControlResponse()
  ' Reintenta flujo de PIN si el manager quedó inválido durante callback.
  if m.apiRequestManager = invalid then
    ' Reintenta la lectura del modal de PIN para sostener el flujo.
    onEpisodePinDialogLoad()
    ' Corta ejecución actual para esperar siguiente respuesta válida.
    return
  end if

  ' Procesa respuesta HTTP exitosa de validación de PIN.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Parsea payload para revisar bandera booleana de validación.
    response = ParseJson(m.apiRequestManager.response)
    ' Continúa a reproducción cuando backend confirma PIN correcto.
    if response <> invalid and response.data <> invalid and response.data then
      ' Remueve acción pendiente al completar validación de PIN.
      removePendingAction(m.apiRequestManager.requestId)
      ' Encadena WatchValidate exactamente igual que MainScreen.
      __runEpisodeWatchValidate()
      ' Corta ejecución para esperar respuesta de WatchValidate.
      return
    else
      ' Oculta loading al no poder continuar con reproducción.
      if m.top.loading <> invalid then m.top.loading.visible = false
      ' Muestra mensaje de PIN inválido replicando MainScreen.
      m.dialog = createAndShowDialog(m.top, "", i18n_t(m.global.i18n, "shared.parentalControlModal.error.invalid"), "onEpisodePinErrorDialogClosed")
    end if
  else
    ' Captura status de error HTTP para logging y logout.
    statusCode = m.apiRequestManager.statusCode
    ' Captura payload de error para diagnóstico.
    errorResponse = m.apiRequestManager.errorResponse
    ' Oculta loading al fallar validación de PIN.
    if m.top.loading <> invalid then m.top.loading.visible = false
    ' Limpia request manager al finalizar error de validación de PIN.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    ' Reutiliza validación global para logout cuando aplica.
    __validateError(statusCode)
    ' Loguea fallo de validación de PIN para soporte.
    printError("Episode ParentalControl:", statusCode.toStr() + " " + errorResponse)
    ' Corta ejecución tras manejar error HTTP.
    return
  end if

  ' Limpia manager al finalizar validación de PIN sin errores HTTP.
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
end sub

' Procesa cierre del diálogo de PIN inválido para liberar el modal.
sub onEpisodePinErrorDialogClosed()
  ' Limpia diálogo y descarta la opción porque solo hay botón de cierre.
  clearDialogAndGetOption(m.top, m.dialog)
  ' Limpia referencia del diálogo luego del cierre.
  m.dialog = invalid
end sub

' Procesa respuesta de WatchValidate para continuar a streaming como MainScreen.
sub onEpisodeWatchValidateResponse()
  ' Reintenta selección si el manager quedó inválido durante callback.
  if m.apiRequestManager = invalid then
    ' Reintenta abrir el episodio actualmente seleccionado.
    __openSelectedEpisode()
    ' Corta ejecución actual para esperar siguiente respuesta válida.
    return
  end if

  ' Maneja respuesta HTTP exitosa de WatchValidate.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Parsea payload data devuelto por WatchValidate.
    response = ParseJson(m.apiRequestManager.response)
    watchData = invalid
    if response <> invalid then watchData = response.data

    ' Continúa a streaming solo cuando resultCode indica éxito funcional.
    if watchData <> invalid and watchData.resultCode = 200 then
      ' Persiste sesión/token para mantener contrato del player.
      setWatchSessionId(watchData.watchSessionId)
      setWatchToken(watchData.watchToken)
      ' Solicita streaming del episodio validado igual que MainScreen.
      m.apiRequestManager = sendApiRequest(m.apiRequestManager, urlStreaming(m.apiUrl, m.selectedEpisode.redirectKey, m.selectedEpisode.redirectId), "GET", "onEpisodeStreamingResponse")
      ' Corta aquí para no limpiar loading hasta terminar streaming.
      return
    else
      ' Obtiene resultCode para diagnóstico cuando WatchValidate falla.
      resultCode = invalid
      if watchData <> invalid then resultCode = watchData.resultCode
      ' Limpia loading al no poder continuar a streaming.
      if m.top.loading <> invalid then m.top.loading.visible = false
      ' Limpia request manager al finalizar respuesta inválida.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Reutiliza manejo global de errores funcionales.
      __validateError(0)
      ' Loguea resultado no exitoso para soporte.
      printError("Episode WatchValidate ResultCode:", resultCode)
      return
    end if
  else
    ' Obtiene status para manejo de errores HTTP.
    statusCode = m.apiRequestManager.statusCode
    ' Obtiene payload de error para logging.
    errorResponse = m.apiRequestManager.errorResponse
    ' Limpia loading al no poder continuar a streaming.
    if m.top.loading <> invalid then m.top.loading.visible = false
    ' Limpia request manager al finalizar respuesta con error.
    m.apiRequestManager = clearApiRequest(m.apiRequestManager)
    ' Reutiliza manejo global de errores HTTP.
    __validateError(statusCode)
    ' Loguea error de WatchValidate para soporte.
    printError("Episode WatchValidate Status:", statusCode.toStr() + " " + errorResponse)
    return
  end if
end sub

' Procesa respuesta de streaming del episodio y notifica navegación al player.
sub onEpisodeStreamingResponse()
  ' Reintenta apertura cuando el manager quedó inválido durante la respuesta.
  if m.apiRequestManager = invalid then
    ' Reintenta abrir el episodio actualmente seleccionado.
    __openSelectedEpisode()
    ' Corta ejecución actual para esperar próxima respuesta.
    return
  end if

  ' Maneja respuesta exitosa para navegar al player.
  if validateStatusCode(m.apiRequestManager.statusCode) then
    ' Remueve acción pendiente al completar streaming.
    if m.apiRequestManager.requestId <> invalid then removePendingAction(m.apiRequestManager.requestId)
    ' Parsea respuesta para extraer nodo data con la URL de reproducción.
    response = ParseJson(m.apiRequestManager.response)
    if response <> invalid and response.data <> invalid then
      ' Prepara payload con identificadores mínimos para PlayerScreen.
      streaming = response.data
      ' Completa key con redirectKey del episodio como en MainScreen.
      streaming.key = m.selectedEpisode.redirectKey
      ' Completa id con redirectId del episodio como en MainScreen.
      streaming.id = m.selectedEpisode.redirectId
      ' Define tipo por defecto tal como otras pantallas antes de abrir Player.
      streaming.streamingType = getStreamingType().DEFAULT
      ' Emite salida para que MainScene redireccione al player.
      m.top.streaming = FormatJson(streaming)
    else
      ' Informa falta de data para diagnóstico sin abrir player.
      printError("Emission Streaming Empty:", m.apiRequestManager.response)
    end if
  else
    ' Obtiene status para manejar errores funcionales.
    statusCode = m.apiRequestManager.statusCode
    ' Obtiene payload de error para logging.
    errorResponse = m.apiRequestManager.errorResponse
    ' Informa error de streaming del episodio para soporte.
    printError("Emission Streaming:", errorResponse)
    ' Valida logout por sesión expirada igual que otros flujos.
    if validateLogout(statusCode, m.top) then
      ' Limpia manager antes de salir por logout.
      m.apiRequestManager = clearApiRequest(m.apiRequestManager)
      ' Oculta loading al salir por logout.
      if m.top.loading <> invalid then m.top.loading.visible = false
      ' Corta ejecución para no continuar con limpieza duplicada.
      return
    end if
  end if

  ' Limpia request manager al finalizar procesamiento.
  m.apiRequestManager = clearApiRequest(m.apiRequestManager)
  ' Oculta loading global al terminar el flujo de streaming.
  if m.top.loading <> invalid then m.top.loading.visible = false
  ' Limpia episodio seleccionado al finalizar intento de reproducción.
  m.selectedEpisode = invalid
end sub

' Construye datos de EpisodeItem con fallback temporal.
function __buildEpisodeItemData(item as dynamic) as object
  ' Inicia estructura con textos de ejemplo requeridos.
  data = {
    episodeTitle: ""
    episodeSynopsis: ""
    episodeTime: ""
    emissionImage: ""
  }
  ' Evita leer campos cuando el item del servicio es inválido.
  if item = invalid then return data
  ' Sobrescribe título cuando el servicio lo envía.
  if item.title <> invalid and item.title <> "" then data.episodeTitle = item.title
  ' Sobrescribe sinopsis cuando el servicio la envía.
  if item.synopsis <> invalid and item.synopsis <> "" then data.episodeSynopsis = item.synopsis
  ' Sobrescribe duración cuando el servicio la envía.
  if item.duration <> invalid and item.duration <> "" then data.episodeTime = item.duration
  ' Sobrescribe imagen principal cuando el servicio la envía.
  if item.image <> invalid and item.image <> "" then data.emissionImage = item.image
  ' Retorna payload final para EpisodeItem.
  return data
end function

' Normaliza el flag play tomando en cuenta actions inválido y casos faltantes.
function __resolveEpisodePlay(item as dynamic) as boolean
  ' Devuelve false por defecto en cualquier caso no válido.
  result = false
  ' Corta cuando el episodio es inválido.
  if item = invalid then return result
  ' Corta cuando actions no existe en el episodio.
  if item.actions = invalid then return result
  ' Corta cuando play no existe en actions.
  if item.actions.play = invalid then return result
  ' Activa play solo cuando el valor sea boolean true.
  result = item.actions.play
  ' Devuelve flag final para EpisodeItem.
  return result
end function

' Construye título con formato "longDate shortTime (channelName)".
function __buildEpisodeTitle(item as dynamic) as string
  ' Devuelve string vacío cuando no hay episodio válido.
  if item = invalid then return ""

  startTime = CreateObject("roDateTime")

  startTime.FromISO8601String(item.startTime)
  startTime.ToLocalTime()
  ' Devuelve string vacío cuando no se pudo convertir startTime.
  if startTime = invalid then return ""
  ' Obtiene meses traducidos desde i18n para componer longDate.
  months = i18n_months(m.global.i18n)
  ' Formatea fecha larga equivalente al pipe pqvLocalDate: 'longDate'.
  longDate = dateConverter(startTime, "dd to MMMM yyyy hh:mm", months)
  ' Formatea hora corta equivalente al pipe pqvLocalDate: 'shortTime'.
  channelName = ""
  ' Lee channel.name cuando el nodo channel existe.
  if item.channel <> invalid and item.channel.name <> invalid then channelName = item.channel.name
  ' Compone título final con el formato solicitado por negocio.
  return longDate + " (" + channelName + ")"
end function

' Limpia todos los EpisodeItem creados dinámicamente.
sub __clearEpisodes()
  ' Evita operar si la lista no está inicializada.
  if m.episodesList = invalid then return
  ' Elimina cada hijo existente del contenedor.
  m.episodesCount = 0
  ' Limpia cache de episodios para evitar abrir contenidos obsoletos.
  m.episodesData = []
  ' Limpia episodio seleccionado para evitar reuso de estado obsoleto.
  m.selectedEpisode = invalid
  ' Reinicia el contador total para evitar navegación con datos obsoletos.
  m.selectedEpisodeIndex = 0
  ' Reinicia la selección al primer elemento para la próxima carga.
  __setEpisodesListTranslation(scaleSize([80, 100], m.scaleInfo), false)
  ' Devuelve la lista a su posición base cuando se limpia la pantalla.

  while m.episodesList.getChildCount() > 0
    ' Remueve el primer hijo hasta vaciar la lista.
    m.episodesList.removeChild(m.episodesList.getChild(0))
  end while

  ' Oculta el SelectionBox cuando no quedan episodios visibles.
  if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
end sub

' Mueve la selección vertical y desplaza los EpisodeItem para mantener fijo el indicador.
function __moveSelection(direction as integer) as boolean
  ' Evita navegación cuando no existen episodios en pantalla.
  if m.episodesList = invalid or m.episodesCount <= 0 then return false

  ' Calcula el nuevo índice a partir de la dirección recibida por teclado.
  newIndex = m.selectedEpisodeIndex + direction
  ' Consume la tecla aunque el índice quede fuera de rango para frenar bubbling.
  if newIndex < 0 or newIndex > m.episodesCount - 1 then return true

  ' Aplica la selección válida y desplaza visualmente los ítems.
  __updateSelection(newIndex)
  ' Informa que UP/DOWN fue gestionado por EmissionsScreen.
  return true
end function

' Aplica índice seleccionado y reposiciona la lista para dejar fijo el SelectionBox.
sub __updateSelection(newIndex as integer)
  ' Corta actualización cuando no existe la lista visual.
  if m.episodesList = invalid then return

  ' Si no hay episodios, oculta indicador y termina sin mover lista.
  if m.episodesCount <= 0 then
    ' Garantiza que el marco no quede visible cuando la lista está vacía.
    if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
    ' Sale temprano para evitar cálculos de desplazamiento sin contenido.
    return
  end if

  ' Clampa el índice inferior para impedir valores negativos.
  if newIndex < 0 then newIndex = 0
  ' Clampa el índice superior para no sobrepasar el último elemento.
  if newIndex > m.episodesCount - 1 then newIndex = m.episodesCount - 1

  ' Guarda índice anterior para decidir si corresponde animar el movimiento.
  previousIndex = m.selectedEpisodeIndex

  ' Persiste el índice seleccionado que usará la navegación posterior.
  m.selectedEpisodeIndex = newIndex

  ' Calcula la posición base (reposo) de la lista en la pantalla.
  baseTranslation = [0, 0]
  ' Obtiene el paso vertical real para desplazar exactamente un item.
  stepY = __getEpisodeStepY()

  ' Mueve la lista verticalmente mientras el SelectionBox permanece fijo.
  targetTranslation = [baseTranslation[0], baseTranslation[1] - (m.selectedEpisodeIndex * stepY) + (m.selectedEpisodeIndex * 0.5)]
  animateTransition = previousIndex <> newIndex
  ' Sincroniza el alto del indicador con el EpisodeItem actualmente enfocado.
  __syncSelectedIndicatorSize()
  ' Obtiene la posición superior base del indicador según el layout escalado.
  indicatorTopTranslation = scaleSize([80, -150], m.scaleInfo)
  ' Captura coordenada X fija del indicador para mantener alineación horizontal.
  indicatorX = indicatorTopTranslation[0]
  ' Captura límite superior (Y) desde donde el indicador debe quedar fijo.
  indicatorTopY = indicatorTopTranslation[1]
  ' Calcula altura visible del viewport para ubicar el indicador al fondo de la pantalla.
  episodesViewportHeight = scaleValue(860, m.scaleInfo)
  ' Usa alto fallback del indicador para robustez cuando aún no se pueda medir.
  indicatorHeight = m.selectedIndicatorFallbackHeight
  ' Prioriza alto real del indicador ya sincronizado con el EpisodeItem seleccionado.
  if m.selectedIndicator <> invalid and m.selectedIndicator.size <> invalid and m.selectedIndicator.size.count() > 1 then indicatorHeight = cint(m.selectedIndicator.size[1])
  ' Define un margen inferior mínimo para mantener el indicador abajo pero completamente visible.
  indicatorBottomPadding = scaleValue(6, m.scaleInfo)
  ' Calcula límite inferior del indicador dejando un respiro muy sutil en la parte baja.
  indicatorBottomY = indicatorTopY + episodesViewportHeight - indicatorHeight - indicatorBottomPadding
  ' Evita invertir límites cuando el alto del indicador supera el viewport.
  if indicatorBottomY < indicatorTopY then indicatorBottomY = indicatorTopY
  ' Calcula cuántos pasos separan al item actual del último episodio cargado.
  distanceFromLast = (m.episodesCount - 1 - m.selectedEpisodeIndex) * stepY
  ' Mueve el indicador desde abajo hacia arriba a medida que se navega con flecha UP.
  indicatorTargetY = indicatorBottomY - distanceFromLast
  ' Fija el indicador en el límite superior cuando intenta sobrepasarlo.
  if indicatorTargetY < indicatorTopY then indicatorTargetY = indicatorTopY
  ' Aplica traducción final del indicador para reflejar la posición dinámica actual.
  if m.selectedIndicator <> invalid then m.selectedIndicator.translation = [indicatorX, indicatorTargetY]
  ' Recalcula desplazamiento de la lista para mantener alineado el item seleccionado con el indicador.
  targetTranslation = [baseTranslation[0], (indicatorTargetY - indicatorTopY) + baseTranslation[1] - (m.selectedEpisodeIndex * stepY) + (m.selectedEpisodeIndex * 0.5)]
  __setEpisodesListTranslation(targetTranslation, animateTransition)

  ' Muestra el marco de selección al existir un episodio activo.
  if m.selectedIndicator <> invalid then m.selectedIndicator.visible = true
end sub

' Sincroniza el tamaño del SelectionBox para igualar el alto del EpisodeItem enfocado.
sub __syncSelectedIndicatorSize()
  ' Evita cálculos cuando el indicador aún no está disponible en la pantalla.
  if m.selectedIndicator = invalid then return
  ' Usa ancho cacheado como base para conservar el diseño horizontal del marco.
  indicatorWidth = m.selectedIndicatorWidth
  ' Usa alto fallback como base en caso de que no se pueda medir el EpisodeItem activo.
  indicatorHeight = m.selectedIndicatorFallbackHeight
  ' Obtiene referencia del EpisodeItem correspondiente al índice actualmente seleccionado.
  selectedEpisodeItem = __getEpisodeItemByIndex(m.selectedEpisodeIndex)
  ' Intenta medir alto real solo cuando el EpisodeItem enfocado existe.
  if selectedEpisodeItem <> invalid then
    ' Lee el bounding rect del EpisodeItem para capturar su altura dinámica actual.
    selectedEpisodeBounds = selectedEpisodeItem.boundingRect()
    ' Reemplaza el alto fallback solo cuando la altura medida es válida y mayor a cero.
    if selectedEpisodeBounds <> invalid and selectedEpisodeBounds.height <> invalid and cint(selectedEpisodeBounds.height) > 0 then indicatorHeight = cint(selectedEpisodeBounds.height)
  end if
  ' Aplica tamaño final al SelectionBox usando ancho fijo y alto dinámico.
  m.selectedIndicator.size = [indicatorWidth, indicatorHeight]
end sub

' Obtiene el EpisodeItem visual asociado al índice lógico de selección.
function __getEpisodeItemByIndex(targetIndex as integer) as dynamic
  ' Evita búsqueda cuando no existe lista renderizada en pantalla.
  if m.episodesList = invalid then return invalid
  ' Evita búsqueda cuando el índice pedido es negativo.
  if targetIndex < 0 then return invalid
  ' Inicia contador de EpisodeItem para mapear índice lógico a hijos reales con separadores.
  currentEpisodeIndex = 0
  ' Recorre todos los nodos hijos porque la lista también contiene separadores.
  for i = 0 to m.episodesList.getChildCount() - 1
    ' Obtiene el hijo actual para evaluar si corresponde a un EpisodeItem.
    child = m.episodesList.getChild(i)
    ' Continúa solo cuando el hijo es un EpisodeItem válido.
    if child <> invalid and child.subtype() = "EpisodeItem" then
      ' Retorna el EpisodeItem cuando coincide con el índice lógico solicitado.
      if currentEpisodeIndex = targetIndex then return child
      ' Avanza índice lógico únicamente al pasar por un EpisodeItem.
      currentEpisodeIndex = currentEpisodeIndex + 1
    end if
  end for
  ' Retorna invalid cuando no se encontró EpisodeItem para el índice solicitado.
  return invalid
end function

' Aplica translation a la lista de episodios con animación opcional.
sub __setEpisodesListTranslation(targetTranslation as object, animate as boolean)
  ' Evita mover la lista cuando no existe el nodo visual.
  if m.episodesList = invalid then return

  ' Corrige valores inválidos usando posición base escalada.
  if targetTranslation = invalid or targetTranslation.count() < 2 then
    targetTranslation = [0, 0]
  end if

  ' Aplica movimiento inmediato cuando no corresponde animar o no existe animation node.
  if not animate or m.episodesMoveAnimation = invalid or m.episodesMoveInterpolator = invalid then
    m.episodesList.translation = targetTranslation
    return
  end if

  ' Captura posición actual para construir interpolación desde el estado visible.
  currentTranslation = m.episodesList.translation
  if currentTranslation = invalid or currentTranslation.count() < 2 then
    currentTranslation = [0, 0]
  end if

  ' Evita iniciar animación cuando origen y destino son iguales.
  if currentTranslation[0] = targetTranslation[0] and currentTranslation[1] = targetTranslation[1] then return

  ' Reinicia y ejecuta interpolación vertical suave entre episodios.
  m.episodesMoveInterpolator.keyValue = [currentTranslation, targetTranslation]
  m.episodesMoveAnimation.control = "stop"
  m.episodesMoveAnimation.control = "start"
end sub

' Calcula el desplazamiento vertical por item (alto del episodio + spacing del LayoutGroup).
function __getEpisodeStepY() as integer
  ' Define fallback con valores de diseño base escalados.
  stepY = scaleValue(324, m.scaleInfo)
  ' Retorna fallback cuando no hay lista o no existen hijos renderizados.
  if m.episodesList = invalid or m.episodesList.getChildCount() <= 0 then return stepY

  ' Intenta medir la distancia real entre dos EpisodeItem consecutivos.
  firstEpisode = invalid
  secondEpisode = invalid
  for i = 0 to m.episodesList.getChildCount() - 1
    child = m.episodesList.getChild(i)
    if child <> invalid and child.subtype() = "EpisodeItem" then
      if firstEpisode = invalid then
        firstEpisode = child
      else
        secondEpisode = child
        exit for
      end if
    end if
  end for

  if firstEpisode <> invalid and secondEpisode <> invalid then
    firstY = cint(firstEpisode.translation[1])
    secondY = cint(secondEpisode.translation[1])
    measuredStep = secondY - firstY
    if measuredStep > 0 then return measuredStep
  end if

  ' Fallback: alto de episodio + spacing superior/inferior + separador.
  if firstEpisode <> invalid then
    bounds = firstEpisode.boundingRect()
    if bounds <> invalid and bounds.height <> invalid and cint(bounds.height) > 0 then
      stepY = cint(bounds.height)
      spacingY = 0
      if m.episodesList.itemSpacings <> invalid and m.episodesList.itemSpacings.count() > 0 then
        spacingY = cint(m.episodesList.itemSpacings[0])
      end if
      stepY = stepY + (spacingY * 2) + scaleValue(m.episodeSeparatorHeight, m.scaleInfo)
    end if
  end if

  ' Entrega el desplazamiento final que usará __updateSelection.
  return cint(stepY)
end function

' Limpia estado cuando ocurre logout.
sub onLogoutChange()
  ' Resetea payload y flags básicos del componente.
  if m.top.logout then
    ' Limpia episodios renderizados durante logout.
    __clearEpisodes()
    ' Limpia payload de entrada.
    m.top.data = invalid
    ' Limpia bandera de salida por back.
    m.top.onBack = false
    ' Limpia última key cacheada.
    m.lastKey = invalid
    ' Limpia último id cacheado.
    m.lastId = invalid
    ' Limpia salida de streaming para evitar retriggers al reloguear.
    m.top.streaming = invalid
    ' Limpia episodio seleccionado durante logout.
    m.selectedEpisode = invalid
    ' Limpia el título cuando se resetea la pantalla por logout.
    if m.emissionsTitle <> invalid then m.emissionsTitle.text = ""
    ' Oculta el marco para evitar residuos visuales al salir de sesión.
    if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
  end if
end sub

' Reutiliza validación de errores estándar para resolver logout cuando aplica.
sub __validateError(statusCode as integer)
  ' Si el error implica logout, delegamos y detenemos el flujo local.
  if validateLogout(statusCode, m.top) then return 
end sub

' Guardar el log cuandos se cambia una opción del menú 
sub __saveActionLog(actionLog as object)

  if beaconTokenExpired() and m.apiUrl <> invalid then
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogsToken(m.apiUrl)
      method: "GET"
      responseMethod: "onActionLogTokenResponse"
      body: invalid
      token: invalid
      publicApi: false
      requestId: requestId
      dataAux: FormatJson(actionLog)
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  else
    __sendActionLog(actionLog)
  end if
end sub

' Llamar al servicio para guardar el log
sub __sendActionLog(actionLog as object)
  beaconToken = getBeaconToken()

  if (beaconToken <> invalid and m.beaconUrl <> invalid)
    requestId = createRequestId()

    action = {
      apiRequestManager: m.apiLogRequestManager
      url: urlActionLogs(m.beaconUrl)
      method: "POST"
      responseMethod: "onActionLogResponse"
      body: FormatJson(actionLog)
      token: beaconToken
      publicApi: false
      dataAux: invalid
      requestId: requestId
      run: function() as Object
        m.apiRequestManager = sendApiRequest(m.apiRequestManager, m.url, m.method, m.responseMethod, m.requestId, m.body, m.token, m.publicApi, m.dataAux)
        return { success: true, error: invalid }
      end function
    }
    
    runAction(requestId, action, ApiType().LOGS_API_URL)
    m.apiLogRequestManager = action.apiRequestManager
  end if
end sub

' Limpiar la llamada del log
sub onActionLogResponse() 
  m.apiLogRequestManager = clearApiRequest(m.apiLogRequestManager)
end sub